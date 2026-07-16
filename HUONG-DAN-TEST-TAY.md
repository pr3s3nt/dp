# Test tay notes-app lên cụm K8s — gõ lệnh từng bước

Mục tiêu: tự tay đưa notes-app vào cụm, nhìn thấy từng công đoạn, xác nhận "đã ăn vào cụm".
Thiết kế cho vòng lặp sửa lỗi:

```
chạy lệnh → lỗi → copy output gửi AI → AI commit fix lên repo → git pull → chạy lại đúng bước đó
```

Mọi bước đều **chạy lại được nhiều lần** (idempotent) — pull xong cứ chạy lại, không cần dọn gì trừ khi ghi rõ.

---

## Bước 0 — Làm MỘT LẦN (không phải lặp lại khi pull code mới)

### 0.1. Công cụ trên máy chạy lệnh (runner / máy có kubectl vào cụm)

```bash
docker version && kubectl version --client && git --version   # phải có sẵn

# score-k8s 0.15.0 (binary đã tải/mirror về máy)
sudo mv score-k8s /usr/local/bin/ && score-k8s --version

# yq v4
sudo install -m 0755 yq /usr/local/bin/yq && yq --version
```

### 0.2. File biến môi trường — nằm NGOÀI repo để git pull không đè mất

```bash
cat > ~/idp-test.env <<'EOF'
export REGISTRY="harbor.example.com/idp"        # SỬA: Harbor project của bạn
export HARBOR_HOST="${REGISTRY%%/*}"
export HARBOR_USERNAME='robot$idp+ci'           # SỬA: robot account
export HARBOR_PASSWORD='...'                    # SỬA: password robot
export NS="notes-app-staging"
EOF
chmod 600 ~/idp-test.env
```

### 0.3. Clone repo

```bash
git clone <URL-repo-v2> ~/idp && cd ~/idp
```

---

## MỖI PHIÊN TEST — bắt đầu bằng 2 lệnh này

```bash
cd ~/idp && git pull --rebase
source ~/idp-test.env
```

---

## Bước 1 — Kiểm tra môi trường cụm (chạy lại thoải mái)

```bash
kubectl get nodes                                   # mong đợi: các node Ready
kubectl get storageclass | grep rook-ceph-block     # mong đợi: có dòng này
kubectl get pods -n traefik                         # mong đợi: traefik Running
kubectl get svc -n traefik                          # ghi lại NodePort của cổng web (vd 30080)
```

Lỗi hay gặp: không có `rook-ceph-block` → gửi AI output của `kubectl get storageclass` (AI sẽ sửa `storageClassName` trong provisioner rồi bạn pull lại).

## Bước 2 — Build + push 2 image

```bash
cd ~/idp/app-repos/notes-app
echo "$HARBOR_PASSWORD" | docker login "$HARBOR_HOST" -u "$HARBOR_USERNAME" --password-stdin

export TAG=$(git rev-parse --short HEAD)   # tag = commit đang test, pull code mới là tag mới
for svc in frontend backend; do
  docker build -t "$REGISTRY/notes-app-$svc:$TAG" "./$svc" && \
  docker push "$REGISTRY/notes-app-$svc:$TAG" || break
done
echo "==> TAG=$TAG"
```

Mong đợi: 2 lần `Pushed`. Lỗi build (npm, Dockerfile) → gửi AI **toàn bộ output docker build**.

## Bước 3 — Render manifest bằng score-k8s (thấy được cái sẽ apply)

```bash
cd ~/idp/app-repos/notes-app
rm -rf work && mkdir work && cd work    # thư mục sạch mỗi lần -> kết quả luôn tái lập

score-k8s init --no-sample \
  --provisioners ../../../platform-repo/score/provisioners/onprem.provisioners.yaml \
  --patch-templates ../../../platform-repo/score/patches/staging.tpl

for svc in frontend backend; do
  score-k8s generate "../$svc/score.yaml" \
    --override-property "containers.main.image=\"$REGISTRY/notes-app-$svc:$TAG\"" \
    --output manifests.yaml
done

# Tách secret khỏi manifest
yq eval 'select(.kind == "Secret")'  manifests.yaml > secrets.yaml
yq eval 'select(.kind != "Secret")' manifests.yaml > app.yaml

# Soi trước khi apply:
yq eval '.kind + "/" + .metadata.name' app.yaml     # mong đợi: Deployment/Service x2, StatefulSet+Service db, IngressRoute x2
grep -n "image:" app.yaml                            # image phải đúng $REGISTRY/...:$TAG
grep -n "storageClassName" app.yaml                  # phải là rook-ceph-block
```

Lỗi ở bước này (template, cú pháp provisioner/score) → gửi AI **nguyên văn lỗi score-k8s**. AI sửa `score.yaml` / provisioner / patch → bạn `git pull` → chạy lại **từ đầu Bước 3** (không cần build lại nếu không đổi code app).

## Bước 4 — Namespace + secrets (create-if-missing, chạy lại vô hại)

