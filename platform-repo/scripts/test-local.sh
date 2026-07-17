#!/usr/bin/env bash
# =============================================================================
# test-local.sh — TEST HARNESS LOCAL cho catalog IDP v2 (không cần CI)
#
# Làm gì:
#   1. score-k8s init + generate cho MỘT app (mọi <svc>/score.yaml trong thư mục app)
#      với provisioner (onprem|cloud) + patch (staging|prod) chọn được.
#   2. Tách Secret khỏi manifest (đúng như orchestrator làm).
#   3. Validate KHÔNG PHÁ app đang chạy: apply vào namespace sandbox riêng
#      (<app>-sandbox) bằng `kubectl apply --dry-run=server` (server-side dry-run
#      kiểm tra cả schema + admission trên cụm thật) — in PASS/FAIL từng manifest.
#   4. --apply: áp THẬT lên namespace sandbox (mặc định BỎ route để không cướp
#      traffic Traefik của app thật — thêm --with-routes nếu cố ý).
#   5. --cleanup: xóa namespace sandbox (chỉ xóa ns có label idp-sandbox=true).
#
# Idempotent: chạy lại bao nhiêu lần cũng được. Password datastore giữ ổn định
# trong state (.sandbox/<...>/.score-k8s/) — xóa workdir (--fresh) sẽ sinh password
# mới, nhưng trên cụm secret là create-if-missing nên không bị xoay.
#
# Ví dụ:
#   # dry-run app mẫu okr lên cụm mới (kubeconfig riêng, cụm mới cần skip TLS verify):
#   ./scripts/test-local.sh score/examples/migration/okr \
#       --kubeconfig ~/.kube/new-cluster.yaml --insecure-skip-tls-verify
#
#   # render không cần cụm (kiểm tra template):
#   ./scripts/test-local.sh score/examples/migration/feedback360 --render-only
#
#   # áp thật vào sandbox rồi dọn:
#   ./scripts/test-local.sh score/examples/migration/okr --kubeconfig ~/.kube/new.yaml \
#       --insecure-skip-tls-verify --apply
#   ./scripts/test-local.sh score/examples/migration/okr --kubeconfig ~/.kube/new.yaml \
#       --insecure-skip-tls-verify --cleanup
#
# Yêu cầu: bash, score-k8s 0.15.0, yq v4, kubectl (trừ --render-only).
# Không phụ thuộc dịch vụ ngoài — chạy được trong mạng nội bộ.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PINNED_SCORE_K8S="0.15.0"

# ----- defaults ---------------------------------------------------------------
TARGET="onprem"          # onprem | cloud
ENVIRONMENT="staging"    # staging | prod
APP_DIR=""
APP_NAME=""
NAMESPACE=""
KUBECONFIG_PATH=""
INSECURE=0
DO_APPLY=0
DO_CLEANUP=0
RENDER_ONLY=0
WITH_ROUTES=0
FRESH=0
REGISTRY=""              # vd harbor.example.com/idp — nếu bỏ trống giữ image "." (dry-run vẫn pass)
TAG="dev"
WORKROOT="$REPO_DIR/.sandbox"

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; }
skip() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; }
bad()  { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mLỖI:\033[0m %s\n' "$*" >&2; exit 1; }

# ----- parse args ---------------------------------------------------------------
[ $# -ge 1 ] || usage 1
while [ $# -gt 0 ]; do
  case "$1" in
    --target)                  TARGET="$2"; shift 2 ;;
    --env)                     ENVIRONMENT="$2"; shift 2 ;;
    --app-name)                APP_NAME="$2"; shift 2 ;;
    --namespace|-n)            NAMESPACE="$2"; shift 2 ;;
    --kubeconfig)              KUBECONFIG_PATH="$2"; shift 2 ;;
    --insecure-skip-tls-verify) INSECURE=1; shift ;;
    --registry)                REGISTRY="$2"; shift 2 ;;
    --tag)                     TAG="$2"; shift 2 ;;
    --apply)                   DO_APPLY=1; shift ;;
    --with-routes)             WITH_ROUTES=1; shift ;;
    --cleanup)                 DO_CLEANUP=1; shift ;;
    --render-only)             RENDER_ONLY=1; shift ;;
    --fresh)                   FRESH=1; shift ;;
    --workdir)                 WORKROOT="$2"; shift 2 ;;
    -h|--help)                 usage 0 ;;
    -*)                        die "cờ không hỗ trợ: $1 (xem --help)" ;;
    *)                         APP_DIR="$1"; shift ;;
  esac
