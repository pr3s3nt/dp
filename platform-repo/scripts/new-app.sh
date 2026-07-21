#!/usr/bin/env bash
# =============================================================================
# new-app.sh — SCAFFOLD một app mới cho IDP trên DigitalOcean.
#
# Tự sinh: mã nguồn app (backend Express+Postgres + frontend nginx), score.yaml,
# Dockerfile, workflow do-ci, platform.lock; tạo repo GitHub <app> + <app>-config;
# thêm clusters/placement/<app>.yaml (cụm riêng idp-<app>); đặt secrets.
#
# Khi push app -> do-ci build image -> dispatch "provision-and-deploy" ->
# do-platform.yaml: TẠO HẠ TẦNG TRƯỚC (terraform: VPC+DOKS idp-<app>) rồi mới
# render + deploy (ArgoCD).  (thứ tự: infra -> ci/cd)
#
# Cách dùng:
#   scripts/new-app.sh <app-name> [--owner pr3s3nt] [--registry <docr-repo-prefix>]
#                       [--local-only]        # chỉ sinh file + git init, KHÔNG đụng GitHub
#   Yêu cầu (khi tạo GitHub): GH_TOKEN (PAT), gh; DO_TOKEN (mặc định đọc doctl config).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"
MONO="$(dirname "$PLATFORM_DIR")"

OWNER="pr3s3nt"
REGISTRY_PREFIX="registry.digitalocean.com/idp-notes-thanhnt"   # DOCR: <prefix>/<app>
LOCAL_ONLY=0
APP=""

log(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mLỖI:\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --registry) REGISTRY_PREFIX="$2"; shift 2 ;;
    --local-only) LOCAL_ONLY=1; shift ;;
    -*) die "cờ lạ: $1" ;;
    *) APP="$1"; shift ;;
  esac
done
[ -n "$APP" ] || die "cú pháp: new-app.sh <app-name> [--owner O] [--registry R] [--local-only]"
echo "$APP" | grep -qE '^[a-z][a-z0-9-]{1,38}[a-z0-9]$' || die "app-name chỉ [a-z0-9-], bắt đầu bằng chữ"

APPDIR="$MONO/app-repos/$APP"
CFGDIR="$MONO/config-repos/${APP}-config"
[ -e "$APPDIR" ] && die "$APPDIR đã tồn tại"

REGISTRY_REPO="${REGISTRY_PREFIX}/${APP}"

# ---------------------------------------------------------------------------
log "Sinh mã nguồn app: $APPDIR"
mkdir -p "$APPDIR/backend/src" "$APPDIR/frontend/html" "$APPDIR/.github/workflows"

cat > "$APPDIR/platform.lock" <<EOF
# Ghim catalog (provisioner+patch) của platform-repo cho $APP. Đổi qua PR để nâng cấp.
main
EOF

# ----- backend (Express + Postgres, CRUD items) -----
cat > "$APPDIR/backend/package.json" <<EOF
{
  "name": "${APP}-backend",
  "version": "1.0.0",
  "private": true,
  "main": "src/index.js",
  "scripts": { "start": "node src/index.js" },
  "dependencies": { "express": "^4.19.0", "pg": "^8.12.0" }
}
EOF

cat > "$APPDIR/backend/src/index.js" <<'EOF'
// backend scaffold — Express + Postgres, CRUD "items" dưới /api.
const express = require('express');
const { Pool } = require('pg');
const { PORT = 8080, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD } = process.env;
const pool = new Pool({ host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASSWORD });
const app = express();
app.use(express.json());
app.get(['/health', '/api/health'], (_q, r) => r.json({ ok: true }));
app.get('/api/items', async (_q, r) => {
  const { rows } = await pool.query('SELECT id, name, created_at FROM items ORDER BY id DESC');
  r.json(rows);
});
app.post('/api/items', async (q, r) => {
  const { name } = q.body;
  if (!name) return r.status(400).json({ error: 'name is required' });
  const { rows } = await pool.query('INSERT INTO items (name) VALUES ($1) RETURNING id, name, created_at', [name]);
  r.status(201).json(rows[0]);
});
app.delete('/api/items/:id', async (q, r) => { await pool.query('DELETE FROM items WHERE id=$1', [q.params.id]); r.status(204).end(); });
async function init(n = 20) {
  for (let i = 0; i < n; i++) {
    try {
      await pool.query('CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now())');
      return app.listen(PORT, () => console.log(`backend on :${PORT}`));
    } catch (e) { console.log(`DB chưa sẵn sàng (${e.message}), thử lại 3s...`); await new Promise(r => setTimeout(r, 3000)); }
  }
  console.error('Không kết nối được DB'); process.exit(1);
}
init();
EOF

