# Kế hoạch test manifest sinh ra cho feedback360 (Score → score-k8s), chế độ RENDER-ONLY

Phạm vi: kiểm tra **output render** của catalog cho app mẫu migration `feedback360`
(`score/examples/migration/feedback360/`) — **không cần cụm k8s**, không apply gì.
Mục tiêu: chứng minh 2 file `score.yaml` (backend + frontend) sinh ra đúng bộ manifest
tương đương cụm 1.19 cũ (ns `feedback360`), trước khi bật CI/orchestrator.

Chạy được ở máy local hoặc runner nội bộ, không cần internet (nếu đã có sẵn binary).

---

## 0. Chuẩn bị (một lần)

| Công cụ | Bản | Ghi chú |
|---|---|---|
| `score-k8s` | **0.15.0** (bản ghim `SCORE_K8S_VERSION` trong `orchestrator.yaml`) | bản khác → template có thể lệch CI, harness sẽ in CẢNH BÁO |
| `yq` | v4 (mikefarah) | dùng để split secret + viết assertion |
| `bash` | — | `kubectl` KHÔNG cần ở chế độ render-only |

```bash
score-k8s --version   # phải là 0.15.0
yq --version          # v4.x
cd <repo>/platform-repo
```

Air-gap: chép sẵn binary `score-k8s` 0.15.0 vào `/usr/local/bin/` (giống bước "Install
score-k8s (chỉ khi runner chưa có)" trong orchestrator).

---

## 1. Ma trận test

| # | Tên | Target | Env | Lệnh | Mục đích |
|---|---|---|---|---|---|
| T1 | Baseline onprem staging | onprem | staging | `--render-only` | bộ manifest chính — đối chiếu cụm cũ |
| T2 | Onprem prod | onprem | prod | `--render-only --env prod` | khác biệt env chỉ nằm ở patch |
| T3 | Có registry thật | onprem | staging | `--registry harbor.example.com/idp --tag abc1234` | image được CI điền đúng dạng |
| T4 | Cloud (đối chiếu tính di động) | cloud | staging | `--target cloud --render-only` | app không đổi, hạ tầng đổi |
| T5 | Idempotency | onprem | staging | chạy lại T1 2 lần | password DB ổn định giữa 2 lần render |
| T6 | Fresh state | onprem | staging | `--fresh` | password mới ⇒ chứng minh state nằm ở `.score-k8s/` |
| T7 | Negative tests | onprem | staging | score.yaml sửa lỗi có chủ đích | provisioner báo lỗi đúng chỗ |

Lệnh gốc (T1):

```bash
./scripts/test-local.sh score/examples/migration/feedback360 --render-only
# output: .sandbox/feedback360-onprem-staging/{manifests.yaml, app.yaml, secrets.yaml, split/}
```

Đặt biến cho các bước sau:

```bash
W=.sandbox/feedback360-onprem-staging
```

---

## 2. Bộ manifest KỲ VỌNG (T1 — onprem/staging)

Tổng: **8 manifest vào git** (`app.yaml`) + **2 Secret bị tách ra** (`secrets.yaml`).

### 2.1 Từ `feedback360-backend/score.yaml`

| # | Kind | Name | Nguồn |
|---|---|---|---|
| 1 | Deployment | `feedback360-backend` | workload |
| 2 | Service | `feedback360-backend` (port 8000 → 8000) | `service.ports.http` |
| 3 | StatefulSet | `feedback360-backend-db` | provisioner `postgres` |
| 4 | Service | `feedback360-backend-db` (headless, 5432) | provisioner `postgres` |
| 5 | Ingress | `feedback360-backend-route-api-feedback360-example-com` | provisioner `route` |
| S1 | Secret | `feedback360-backend-db-credentials` (key `password`) | postgres — **tách ra** |
| S2 | Secret | `feedback360-backend-app-config` (10 key = `CHANGE_ME`) | app-config — **tách ra** |

### 2.2 Từ `feedback360-frontend/score.yaml`

| # | Kind | Name |
|---|---|---|
| 6 | Deployment | `feedback360-frontend` |
| 7 | Service | `feedback360-frontend` (port 80 → 80) |
| 8 | Ingress | `feedback360-frontend-route-feedback360-example-com` |

**KHÔNG được xuất hiện:** PVC/CronJob backup (chưa bật `params.backup`), ConfigMap,
NetworkPolicy, ServiceAccount riêng, hay bất kỳ Ingress thứ 3 nào.

Lệnh kiểm tra nhanh:

```bash
yq ea '[.kind + "/" + .metadata.name] | .[]' $W/app.yaml | sort
yq ea '[.kind + "/" + .metadata.name] | .[]' $W/secrets.yaml | sort
```

---

## 3. Assertion chi tiết (PASS/FAIL từng mục)

### A. Cấu trúc & an toàn secret

| ID | Kiểm tra | Kỳ vọng | Lệnh |
|---|---|---|---|
| A1 | Số manifest vào git | 8 | `yq ea '[.] \| length' $W/app.yaml` |
| A2 | Không còn Secret trong app.yaml | rỗng | `yq ea 'select(.kind=="Secret")' $W/app.yaml` |
| A3 | Đúng 2 Secret bị tách | 2 | `yq ea '[.] \| length' $W/secrets.yaml` |
| A4 | Không có password plaintext trong app.yaml | không match | `grep -iE '"?password"?: *[A-Za-z0-9]{12,}' $W/app.yaml` |
| A5 | Manifest KHÔNG ghim namespace (ArgoCD/`-n` quyết định) | rỗng | `yq ea '.metadata.namespace' $W/app.yaml \| grep -v null` |
| A6 | app-config đúng 10 key, giá trị `CHANGE_ME` | 10 | `yq 'select(.metadata.name=="feedback360-backend-app-config") \| .stringData \| keys \| length' $W/secrets.yaml` |

Danh sách 10 key phải khớp `be-secret` cụm cũ: `NODE_ENV`, `PORT`, `FRONTEND_URL`,
`DATABASE_URL`, `DEFAULT_PASSWORD`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `KEYCLOAK_URL`,
`KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`.

### B. Backend Deployment — biến môi trường

Container `main` phải có **15 biến**: 10 từ app-config + 5 từ postgres.

| ID | Kiểm tra | Kỳ vọng |
|---|---|---|
| B1 | Số env | 15 |
| B2 | 10 biến app-config | đều là `valueFrom.secretKeyRef.name = feedback360-backend-app-config`, `key` = chính tên biến |
| B3 | `DB_PASSWORD` | `secretKeyRef` → `feedback360-backend-db-credentials` / `password` — **không plaintext** |
| B4 | `DB_HOST` | value `feedback360-backend-db` |
| B5 | `DB_PORT` | value `5432` |
| B6 | `DB_NAME` | value `feedback360` (đúng tên DB cụm cũ để restore dump không phải đổi app) |
| B7 | `DB_USER` | value `postgres` |
| B8 | `DATABASE_URL` | **phải là secretKeyRef của app-config**, KHÔNG phải chuỗi ghép — đây là lý do app-config tồn tại |

```bash
yq 'select(.kind=="Deployment" and .metadata.name=="feedback360-backend")
    | .spec.template.spec.containers[0].env' $W/app.yaml
```

### C. Patch template staging đã ăn đúng chỗ

| ID | Đối tượng | Kỳ vọng |
|---|---|---|
| C1 | Deployment `feedback360-backend` / `-frontend` | `spec.replicas = 1` |
| C2 | 2 Deployment trên | `metadata.labels.env = staging` |
| C3 | 2 Deployment trên | `strategy.type = RollingUpdate`, `maxSurge 1`, `maxUnavailable 0` |
| C4 | Container `main` (chưa khai resources) | được patch `requests 50m/64Mi`, `limits.memory 256Mi` |
| C5 | StatefulSet `feedback360-backend-db` (label `component: datastore`) | **KHÔNG** bị đụng `replicas`/`resources`; giữ nguyên `requests 200m/512Mi`, `limits.memory 1Gi` (khai trong `params.resources`) |
| C6 | StatefulSet DB | **KHÔNG** có `metadata.labels.env` và **KHÔNG** có `spec.strategy` (patch chỉ nhắm Deployment) |
| C7 | Cả 3 workload (2 Deployment + 1 StatefulSet) | `spec.template.spec.imagePullSecrets = [{name: harbor-pull}]` |

C5 là assertion quan trọng nhất của thiết kế: **datastore tự khai nhu cầu trong catalog,
patch env không được ghi đè.**

```bash
yq ea 'select(.kind=="Deployment") | .metadata.name + " replicas=" + (.spec.replicas|tostring) + " env=" + .metadata.labels.env' $W/app.yaml
yq 'select(.kind=="StatefulSet") | .spec.template.spec.containers[0].resources' $W/app.yaml
yq ea 'select(.kind=="Deployment" or .kind=="StatefulSet") | .metadata.name + " -> " + (.spec.template.spec.imagePullSecrets[0].name)' $W/app.yaml
```

### D. Route / Ingress (đa host cùng app — điểm đặc trưng của feedback360)

| ID | Kiểm tra | Kỳ vọng |
|---|---|---|
| D1 | Số Ingress | 2, tên khác nhau, không đụng nhau |
| D2 | BE Ingress | host `api-feedback360.example.com`, path `/`, pathType `Prefix` |
| D3 | BE backend service | `name: feedback360-backend`, `port.number: 8000` |
| D4 | FE Ingress | host `feedback360.example.com`, backend `feedback360-frontend` port 80 |
| D5 | `ingressClassName` | `nginx` (đúng khuôn Rancher cũ) |
| D6 | apiVersion | `networking.k8s.io/v1` (cụm 1.35 đã bỏ `extensions/v1beta1`) |
| D7 | Khối `tls` | **KHÔNG có** — vì score.yaml chưa khai `params.tlsSecret` (xem §6 Rủi ro) |

### E. Đối chiếu với cụm 1.19 cũ

Chạy song song với manifest cũ trong `out/old/manifests/feedback360/`:

| ID | Cũ | Mới | Kỳ vọng |
|---|---|---|---|
| E1 | `Deployment.feedback360-backend` env list | B1–B8 | cùng bộ tên biến, không thiếu biến nào app đang đọc |
| E2 | `Service feedback360-be-service` port 8000 | Service `feedback360-backend` 8000 | port giữ nguyên; **tên Service ĐỔI** → app gọi nội bộ phải qua biến, không hardcode |
| E3 | `Ingress feedback360` (2 host) | 2 Ingress riêng | đủ cả host BE lẫn FE |
| E4 | `StatefulSet postgresql` + PVC | StatefulSet `feedback360-backend-db` + volumeClaimTemplates | probe `pg_isready` giữ nguyên (delay 30/5, period 10/5) |
| E5 | Secret `be-secret` | Secret `feedback360-backend-app-config` | đủ 10 key |
| E6 | `nodeSelector` / `hostPath` timezone | không có | **cố ý bỏ** — đặt `TZ` qua env nếu cần |

Cách làm: `diff <(yq ea 'select(.kind=="Deployment")|.spec.template.spec.containers[0].env[].name' cu.yaml | sort) <(...moi...)`.

---

## 4. T2 — prod, chỉ khác ở patch

```bash
./scripts/test-local.sh score/examples/migration/feedback360 --render-only --env prod
diff <(yq ea 'sort_keys(..)' $W/app.yaml) \
     <(yq ea 'sort_keys(..)' .sandbox/feedback360-onprem-prod/app.yaml)
```

**Diff hợp lệ CHỈ được gồm 3 nhóm:**

1. `metadata.labels.env`: `staging` → `prod`
2. `spec.replicas` của 2 Deployment app: `1` → `3`
3. `resources` container app: `requests 50m/64Mi, limits.memory 256Mi` → `requests 100m/128Mi, limits.memory 512Mi`

Mọi khác biệt ngoài 3 nhóm này = FAIL (nghĩa là khác biệt env đã rò rỉ ra ngoài patch).

## 5. T3–T7

**T3 — registry:**
`--registry harbor.example.com/idp --tag abc1234` → image phải là
`harbor.example.com/idp/feedback360-backend:abc1234` và `...-frontend:abc1234`
(đúng dạng orchestrator sinh: `<registry>/<app>-<svc>:<sha>`).
Không có `--registry` thì image giữ `.` — chấp nhận được ở render-only.

**T4 — cloud:** `--target cloud --render-only`. Kỳ vọng:
StatefulSet + Service DB **biến mất** (RDS do Terraform dựng), Secret
`feedback360-backend-db-credentials` **không được sinh** (Terraform ghi), và
`DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD` chuyển hết sang `secretKeyRef`
(host/port/dbname/username/password). Deployment/Service/Ingress giữ nguyên số lượng.
**Điểm chốt: `score.yaml` không đổi một ký tự.**

**T5 — idempotency:** chạy T1 hai lần liên tiếp, `secrets.yaml` phải giống hệt
(`sha256sum` bằng nhau) — password nằm trong state `.score-k8s/`.

**T6 — fresh:** `--fresh` → password ĐỔI. Đây là hành vi đúng; trên cụm không sao vì
orchestrator dùng `kubectl create` (create-if-missing), không bao giờ xoay password đang chạy.

**T7 — negative (sửa bản copy, không sửa file gốc):**

| Kịch bản | Kỳ vọng |
|---|---|
| Bỏ `params.keys` của `app-config` | render FAIL, message `app-config: thiếu params.keys (...)` |
| Bỏ `params.port` của `route` | Ingress `port.number` rỗng/lỗi → phải thấy được, không im lặng |
| Đổi `type: postgres` → `type: s3` | FAIL "no provisioner" — chứng minh không có fallback ngầm |
| Thêm resource `type: mysql` song song với `postgres` cùng workload | đụng tên Secret `<workload>-db-credentials` — xác nhận cảnh báo trong catalog là đúng |

---

## 6. Rủi ro / điểm cần xác nhận bằng mắt sau khi render

1. **Domain placeholder** — `api-feedback360.example.com` / `feedback360.example.com` là TODO.
   Trước khi lên staging thật phải đổi, nếu không Ingress sẽ không nhận traffic.
2. **Không có TLS** — chưa khai `params.tlsSecret`. Nếu cụm cũ đang chạy HTTPS thì đây là
   regression: cần tạo secret cert trong ns và bổ sung `params.tlsSecret` vào cả 2 route.
3. **`storageClassName: rook-ceph-block`** hard-code trong provisioner postgres —
   `kubectl get storageclass` trên cụm 1.35 để xác nhận tên; render-only không bắt được lỗi này.
4. **`imagePullSecrets: harbor-pull` bị tiêm cả vào StatefulSet postgres** (patch không lọc
   theo `component: datastore`). Image `postgres:16-alpine` đến từ Docker Hub → nếu cụm không
   ra internet, phải bật Harbor proxy-cache và đổi `params.image`, nếu không pod DB `ImagePullBackOff`.
5. **Tên Service đổi** (`feedback360-be-service` → `feedback360-backend`): app/FE nào hardcode
   tên cũ sẽ gãy. Kiểm tra `FRONTEND_URL` và cấu hình nginx của FE.
6. **`DATABASE_URL` do ops điền tay** — nếu quên, backend prisma sẽ không kết nối được dù
   `DB_*` đã đúng. Đây là bước bắt buộc trong runbook cutover.
7. **Không có PVC upload/file** cho backend — nếu app cũ có PVC lưu file, render-only sẽ
   không báo gì; phải soát lại manifest cũ (mục E).
8. **Render-only không kiểm tra được**: schema K8s 1.35 (deprecated API), admission/quota,
   storageClass tồn tại, ảnh pull được, DB thật lên được. Những mục này thuộc tầng sau
   (`--kubeconfig ... ` dry-run server-side, rồi `--apply` vào ns `feedback360-sandbox`).

---

## 7. Tiêu chí kết luận

**PASS** khi: §2 đúng đủ 8+2 manifest, toàn bộ assertion A/B/C/D pass, T2 diff nằm trong
3 nhóm cho phép, T4 cho thấy score.yaml bất biến giữa onprem/cloud, T5 idempotent,
T7 báo lỗi đúng chỗ — và mục §6.1/§6.2 đã có quyết định (đổi domain, có/không TLS).

**FAIL / chặn** khi: có Secret lọt vào `app.yaml`, có password plaintext trong env,
patch env đụng vào manifest `component: datastore`, hoặc thiếu biến môi trường so với cụm cũ.

Sau khi PASS: chuyển sang tầng 2 (dry-run server-side lên cụm 1.35 thật)
`./scripts/test-local.sh score/examples/migration/feedback360 --kubeconfig ~/.kube/new.yaml --insecure-skip-tls-verify`,
rồi tầng 3 (`--apply` vào ns sandbox, `--cleanup` sau khi xong).

---

## 8. Ghi chép kết quả (điền khi chạy)

| Test | Ngày | score-k8s | Kết quả | Ghi chú |
|---|---|---|---|---|
| T1 | | | | |
| T2 | | | | |
| T3 | | | | |
| T4 | | | | |
| T5 | | | | |
| T6 | | | | |
| T7 | | | | |