done

[ -n "$APP_DIR" ] || die "thiếu đường dẫn thư mục app (chứa <svc>/score.yaml)"
[ -d "$APP_DIR" ] || die "không thấy thư mục: $APP_DIR"
case "$TARGET" in onprem|cloud) ;; *) die "--target phải là onprem|cloud" ;; esac
case "$ENVIRONMENT" in staging|prod) ;; *) die "--env phải là staging|prod" ;; esac

APP_DIR="$(cd "$APP_DIR" && pwd)"
[ -n "$APP_NAME" ] || APP_NAME="$(basename "$APP_DIR")"
[ -n "$NAMESPACE" ] || NAMESPACE="${APP_NAME}-sandbox"

PROVISIONERS="$REPO_DIR/score/provisioners/${TARGET}.provisioners.yaml"
PATCH_TPL="$REPO_DIR/score/patches/${ENVIRONMENT}.tpl"
[ -f "$PROVISIONERS" ] || die "không thấy $PROVISIONERS"
[ -f "$PATCH_TPL" ]    || die "không thấy $PATCH_TPL"

# ----- kubectl wrapper ----------------------------------------------------------
KUBECTL=(kubectl)
[ -n "$KUBECONFIG_PATH" ] && KUBECTL+=(--kubeconfig "$KUBECONFIG_PATH")
[ "$INSECURE" = 1 ]       && KUBECTL+=(--insecure-skip-tls-verify)

require() { command -v "$1" >/dev/null 2>&1 || die "thiếu công cụ: $1 — $2"; }

require score-k8s "cài bản ${PINNED_SCORE_K8S}: https://github.com/score-spec/score-k8s/releases (máy nội bộ: chép sẵn binary)"
require yq        "cài yq v4 (mikefarah): https://github.com/mikefarah/yq/releases"
if [ "$RENDER_ONLY" = 0 ]; then require kubectl "cài kubectl tương thích cụm 1.35"; fi

SK_VER="$(score-k8s --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
if [ -n "$SK_VER" ] && [ "$SK_VER" != "$PINNED_SCORE_K8S" ]; then
  printf '\033[1;33mCẢNH BÁO:\033[0m score-k8s %s ≠ bản ghim %s (platform pin trong orchestrator). Kết quả có thể lệch CI.\n' "$SK_VER" "$PINNED_SCORE_K8S"
fi

# ----- cleanup mode ---------------------------------------------------------------
if [ "$DO_CLEANUP" = 1 ]; then
  log "Dọn dẹp namespace sandbox: $NAMESPACE"
  if ! "${KUBECTL[@]}" get ns "$NAMESPACE" >/dev/null 2>&1; then
    skip "namespace $NAMESPACE không tồn tại — không có gì để dọn"; exit 0
  fi
  LBL="$("${KUBECTL[@]}" get ns "$NAMESPACE" -o jsonpath='{.metadata.labels.idp-sandbox}' 2>/dev/null || true)"
  [ "$LBL" = "true" ] || die "namespace $NAMESPACE KHÔNG có label idp-sandbox=true — từ chối xóa (an toàn cho app thật)"
  "${KUBECTL[@]}" delete ns "$NAMESPACE" --wait=false
  ok "đã yêu cầu xóa namespace $NAMESPACE (PVC/PV sẽ bị thu hồi theo reclaimPolicy)"
  exit 0
fi

