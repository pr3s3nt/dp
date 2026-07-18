#!/usr/bin/env bash
# =============================================================================
# bootstrap-do-cicd.sh — Dựng full CI/CD cho notes-app trên DigitalOcean.
#
# Làm một lần: tạo 3 repo GitHub từ 3 thư mục của monorepo này, đặt secrets,
# cài ArgoCD trên cụm DOKS, apply project + ApplicationSet. Sau đó mỗi lần push
# notes-app -> do-ci -> do-orchestrator -> config repo -> ArgoCD sync (tự động staging).
#
# Yêu cầu biến môi trường:
#   GH_PAT     GitHub PAT (scope: repo/administration + contents + actions + secrets + workflow)
#   DO_TOKEN   (tùy chọn) DigitalOcean API token — mặc định đọc từ ~/.config/doctl/config.yaml
#
# Cần: gh, kubectl (context trỏ cụm DOKS), yq, git.
# =============================================================================
set -euo pipefail

OWNER="${OWNER:-pr3s3nt}"
VISIBILITY="${VISIBILITY:-public}"
MONO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # gốc monorepo idp/
CLUSTER_ID="${CLUSTER_ID:-k8s-1-36-0-do-2-sgp1-1783313804464}"

log(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mLỖI:\033[0m %s\n' "$*" >&2; exit 1; }

[ -n "${GH_PAT:-}" ] || die "thiếu GH_PAT"
: "${DO_TOKEN:=$(yq '.access-token // ""' ~/.config/doctl/config.yaml 2>/dev/null)}"
[ -n "$DO_TOKEN" ] || die "thiếu DO_TOKEN và không đọc được từ doctl config"

export GH_TOKEN="$GH_PAT"
gh auth status >/dev/null 2>&1 || die "gh chưa nhận GH_TOKEN (PAT sai scope?)"

# map: <repo-name> = <đường dẫn thư mục nguồn trong monorepo>
declare -A REPOS=(
  [platform-repo]="$MONO/platform-repo"
  [notes-app]="$MONO/app-repos/notes-app"
  [notes-app-config]="$MONO/config-repos/notes-app-config"
)

# ----- 1. Tạo repo + push từng thư mục thành repo riêng --------------------------------
push_repo(){ # $1=name $2=srcdir
  local name="$1" src="$2" tmp
  gh repo view "$OWNER/$name" >/dev/null 2>&1 \
    || gh repo create "$OWNER/$name" --"$VISIBILITY" -y >/dev/null
  tmp="$(mktemp -d)"
  cp -r "$src/." "$tmp/"
  ( cd "$tmp"
    git init -q -b main
    git add -A
    git -c user.email=idp@local -c user.name=idp commit -q -m "bootstrap $name (DO CI/CD)"
    git push -q -f "https://x-access-token:${GH_PAT}@github.com/${OWNER}/${name}.git" main
  )
  rm -rf "$tmp"
  log "pushed $OWNER/$name"
}
for name in "${!REPOS[@]}"; do push_repo "$name" "${REPOS[$name]}"; done

# ----- 2. Secrets ---------------------------------------------------------------------
gh secret set DO_TOKEN                --repo "$OWNER/notes-app"     --body "$DO_TOKEN"
gh secret set PLATFORM_DISPATCH_TOKEN --repo "$OWNER/notes-app"     --body "$GH_PAT"
gh secret set DO_TOKEN                --repo "$OWNER/platform-repo" --body "$DO_TOKEN"
gh secret set CONFIG_REPO_TOKEN       --repo "$OWNER/platform-repo" --body "$GH_PAT"
log "secrets đã đặt cho notes-app + platform-repo"

# ----- 3. ArgoCD ----------------------------------------------------------------------
if ! kubectl get ns argocd >/dev/null 2>&1; then
  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  log "chờ ArgoCD server sẵn sàng..."
  kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
fi
kubectl apply -f "$MONO/platform-repo/argocd/do-project.yaml"
kubectl apply -f "$MONO/platform-repo/argocd/do-appset.yaml"
log "ArgoCD project + ApplicationSet do-apps đã apply"

cat <<EOF

XONG BOOTSTRAP. Kích hoạt 1 vòng CI/CD:
  cd "$MONO/app-repos/notes-app" (bản đã push) hoặc sửa file rồi:
  git commit --allow-empty -m "trigger" && git push   # -> do-ci -> orchestrator -> ArgoCD

Mật khẩu admin ArgoCD:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
UI: kubectl -n argocd port-forward svc/argocd-server 8080:443
EOF
