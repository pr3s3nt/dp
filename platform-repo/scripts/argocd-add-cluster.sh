#!/usr/bin/env bash
# =============================================================================
# argocd-add-cluster.sh — Đăng ký một cụm "app" vào ArgoCD chạy trên cụm "mgmt"
# (tự động hóa `argocd cluster add` chỉ bằng kubectl, không cần argocd CLI login).
#
# Mô hình multi-cluster: ArgoCD ở cụm mgmt deploy CHÉO sang cụm app
# (destination.name = <name> đăng ký ở đây; khớp clusters/placement/<app>.yaml).
#
# Cách dùng:
#   argocd-add-cluster.sh --app-context <ctx-app> --mgmt-context <ctx-mgmt> --name <ten-argocd>
# =============================================================================
set -euo pipefail
APP_CTX=""; MGMT_CTX=""; NAME=""
while [ $# -gt 0 ]; do case "$1" in
  --app-context) APP_CTX="$2"; shift 2 ;;
  --mgmt-context) MGMT_CTX="$2"; shift 2 ;;
  --name) NAME="$2"; shift 2 ;;
  *) echo "cờ lạ: $1" >&2; exit 1 ;;
esac; done
[ -n "$APP_CTX" ] && [ -n "$MGMT_CTX" ] && [ -n "$NAME" ] || { echo "cần --app-context --mgmt-context --name" >&2; exit 1; }

# 1) Trên cụm app: ServiceAccount cluster-admin + token cho ArgoCD.
kubectl --context "$APP_CTX" apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata: { name: argocd-manager, namespace: kube-system }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: { name: argocd-manager }
roleRef: { apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: cluster-admin }
subjects: [{ kind: ServiceAccount, name: argocd-manager, namespace: kube-system }]
---
apiVersion: v1
kind: Secret
metadata:
  name: argocd-manager-token
  namespace: kube-system
  annotations: { kubernetes.io/service-account.name: argocd-manager }
type: kubernetes.io/service-account-token
EOF

echo "==> chờ token SA..."
TOKEN=""
for i in $(seq 1 30); do
  TOKEN=$(kubectl --context "$APP_CTX" -n kube-system get secret argocd-manager-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d || true)
  [ -n "$TOKEN" ] && break; sleep 2
done
[ -n "$TOKEN" ] || { echo "không lấy được token SA" >&2; exit 1; }

SERVER=$(kubectl --context "$APP_CTX" config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA=$(kubectl --context "$APP_CTX" config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# 2) Trên cụm mgmt: tạo Secret cluster cho ArgoCD.
kubectl --context "$MGMT_CTX" apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cluster-${NAME}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${NAME}
  server: ${SERVER}
  config: |
    {"bearerToken":"${TOKEN}","tlsClientConfig":{"caData":"${CA}"}}
EOF

echo "==> đã đăng ký cụm '${NAME}' (${SERVER}) vào ArgoCD mgmt."
