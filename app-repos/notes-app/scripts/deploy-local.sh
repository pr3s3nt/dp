#!/usr/bin/env bash
# =============================================================================
# DEPLOY-LOCAL — test nhanh notes-app lên cụm onprem, KHÔNG cần CI/ArgoCD.
# Mô phỏng đúng những gì CI làm: build -> score-k8s render -> tách secret -> apply.
#
# Yêu cầu trên máy: docker, kubectl (context trỏ đúng cụm), score-k8s, yq (v4).
#   score-k8s: https://github.com/score-spec/score-k8s/releases (bản 0.15.0)
#   yq:        https://github.com/mikefarah/yq/releases
#
# Cách chạy (từ thư mục notes-app/), registry là Harbor:
#   REGISTRY=harbor.cty.local/idp \
#   HARBOR_USERNAME='robot$idp+ci' HARBOR_PASSWORD='...' \
#   bash scripts/deploy-local.sh
#   # tùy chọn thêm: TAG=v1 ENVIRONMENT=staging PLATFORM_DIR=/path/to/platform-repo
# Lưu ý Harbor: project (vd 'idp') phải tồn tại trước khi push.
# =============================================================================
set -euo pipefail

REGISTRY="${REGISTRY:?Thiếu REGISTRY. Ví dụ: REGISTRY=registry.cty.local/idp $0}"
TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%y%m%d%H%M)}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
APP_NAME="notes-app"
NS="${APP_NAME}-${ENVIRONMENT}"
SERVICES="frontend backend"

# platform-repo chứa provisioners + patches (mặc định: nằm cạnh trong repo v2)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
PLATFORM_DIR="${PLATFORM_DIR:-$(cd "$APP_DIR/../../platform-repo" && pwd)}"

echo "==> registry=$REGISTRY tag=$TAG env=$ENVIRONMENT ns=$NS"
echo "==> platform: $PLATFORM_DIR"

# App ghim catalog ở ref nào (platform.lock) thì PLATFORM_DIR phải đang ở đúng ref đó
LOCK=$(grep -v '^#' "$APP_DIR/platform.lock" 2>/dev/null | head -1 | tr -d '[:space:]')
if [ -n "$LOCK" ] && [ "$LOCK" != "main" ]; then
  echo "LƯU Ý: app ghim catalog '$LOCK' — kiểm tra PLATFORM_DIR đang checkout đúng ref:"
  echo "  git -C $PLATFORM_DIR checkout $LOCK"
fi

# --- kiểm tra công cụ + storageclass ----------------------------------------
for bin in docker kubectl score-k8s yq; do
  command -v "$bin" >/dev/null || { echo "Thiếu công cụ: $bin"; exit 1; }
done
if ! kubectl get storageclass rook-ceph-block >/dev/null 2>&1; then
  echo "CẢNH BÁO: không thấy storageclass 'rook-ceph-block'. Danh sách hiện có:"
  kubectl get storageclass
  echo "-> nếu tên khác, sửa storageClassName trong ${PLATFORM_DIR}/score/provisioners/onprem.provisioners.yaml"
fi

# --- 1. build + push image ----------------------------------------------------
HARBOR_HOST="${REGISTRY%%/*}"
if [ -n "${HARBOR_USERNAME:-}" ] && [ -n "${HARBOR_PASSWORD:-}" ]; then
  echo "$HARBOR_PASSWORD" | docker login "$HARBOR_HOST" -u "$HARBOR_USERNAME" --password-stdin
fi
for svc in $SERVICES; do
  echo "==> build $svc"
  docker build -t "${REGISTRY}/${APP_NAME}-${svc}:${TAG}" "${APP_DIR}/${svc}"
  docker push "${REGISTRY}/${APP_NAME}-${svc}:${TAG}"
done

# --- 2. render manifest bằng score-k8s + provisioner + patch env --------------
# Giữ nguyên thư mục work giữa các lần chạy để password DB trong state ổn định.
WORK="${APP_DIR}/.work-${ENVIRONMENT}"
mkdir -p "$WORK" && cd "$WORK"
if [ ! -d .score-k8s ]; then
  score-k8s init --no-sample \
    --provisioners "${PLATFORM_DIR}/score/provisioners/onprem.provisioners.yaml" \
    --patch-templates "${PLATFORM_DIR}/score/patches/${ENVIRONMENT}.tpl"
fi
for svc in $SERVICES; do
  score-k8s generate "${APP_DIR}/${svc}/score.yaml" \
    --override-property "containers.main.image=\"${REGISTRY}/${APP_NAME}-${svc}:${TAG}\"" \
    --output manifests.yaml
done

# --- 3. tách secret (không đưa vào git) + apply --------------------------------
yq eval 'select(.kind == "Secret")' manifests.yaml > secrets.yaml
yq eval 'select(.kind != "Secret")' manifests.yaml > app.yaml

kubectl create namespace "$NS" 2>/dev/null || true

# Pull secret cho Harbor — patch template đã tiêm imagePullSecrets: harbor-pull vào mọi workload
if [ -n "${HARBOR_USERNAME:-}" ] && [ -n "${HARBOR_PASSWORD:-}" ]; then
  kubectl create secret docker-registry harbor-pull -n "$NS" \
    --docker-server="$HARBOR_HOST" \
    --docker-username="$HARBOR_USERNAME" \
    --docker-password="$HARBOR_PASSWORD" 2>/dev/null \
    || echo "==> harbor-pull đã tồn tại -> giữ nguyên"
else
  echo "CẢNH BÁO: thiếu HARBOR_USERNAME/HARBOR_PASSWORD -> không tạo secret harbor-pull."
  echo "  Project Harbor private thì pod sẽ ImagePullBackOff. Truyền 2 biến đó hoặc tạo secret tay."
fi

# create-if-missing: giữ nguyên password cũ nếu secret đã tồn tại trên cụm
kubectl create -n "$NS" -f secrets.yaml 2>/dev/null || echo "==> secret đã tồn tại -> giữ nguyên"
kubectl apply -n "$NS" -f app.yaml

echo
echo "==> Xong. Theo dõi:"
echo "    kubectl get pods,pvc,ingressroute -n $NS"
echo "==> Truy cập (host notes.local trong score.yaml):"
echo "    - thêm vào /etc/hosts: <IP-node-Traefik>  notes.local"
echo "    - mở http://notes.local:<nodePort-web-của-Traefik>/"
echo "    - hoặc test nhanh: curl -H 'Host: notes.local' http://<IP-node>:<port>/api/health"
