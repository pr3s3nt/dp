#!/usr/bin/env bash
# run_all.sh — trích xuất cả 2 cụm rồi so sánh. Sửa 4 biến bên dưới cho khớp máy bạn.
set -euo pipefail
cd "$(dirname "$0")"

# === Cấu hình — sửa cho đúng ===
OLD_KUBECONFIG="${OLD_KUBECONFIG:-$HOME/.kube/old-cluster.yaml}"
NEW_KUBECONFIG="${NEW_KUBECONFIG:-$HOME/.kube/new-cluster.yaml}"
REDACTION="${REDACTION:-./redaction.yaml}"
OUT="${OUT:-./out}"
# ================================

PY="${PYTHON:-python3}"

echo ">> Cụm CŨ (1.19)"
"$PY" extract_cluster.py \
  --kubeconfig "$OLD_KUBECONFIG" \
  --label old \
  --output "$OUT" \
  --redaction-config "$REDACTION"

echo ">> Cụm MỚI (1.35) — insecure TLS"
"$PY" extract_cluster.py \
  --kubeconfig "$NEW_KUBECONFIG" \
  --label new \
  --insecure-skip-tls-verify \
  --output "$OUT" \
  --redaction-config "$REDACTION"

echo ">> So sánh"
"$PY" compare_clusters.py \
  --old "$OUT/old/inventory.json" \
  --new "$OUT/new/inventory.json" \
  --output "$OUT/migration-gap.md"

echo ">> Xong. Xem:"
echo "   $OUT/old/inventory.md"
echo "   $OUT/new/inventory.md"
echo "   $OUT/migration-gap.md"