# ----- render ---------------------------------------------------------------------
WORKDIR="$WORKROOT/${APP_NAME}-${TARGET}-${ENVIRONMENT}"
[ "$FRESH" = 1 ] && rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Danh sách service = mọi thư mục con cấp 1 có score.yaml (giống orchestrator)
SERVICES="$(cd "$APP_DIR" && for f in */score.yaml; do [ -f "$f" ] && dirname "$f"; done || true)"
if [ -z "$SERVICES" ] && [ -f "$APP_DIR/score.yaml" ]; then SERVICES="."; fi
[ -n "$SERVICES" ] || die "không tìm thấy */score.yaml nào trong $APP_DIR"

log "App: $APP_NAME | services: $(echo $SERVICES | tr '\n' ' ')"
log "Render: target=$TARGET env=$ENVIRONMENT -> $WORKDIR"

cd "$WORKDIR"
score-k8s init --no-sample \
  --provisioners "$PROVISIONERS" \
  --patch-templates "$PATCH_TPL"

for svc in $SERVICES; do
  SVC_NAME="$( [ "$svc" = "." ] && basename "$APP_DIR" || echo "$svc" )"
  GEN_ARGS=("$APP_DIR/$svc/score.yaml" --output manifests.yaml)
  if [ -n "$REGISTRY" ]; then
    GEN_ARGS+=(--override-property "containers.main.image=\"${REGISTRY}/${APP_NAME}-${SVC_NAME}:${TAG}\"")
  fi
  score-k8s generate "${GEN_ARGS[@]}"
done
[ -s manifests.yaml ] || die "score-k8s không sinh ra manifest nào"

# Tách secret đúng như orchestrator (secret KHÔNG BAO GIỜ vào git)
yq eval 'select(.kind == "Secret")' manifests.yaml > secrets.yaml
yq eval 'select(.kind != "Secret")' manifests.yaml > app.yaml

log "Render xong: $(yq eval-all '[.] | length' app.yaml) manifest + $(yq eval-all '[.] | length' secrets.yaml 2>/dev/null || echo 0) secret"

# Chia từng document ra file riêng để báo PASS/FAIL từng manifest
rm -rf split && mkdir -p split
( cd split && yq -s '"doc_" + $index' ../app.yaml )
if [ -s secrets.yaml ]; then
  ( cd split && yq -s '"secret_" + $index' ../secrets.yaml )
fi

if [ "$RENDER_ONLY" = 1 ]; then
  log "Chế độ --render-only: bỏ qua kubectl. Kết quả render:"
  for f in split/doc_*.yml split/secret_*.yml; do
    [ -f "$f" ] || continue
    printf '  - %s/%s\n' "$(yq '.kind' "$f")" "$(yq '.metadata.name' "$f")"
  done
  log "File: $WORKDIR/app.yaml (manifest) + $WORKDIR/secrets.yaml (secret — không commit!)"
  exit 0
fi

# ----- namespace sandbox (an toàn: chỉ đụng ns có label idp-sandbox=true) ----------
log "Namespace sandbox: $NAMESPACE"
if "${KUBECTL[@]}" get ns "$NAMESPACE" >/dev/null 2>&1; then
  LBL="$("${KUBECTL[@]}" get ns "$NAMESPACE" -o jsonpath='{.metadata.labels.idp-sandbox}' 2>/dev/null || true)"
  [ "$LBL" = "true" ] || die "namespace $NAMESPACE đã tồn tại mà KHÔNG phải sandbox của harness (thiếu label idp-sandbox=true) — chọn --namespace khác"
  skip "namespace đã có (idempotent)"
else
  "${KUBECTL[@]}" create ns "$NAMESPACE"
  "${KUBECTL[@]}" label ns "$NAMESPACE" idp-sandbox=true --overwrite
  ok "đã tạo namespace $NAMESPACE (label idp-sandbox=true)"
fi

# ----- validate / apply -------------------------------------------------------------
PASS=0; FAIL=0; SKIPPED=0; FAILED_DOCS=()