```bash
kubectl create namespace "$NS" 2>/dev/null || echo "ns đã có"

kubectl create secret docker-registry harbor-pull -n "$NS" \
  --docker-server="$HARBOR_HOST" \
  --docker-username="$HARBOR_USERNAME" \
  --docker-password="$HARBOR_PASSWORD" 2>/dev/null || echo "harbor-pull đã có"

kubectl create -n "$NS" -f secrets.yaml 2>/dev/null || echo "secret DB đã có -> giữ nguyên password cũ"
kubectl get secrets -n "$NS"    # mong đợi: harbor-pull + backend-db-credentials
```

## Bước 5 — Apply app

```bash
kubectl apply -n "$NS" -f app.yaml
kubectl get pods -n "$NS" -w    # Ctrl+C khi cả 3 pod Running (frontend, backend, backend-db-0)
```

Thời gian lần đầu ~1–3 phút (kéo image + tạo PVC). Kiểm chứng "đã ăn vào cụm":

```bash
kubectl get pods,pvc,svc -n "$NS"        # PVC phải Bound
kubectl get ingressroute -n "$NS"
```

## Bước 6 — Truy cập & test chức năng

```bash
NODE_IP=<IP-node-chạy-traefik>; PORT=<nodePort-web-ở-Bước-1>

curl -s -H 'Host: notes.local' "http://$NODE_IP:$PORT/api/health"        # {"ok":true}
curl -s -H 'Host: notes.local' -X POST "http://$NODE_IP:$PORT/api/notes" \
  -H 'Content-Type: application/json' -d '{"text":"test dau tien"}'
curl -s -H 'Host: notes.local' "http://$NODE_IP:$PORT/api/notes"         # thấy note vừa tạo

# Test dữ liệu bền qua restart (điểm ăn tiền của Rook Ceph):
kubectl delete pod backend-db-0 -n "$NS"
kubectl wait --for=condition=ready pod/backend-db-0 -n "$NS" --timeout=180s
curl -s -H 'Host: notes.local' "http://$NODE_IP:$PORT/api/notes"         # note VẪN CÒN
```

Mở UI: thêm `NODE_IP  notes.local` vào `/etc/hosts` máy bạn → `http://notes.local:PORT/`.

---

## VÒNG LẶP SỬA LỖI — sửa ở đâu, chạy lại từ bước nào

| AI sửa file gì (sau khi bạn gửi lỗi) | Bạn chạy lại từ |
|---|---|
| Code app / Dockerfile / package.json | Bước 2 (build lại → TAG mới) → 3 → 5 |
| score.yaml | Bước 3 → 5 (không cần build) |
| provisioners / patches (platform-repo) | Bước 3 → 5 |
| Chỉ tài liệu | không phải chạy gì |

Chuỗi chuẩn mỗi vòng: `git pull --rebase && source ~/idp-test.env` → chạy lại từ bước trong bảng.

Lưu ý duy nhất về trạng thái cũ: nếu AI **đổi tên** workload/resource trong score.yaml (không phải sửa nội dung), object tên cũ còn sót trên cụm — dọn bằng Reset bên dưới rồi chạy lại từ Bước 4.

## RESET — xóa sạch làm lại từ đầu (khi nghi ngờ trạng thái bẩn)

```bash
kubectl delete namespace "$NS"          # xóa hết pod/pvc/secret của app (mất dữ liệu test)
rm -rf ~/idp/app-repos/notes-app/work
# xong chạy lại từ Bước 4 (không cần build lại nếu image không đổi)
```

## THU THẬP DEBUG — copy nguyên khối output này gửi AI khi pod không lên

```bash
{
  echo "=== PODS ===";        kubectl get pods -n "$NS" -o wide
  echo "=== EVENTS ===";      kubectl get events -n "$NS" --sort-by=.lastTimestamp | tail -25
  echo "=== DESCRIBE ===";    kubectl describe pods -n "$NS" | grep -A8 -E "^Name:|Warning|Error"
  echo "=== LOG backend ==="; kubectl logs -n "$NS" deploy/backend --tail=40 2>&1
  echo "=== LOG db ===";      kubectl logs -n "$NS" backend-db-0 --tail=40 2>&1
  echo "=== PVC ===";         kubectl get pvc -n "$NS"
  echo "=== IMAGE ===";       kubectl get pods -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.containers[0].image}{"\n"}{end}'
} 2>&1 | tee /tmp/debug-notes-app.txt
```

Giải mã nhanh trước khi gửi:

| Triệu chứng trong output | Thường là |
|---|---|
| `ImagePullBackOff` + repo notes-app | thiếu/sai harbor-pull, robot thiếu quyền pull |
| `ImagePullBackOff` + image postgres | node không kéo được Docker Hub → cần mirror qua Harbor |
| PVC `Pending` | sai tên storageclass hoặc Ceph không cấp được |
| backend `CrashLoopBackOff`, log "DB chưa sẵn sàng" kéo dài | db chưa lên (xem LOG db) hoặc secret sai |
| `x509: certificate signed by unknown authority` | node/docker chưa tin CA của Harbor |
