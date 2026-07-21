#!/usr/bin/env bash
# =============================================================================
# deploy-do.sh — Render + deploy MỘT app lên cụm DigitalOcean (DOKS) bằng score-k8s
#
# Dùng provisioner do.provisioners.yaml + patch do-<env>.tpl để sinh manifest THẬT
# rồi apply lên cụm. Hai môi trường staging/prod TÁCH NHAU BẰNG NAMESPACE
# (<app>-staging vs <app>-prod) trên CÙNG một cụm.
#
# So với orchestrator/CI: đây là bản chạy tay gọn cho DO — image kéo từ DOCR,
# host route override bằng nip.io theo env (2 env cùng cụm phải khác host để
# ingress-nginx không tranh traffic).
#
# Ví dụ:
#   ./scripts/deploy-do.sh ../app-repos/notes-app \
#       --env staging \
#       --registry registry.digitalocean.com/idp-notes-thanhnt/notes-app \
#       --lb-ip 203.0.113.10
#
# Yêu cầu: score-k8s 0.15.0, yq v4, kubectl (context trỏ cụm DOKS), doctl (đã auth).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

ENVIRONMENT="staging"
APP_DIR=""
APP_NAME=""
NAMESPACE=""
REGISTRY=""          # vd registry.digitalocean.com/idp-notes-thanhnt/notes-app (tag = tên service)
TAG=""               # override tag chung (mặc định: tên service)
LB_IP=""             # IP LoadBalancer ingress-nginx -> host = <app>-<env>.<LB_IP>.nip.io
RENDER_ONLY=0
WORKROOT="$REPO_DIR/.do-deploy"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32mOK\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mLỖI:\033[0m %s\n' "$*" >&2; exit 1; }

[ $# -ge 1 ] || die "cú pháp: deploy-do.sh <app-dir> --env staging|prod --registry <reg> --lb-ip <ip>"
while [ $# -gt 0 ]; do
  case "$1" in
    --env)        ENVIRONMENT="$2"; shift 2 ;;
    --app-name)   APP_NAME="$2"; shift 2 ;;
    --namespace|-n) NAMESPACE="$2"; shift 2 ;;
    --registry)   REGISTRY="$2"; shift 2 ;;
    --tag)        TAG="$2"; shift 2 ;;
    --lb-ip)      LB_IP="$2"; shift 2 ;;
    --render-only) RENDER_ONLY=1; shift ;;
    --workdir)    WORKROOT="$2"; shift 2 ;;
    -*)           die "cờ không hỗ trợ: $1" ;;
    *)            APP_DIR="$1"; shift ;;
  esac
done

[ -n "$APP_DIR" ] || die "thiếu đường dẫn thư mục app"
[ -d "$APP_DIR" ] || die "không thấy thư mục: $APP_DIR"
case "$ENVIRONMENT" in staging|prod) ;; *) die "--env phải là staging|prod" ;; esac

APP_DIR="$(cd "$APP_DIR" && pwd)"
[ -n "$APP_NAME" ] || APP_NAME="$(basename "$APP_DIR")"
[ -n "$NAMESPACE" ] || NAMESPACE="${APP_NAME}-${ENVIRONMENT}"

PROVISIONERS="$REPO_DIR/score/provisioners/do.provisioners.yaml"
PATCH_TPL="$REPO_DIR/score/patches/do-${ENVIRONMENT}.tpl"
[ -f "$PROVISIONERS" ] || die "không thấy $PROVISIONERS"
[ -f "$PATCH_TPL" ]    || die "không thấy $PATCH_TPL"

command -v score-k8s >/dev/null || die "thiếu score-k8s"
command -v yq        >/dev/null || die "thiếu yq"
[ "$RENDER_ONLY" = 1 ] || command -v kubectl >/dev/null || die "thiếu kubectl"

# host route theo env (nip.io trỏ về IP LoadBalancer). 2 env cùng cụm -> khác host.
HOST=""
[ -n "$LB_IP" ] && HOST="${APP_NAME}-${ENVIRONMENT}.${LB_IP}.nip.io"

# ----- chuẩn bị workdir + bản sao score.yaml (patch host route theo env) -----------
WORKDIR="$WORKROOT/${APP_NAME}-${ENVIRONMENT}"
rm -rf "$WORKDIR"; mkdir -p "$WORKDIR/src"
cp -r "$APP_DIR/." "$WORKDIR/src/"