check_doc() { # $1=file  $2=dry|real  $3=create|apply
  local f="$1" mode="$2" verb="$3" kind name label out rc
  kind="$(yq '.kind' "$f")"; name="$(yq '.metadata.name' "$f")"
  label="$kind/$name"

  # --apply mặc định bỏ route: IngressRoute/Ingress trong sandbox trùng Host() sẽ
  # cướp traffic của app thật trên Traefik. Dry-run thì vẫn kiểm tra đủ.
  if [ "$mode" = "real" ] && [ "$WITH_ROUTES" = 0 ] && { [ "$kind" = "IngressRoute" ] || [ "$kind" = "Ingress" ]; }; then
    skip "$label — route bị bỏ khi --apply (dùng --with-routes nếu cố ý)"; SKIPPED=$((SKIPPED+1)); return 0
  fi

  local args=(-n "$NAMESPACE" -f "$f")
  [ "$mode" = "dry" ] && args+=(--dry-run=server)

  if [ "$verb" = "create" ]; then
    out="$("${KUBECTL[@]}" create "${args[@]}" 2>&1)" && rc=0 || rc=$?
    if [ $rc -ne 0 ] && grep -q 'AlreadyExists\|already exists' <<<"$out"; then
      skip "$label — đã tồn tại → giữ nguyên (create-if-missing)"; SKIPPED=$((SKIPPED+1)); return 0
    fi
  else
    out="$("${KUBECTL[@]}" apply "${args[@]}" 2>&1)" && rc=0 || rc=$?
  fi

  if [ $rc -eq 0 ]; then ok "$label"; PASS=$((PASS+1))
  else bad "$label"; printf '%s\n' "$out" | sed 's/^/       /'; FAIL=$((FAIL+1)); FAILED_DOCS+=("$label"); fi
}

MODE="dry"; [ "$DO_APPLY" = 1 ] && MODE="real"
if [ "$MODE" = "dry" ]; then
  log "Server-side DRY-RUN vào $NAMESPACE (không thay đổi gì trên cụm)"
else
  log "ÁP THẬT vào $NAMESPACE"
fi

# Secret: dùng create (đúng ngữ nghĩa create-if-missing của orchestrator)
for f in split/secret_*.yml; do [ -f "$f" ] || continue; check_doc "$f" "$MODE" create; done
# Manifest còn lại: apply
for f in split/doc_*.yml;    do [ -f "$f" ] || continue; check_doc "$f" "$MODE" apply;  done

# ----- summary ------------------------------------------------------------------
echo
log "KẾT QUẢ [$APP_NAME | $TARGET/$ENVIRONMENT | ns=$NAMESPACE | mode=$([ "$MODE" = dry ] && echo dry-run || echo apply)]"
printf '     PASS=%d  FAIL=%d  SKIP=%d\n' "$PASS" "$FAIL" "$SKIPPED"

if [ "$MODE" = "real" ] && grep -q 'CHANGE_ME' secrets.yaml 2>/dev/null; then
  echo
  printf '\033[1;33mLƯU Ý:\033[0m app-config secret đang chứa placeholder CHANGE_ME. Điền giá trị thật:\n'
  yq eval 'select(.metadata.labels."app.kubernetes.io/component" == "app-config") | "  kubectl -n '"$NAMESPACE"' patch secret " + .metadata.name + " -p '\''{\"stringData\":{\"<KEY>\":\"<GIÁ TRỊ>\"}}'\''"' secrets.yaml 2>/dev/null || true
fi

if [ $FAIL -gt 0 ]; then
  echo; printf '\033[1;31mManifest lỗi:\033[0m %s\n' "${FAILED_DOCS[*]}"
  echo 'Gợi ý: nếu lỗi TLS "specifying a root certificates file with the insecure flag is not allowed"'
  echo '  -> xóa certificate-authority-data trong kubeconfig của cụm mới rồi chạy lại.'
  exit 1
fi
log "OK — toàn bộ manifest hợp lệ."
[ "$MODE" = "dry" ] && log "Muốn thử thật: thêm --apply (route bị bỏ trừ khi --with-routes). Dọn: --cleanup"
exit 0