cat > "$APPDIR/backend/Dockerfile" <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY src ./src
EXPOSE 8080
USER node
CMD ["node", "src/index.js"]
EOF

cat > "$APPDIR/backend/score.yaml" <<EOF
apiVersion: score.dev/v1b1
metadata:
  name: backend
containers:
  main:
    image: "."
    variables:
      PORT: "8080"
      DB_HOST: \${resources.db.host}
      DB_PORT: \${resources.db.port}
      DB_NAME: \${resources.db.name}
      DB_USER: \${resources.db.username}
      DB_PASSWORD: \${resources.db.password}
service:
  ports:
    http: { port: 8080, targetPort: 8080 }
resources:
  db:
    type: postgres
  api:
    type: route
    params: { host: ${APP}.local, path: /api, port: 8080 }
EOF

# ----- frontend (nginx tĩnh, gọi /api bằng vanilla JS — không cần build) -----
cat > "$APPDIR/frontend/html/index.html" <<EOF
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><title>${APP}</title></head>
<body style="font-family:system-ui;max-width:560px;margin:48px auto">
<h1>${APP} — demo IDP trên DigitalOcean</h1>
<form onsubmit="add(event)"><input id="t" placeholder="Tên item..."><button>Thêm</button></form>
<ul id="list"></ul>
<script>
async function load(){const r=await fetch('/api/items');document.getElementById('list').innerHTML=(await r.json()).map(i=>'<li>'+i.name+'</li>').join('')}
async function add(e){e.preventDefault();const t=document.getElementById('t');await fetch('/api/items',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:t.value})});t.value='';load()}
load();
</script></body></html>
EOF

cat > "$APPDIR/frontend/Dockerfile" <<'EOF'
FROM nginx:1.27-alpine
COPY html /usr/share/nginx/html
EXPOSE 80
EOF

cat > "$APPDIR/frontend/score.yaml" <<EOF
apiVersion: score.dev/v1b1
metadata:
  name: frontend
containers:
  main:
    image: "."
service:
  ports:
    http: { port: 80, targetPort: 80 }
resources:
  site:
    type: route
    params: { host: ${APP}.local, path: /, port: 80 }
EOF

# ----- workflow do-ci (build DOCR + dispatch provision-and-deploy) -----
cat > "$APPDIR/.github/workflows/do-ci.yaml" <<EOF
name: do-ci
on:
  push: { branches: [main] }
env:
  REGISTRY_REPO: ${REGISTRY_REPO}
  APP_NAME: ${APP}
  PLATFORM_REPO: ${OWNER}/platform-repo
jobs:
  build:
    runs-on: ubuntu-latest
    strategy: { matrix: { service: [frontend, backend] } }
    steps:
      - uses: actions/checkout@v4
      - name: Login DOCR
        run: echo "\${{ secrets.DO_TOKEN }}" | docker login registry.digitalocean.com -u "\${{ secrets.DO_TOKEN }}" --password-stdin
      - name: Build & push
        run: |
          IMG="\${REGISTRY_REPO}:\${{ matrix.service }}-\${{ github.sha }}"
          docker build -t "\$IMG" "./\${{ matrix.service }}"
          docker push "\$IMG"
  notify-platform:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Dispatch provision-and-deploy (infra TRƯỚC, deploy SAU)
        run: |
          curl -sf -X POST -H "Authorization: Bearer \${{ secrets.PLATFORM_DISPATCH_TOKEN }}" \\
            -H "Accept: application/vnd.github+json" \\
            "\${{ github.api_url }}/repos/\${PLATFORM_REPO}/dispatches" \\
            -d '{"event_type":"provision-and-deploy","client_payload":{"app":"${APP}","repo":"\${{ github.repository }}","sha":"\${{ github.sha }}"}}'