SERVICES="$(cd "$WORKDIR/src" && for f in */score.yaml; do [ -f "$f" ] && dirname "$f"; done || true)"
[ -n "$SERVICES" ] || { [ -f "$WORKDIR/src/score.yaml" ] && SERVICES="."; }
[ -n "$SERVICES" ] || die "không tìm thấy */score.yaml trong $APP_DIR"

# Override host route (nếu có LB_IP): set params.host cho mọi resource type=route
if [ -n "$HOST" ]; then
  for svc in $SERVICES; do
    f="$WORKDIR/src/$svc/score.yaml"
    routes="$(yq '.resources | to_entries | map(select(.value.type == "route")) | .[].key' "$f" 2>/dev/null || true)"
    for r in $routes; do
      HOST="$HOST" yq -i ".resources.${r}.params.host = strenv(HOST)" "$f"
    done
  done
  log "Host route ($ENVIRONMENT) = $HOST"
fi

log "App: $APP_NAME | env: $ENVIRONMENT | ns: $NAMESPACE | services: $(echo $SERVICES | tr '\n' ' ')"

cd "$WORKDIR"
score-k8s init --no-sample \
  --provisioners "$PROVISIONERS" \
  --patch-templates "$PATCH_TPL"

for svc in $SERVICES; do
  SVC_NAME="$( [ "$svc" = "." ] && echo "$APP_NAME" || echo "$svc" )"
  GEN_ARGS=("src/$svc/score.yaml" --output manifests.yaml)
  if [ -n "$REGISTRY" ]; then
    IMG_TAG="${TAG:-$SVC_NAME}"
    GEN_ARGS+=(--override-property "containers.main.image=\"${REGISTRY}:${IMG_TAG}\"")
  fi
  score-k8s generate "${GEN_ARGS[@]}"
done
[ -s manifests.yaml ] || die "score-k8s không sinh manifest"

# Tách secret khỏi manifest (secret KHÔNG vào git; apply create-if-missing)
yq eval 'select(.kind == "Secret")'  manifests.yaml > secrets.yaml
yq eval 'select(.kind != "Secret")'  manifests.yaml > app.yaml

N_SECRET="$(yq eval 'select(.kind=="Secret") | .metadata.name' secrets.yaml 2>/dev/null | grep -c . || true)"
log "Render xong: $(yq eval-all '[.] | length' app.yaml) manifest + ${N_SECRET:-0} secret"
log "File: $WORKDIR/app.yaml | $WORKDIR/secrets.yaml (secret — không commit)"

if [ "$RENDER_ONLY" = 1 ]; then
  log "--render-only: dừng ở đây."
  exit 0
fi

# ----- namespace + pull secret DOCR --------------------------------------------------
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"
ok "namespace $NAMESPACE"

if command -v doctl >/dev/null 2>&1; then
  # doctl gắn cứng namespace: kube-system trong manifest -> xoá field để apply vào ns app.
  doctl registry kubernetes-manifest 2>/dev/null | yq 'del(.metadata.namespace)' \
    | kubectl apply -n "$NAMESPACE" -f - >/dev/null \
    && ok "pull secret DOCR trong $NAMESPACE" || log "bỏ qua pull secret DOCR (doctl?)"
fi

# ----- apply secret (create-if-missing) rồi app manifest ------------------------------
if [ -s secrets.yaml ]; then
  # create-if-missing: giữ nguyên password nếu secret đã tồn tại
  while IFS= read -r sname; do
    [ -n "$sname" ] || continue
    if kubectl -n "$NAMESPACE" get secret "$sname" >/dev/null 2>&1; then
      ok "secret $sname đã có → giữ nguyên"
    else
      yq eval "select(.kind==\"Secret\" and .metadata.name==\"$sname\")" secrets.yaml \
        | kubectl -n "$NAMESPACE" apply -f - >/dev/null && ok "secret $sname (mới)"
    fi
  done < <(yq eval 'select(.kind=="Secret") | .metadata.name' secrets.yaml)
fi

kubectl -n "$NAMESPACE" apply -f app.yaml
ok "đã apply toàn bộ manifest vào $NAMESPACE"

log "Xong. Theo dõi: kubectl -n $NAMESPACE get pods -w"
[ -n "$HOST" ] && log "URL: http://$HOST/"