EOF

# ---------------------------------------------------------------------------
log "Sinh config repo: $CFGDIR"
mkdir -p "$CFGDIR/do/staging" "$CFGDIR/do/prod"
touch "$CFGDIR/do/staging/.gitkeep" "$CFGDIR/do/prod/.gitkeep"
cat > "$CFGDIR/README.md" <<EOF
# ${APP}-config — config repo của ${APP} (ArgoCD đọc). Máy ghi, người review. Không sửa tay.
EOF

# ---------------------------------------------------------------------------
log "Thêm placement (cụm riêng idp-${APP})"
cat > "$PLATFORM_DIR/clusters/placement/${APP}.yaml" <<EOF
# ${APP} — cụm DOKS riêng (terraform tạo: idp-${APP}). ArgoCD deploy in-cluster.
app: ${APP}
clusters:
  staging: in-cluster
  prod: in-cluster
EOF

# ---------------------------------------------------------------------------
log "git init cho app repo + config repo"
for d in "$APPDIR" "$CFGDIR"; do
  ( cd "$d"; git init -q -b main; git add -A; git -c user.email=idp@local -c user.name=idp commit -q -m "scaffold ${APP}" )
done

if [ "$LOCAL_ONLY" = 1 ]; then
  log "--local-only: xong (không đụng GitHub). File tại: $APPDIR , $CFGDIR"
  exit 0
fi

# ---------------------------------------------------------------------------
[ -n "${GH_TOKEN:-}" ] || die "cần GH_TOKEN (PAT) để tạo repo GitHub (hoặc dùng --local-only)"
: "${DO_TOKEN:=$(yq '.access-token // ""' ~/.config/doctl/config.yaml 2>/dev/null)}"
[ -n "$DO_TOKEN" ] || die "thiếu DO_TOKEN"
command -v gh >/dev/null || die "thiếu gh"

log "Tạo repo GitHub (rỗng) TRƯỚC"
for name in "$APP" "${APP}-config"; do
  gh repo view "$OWNER/$name" >/dev/null 2>&1 || gh repo create "$OWNER/$name" --public -y >/dev/null
done

# Đặt secrets TRƯỚC khi push nội dung — nếu không, push app sẽ kích hoạt do-ci lúc
# secret DO_TOKEN chưa có -> build fail ("Must provide --username").
log "Đặt secrets cho $OWNER/$APP"
gh secret set DO_TOKEN                --repo "$OWNER/$APP" --body "$DO_TOKEN"
gh secret set PLATFORM_DISPATCH_TOKEN --repo "$OWNER/$APP" --body "$GH_TOKEN"

log "Push nội dung app + config repo"
for pair in "$APP:$APPDIR" "${APP}-config:$CFGDIR"; do
  name="${pair%%:*}"; dir="${pair#*:}"
  ( cd "$dir"; git push -q -f "https://x-access-token:${GH_TOKEN}@github.com/${OWNER}/${name}.git" main )
  log "pushed $OWNER/$name"
done

# placement mới phải lên platform-repo để ArgoCD/appset thấy app này:
log "Đẩy placement/${APP}.yaml lên platform-repo"
tmp="$(mktemp -d)"; git -C "$MONO" archive HEAD:platform-repo 2>/dev/null | tar -x -C "$tmp" 2>/dev/null || cp -r "$PLATFORM_DIR/." "$tmp/"
cp "$PLATFORM_DIR/clusters/placement/${APP}.yaml" "$tmp/clusters/placement/${APP}.yaml"
( cd "$tmp"; git init -q -b main; git add -A; git -c user.email=idp@local -c user.name=idp commit -q -m "platform: add placement ${APP}"
  git push -q -f "https://x-access-token:${GH_TOKEN}@github.com/${OWNER}/platform-repo.git" main )
rm -rf "$tmp"

cat <<EOF

SCAFFOLD XONG cho '${APP}'.
Kích hoạt luồng (infra -> ci/cd): sửa gì đó rồi push repo $OWNER/$APP, HOẶC:
  gh api repos/$OWNER/$APP/dispatches -f event_type= ... (do-ci tự chạy khi push)
Theo dõi: Actions của $OWNER/platform-repo (workflow do-platform: job infra -> deploy).
EOF
