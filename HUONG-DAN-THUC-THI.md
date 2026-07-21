# HƯỚNG DẪN THỰC THI — Catalog mở rộng cho migration 1.19 → 1.35

Tài liệu này dành cho người chạy trong công ty (máy nối được cụm k8s qua `kubectl`).
Làm tuần tự từ Bước 0. Mọi lệnh chạy từ thư mục `platform-repo/` trừ khi ghi khác.

## Những gì đã thêm vào repo (đối chiếu yêu cầu D1–D6)

| Deliverable | File |
|---|---|
| D1 Provisioner `mysql`, `mongodb`, `redis` (+ backup CronJob tùy chọn §4C) | `platform-repo/score/provisioners/onprem.provisioners.yaml`, `cloud.provisioners.yaml` |
| D2 Patch: resources bỏ qua datastore, pull secret cấu hình được (§4D), tiêm cả CronJob | `platform-repo/score/patches/staging.tpl`, `prod.tpl` |
| D3 Cơ chế app-config secret (§4B) | block `app-config` trong 2 file provisioner |
| D4 Test harness local (§6) | `platform-repo/scripts/test-local.sh` |
| D5 score.yaml mẫu 3 app | `platform-repo/score/examples/migration/{feedback360,okr,shift-handover}/` |
| D6 Tài liệu maintainer + mapping + đánh giá keycloak/svms/arangodb | `platform-repo/docs/them-provisioner-moi.md`, `docs/mapping-k8s-cu-sang-score.md` |
| Route đa host (§4E) | render **Ingress nginx chuẩn** (khuôn công ty trên Rancher); tên chứa host+path — 2 host cùng workload không đụng nhau; params: `ingressClass/bodySize/tlsSecret/pathType` |
| App mẫu format công ty | `examples/migration/otm/` — dựng từ đúng manifest Rancher bạn cung cấp (otm-fe 8080 + probe + resources, otm-be 1080, mysql 5.6 30Gi headless, strategy maxSurge 1/maxUnavailable 0 do patch tiêm) |
| DB theo format công ty | **mysql = port trung thực StatefulSet bạn apply**: init server-id + clone/sidecar xtrabackup + master/slave.cnf + liveness bash 120s + Service headless & `-read` + PVC Retain; `params.replicas` bật read-replica, ghi vào `host` (pod-0), đọc `readHost`. postgres/mongodb/redis: probe + headless + `params.config` cùng khuôn |
| Postgres nâng cùng khuôn | `params.database/image/storage/backup` + label datastore + resources (mặc định giữ hành vi cũ — app cũ không đổi) |
| **Đa cụm: mỗi app một cụm k8s riêng** | `platform-repo/clusters/placement/<app>.yaml` (nguồn sự thật); ArgoCD cụm quản lý deploy chéo (`appset-onprem.yaml`); orchestrator apply secret theo `KUBECONFIG_<TÊN_CỤM>`. Xem `platform-repo/clusters/README.md` |

Đã kiểm chứng offline: cấu trúc template + YAML đầu ra + quy tắc patch (85 assertion),
smoke-test 4 chế độ của test harness. **Chưa chạy qua binary `score-k8s` thật** (môi trường
làm việc không tải được) → **Bước 1 dưới đây là bắt buộc** trước khi đụng cụm.

## Bước 0 — Chuẩn bị máy (một lần)

Cần 3 binary (air-gap: chép file vào `/usr/local/bin`):

```bash
# score-k8s ĐÚNG bản 0.15.0 (bản platform ghim trong orchestrator)
curl -fsSL -o /tmp/sk.tgz https://github.com/score-spec/score-k8s/releases/download/0.15.0/score-k8s_0.15.0_linux_amd64.tar.gz
tar xzf /tmp/sk.tgz -C /tmp score-k8s && sudo mv /tmp/score-k8s /usr/local/bin/
# yq v4 (mikefarah) + kubectl tương thích 1.35
score-k8s --version && yq --version && kubectl version --client
```

Kubeconfig: file riêng cho từng cụm, ví dụ `~/.kube/new-cluster.yaml` (cụm mới 1.35).
KHÔNG dùng context trỏ cụm prod cũ khi chạy harness.

## Bước 1 — Render offline (không cần cụm, ~1 phút)

Kiểm tra catalog render được bằng score-k8s thật:

```bash
cd platform-repo
./scripts/test-local.sh score/examples/migration/okr            --render-only
./scripts/test-local.sh score/examples/migration/feedback360    --render-only
./scripts/test-local.sh score/examples/migration/shift-handover --render-only
# thử cả prod patch + cloud provisioner:
./scripts/test-local.sh score/examples/migration/okr --env prod --render-only
./scripts/test-local.sh score/examples/migration/okr --target cloud --render-only
```

Đạt khi: mỗi lệnh liệt kê danh sách manifest, không lỗi template. Mở soi bằng mắt:
`.sandbox/okr-onprem-staging/app.yaml` (manifest) — để ý StatefulSet mysql, Deployment redis,
Ingress nginx tên có host. `secrets.yaml` chứa password sinh ra — **không commit** (đã có .gitignore).
So khuôn công ty nhanh nhất: `./scripts/test-local.sh score/examples/migration/otm --render-only`
rồi so `app.yaml` với manifest Rancher (otm-fe/otm-be/mysql headless/strategy/probe/resources).

Nếu lỗi template ở bước này: báo lại nguyên văn lỗi (khác biệt cú pháp giữa mô phỏng và
score-k8s thật, sửa nhanh được).

## Bước 2 — Dry-run server-side lên CỤM MỚI (an toàn, không thay đổi gì)

```bash
./scripts/test-local.sh score/examples/migration/okr \
    --kubeconfig ~/.kube/new-cluster.yaml --insecure-skip-tls-verify
# lặp cho feedback360, shift-handover
```

Mô hình **mỗi app một cụm riêng**: `--kubeconfig` trỏ vào **cụm của chính app đó**
(cụm ghi trong `clusters/placement/<app>.yaml`). Chưa dựng cụm riêng thì dry-run tạm
lên cụm quản lý — manifest giống hệt nhau, chỉ khác nơi áp.

Hai người test **cùng một app trên cùng một cụm** cùng lúc: thêm
`--namespace okr-sandbox-<tên mình>` để không giẫm namespace của nhau (mặc định
cả hai sẽ dùng chung `okr-sandbox`). Còn deploy thật thì đã được tuần tự hóa
tự động theo app (xem mục "Nhiều người dùng đồng thời" trong `platform-repo/README.md`).

Harness tạo namespace `okr-sandbox` (label `idp-sandbox=true`) rồi `kubectl apply
--dry-run=server` từng manifest — apiserver 1.35 kiểm schema + admission thật, in PASS/FAIL
từng cái. App đang chạy không bị đụng (namespace riêng, dry-run).

Đạt khi (tiêu chí nghiệm thu §10): **cả 3 app PASS toàn bộ manifest**.

Hay gặp:
- Route giờ là Ingress nginx CHUẨN (`networking.k8s.io/v1`) → dry-run pass không cần cài gì;
  nhưng traffic chỉ chạy khi cụm có ingress-nginx controller (bootstrap/onprem.md) và
  `ingressClassName` khớp (`kubectl get ingressclass`; khác `nginx` thì khai `params.ingressClass`).
- Lỗi TLS `specifying a root certificates file with the insecure flag is not allowed`
  → kubeconfig có sẵn `certificate-authority-data`; xóa field đó trong file kubeconfig rồi chạy lại.
- `storageclass "rook-ceph-block" not found` → `kubectl get storageclass` xem tên thật,
  sửa 1 chỗ trong `onprem.provisioners.yaml` (mysql/mongodb/postgres + PVC backup).

## Bước 3 — Áp thật vào sandbox (tùy chọn nhưng nên làm cho 1 app)

```bash
./scripts/test-local.sh score/examples/migration/okr \
    --kubeconfig ~/.kube/new-cluster.yaml --insecure-skip-tls-verify \
    --registry harbor.<domain>/idp --tag <sha-hoặc-tag-image> \
    --apply
kubectl --kubeconfig ~/.kube/new-cluster.yaml -n okr-sandbox get pods -w
```

Ghi chú:
- `--apply` mặc định **bỏ route** (Ingress trong sandbox trùng host/path sẽ tranh traffic
  với app thật trên ingress-nginx). Muốn test route: đổi host trong score.yaml mẫu thành
  `*-sandbox.<domain>` rồi thêm `--with-routes`.
- Không truyền `--registry/--tag` thì image là `"."` — pod sẽ ImagePullBackOff (bình thường);
  datastore (mysql/redis/mongo) vẫn phải Running.
- App có `app-config`: pod sẽ thiếu config cho tới khi điền giá trị thật:

```bash
kubectl -n feedback360-sandbox patch secret feedback360-backend-app-config \
  -p '{"stringData":{"NODE_ENV":"production","JWT_SECRET":"..."}}'
kubectl -n feedback360-sandbox rollout restart deploy feedback360-backend
```
(giá trị lấy từ secret cũ: `kubectl --kubeconfig <cụm-cũ> -n feedback360 get secret be-secret -o yaml`,
decode base64. Điền xong thì các lần deploy sau không bị ghi đè — create-if-missing.)

Dọn dẹp:

```bash
./scripts/test-local.sh score/examples/migration/okr \
    --kubeconfig ~/.kube/new-cluster.yaml --insecure-skip-tls-verify --cleanup
```

Idempotent: mọi lệnh trên chạy lại nhiều lần không lỗi. `--fresh` nếu muốn xóa state render cũ.

## Bước 4 — Chốt catalog

1. Mở PR các thay đổi trong `platform-repo` (catalog-ci sẽ render-diff bộ examples cho reviewer).
2. Merge → đánh tag catalog mới: `git tag catalog/v2 && git push --tags`.
3. App mới onboard ghim `platform.lock` = `catalog/v2`. App đang chạy (shop-app) **không
   bị ảnh hưởng** cho tới khi tự nâng lock (canary từng app).

## Bước 5 — Onboard app thật đầu tiên (khuyên: okr)

Mỗi app một cụm riêng → làm 5a trước, mỗi cụm chỉ một lần.

**5a. Onboard CỤM của app** (chi tiết: `platform-repo/clusters/README.md`):

```bash
# từ máy quản trị thấy cả cụm quản lý (đang chạy ArgoCD) lẫn cụm app:
argocd cluster add <context-cụm-okr> --name okr-staging
# secret cho orchestrator (Settings → Secrets → Actions của platform-repo):
#   KUBECONFIG_OKR_STAGING = base64 kubeconfig cụm đó
# + cài ingress-nginx trên cụm app (bootstrap/onprem.md — không cần ArgoCD trên cụm app)
```

**5b. Onboard APP:**

1. Tạo repo `okr` trong org theo khuôn `app-repos/shop-app`: mỗi service một thư mục
   (`backend/`, `frontend/`) chứa `score.yaml` (lấy từ `score/examples/migration/okr/`,
   đổi domain thật) + Dockerfile + code; `platform.lock` = `catalog/v2`; workflows
   `ci.yaml`/`promote.yaml` copy từ shop-app.
2. Tạo repo rỗng `okr-config`.
3. Sửa `platform-repo/clusters/placement/okr.yaml` cho khớp tên cụm vừa đăng ký
   (file mẫu đã có sẵn — thiếu file này ArgoCD sẽ không deploy app).
4. Secrets CI như shop-app (xem `app-repos/shop-app/README.md`).
5. Push main → orchestrator render + apply secret **lên cụm theo placement** + commit
   config → ArgoCD (cụm quản lý) sync `okr-staging` **trên cụm okr-staging**.
6. Điền app-config secret (nếu app có) + restore dữ liệu (xem
   `platform-repo/docs/mapping-k8s-cu-sang-score.md` mục "Di trú dữ liệu").
7. Trỏ DNS host về ingress-nginx **của cụm app** sau khi nghiệm thu.

## Bước 6 — Rollout 21 app còn lại theo wave

| Wave | App | Lý do |
|---|---|---|
| 1 | dap, knox2fem, opn, portal, service-portal, survey-doe, fem | app đơn không datastore — rủi ro thấp nhất |
| 2 | okr, okr-dep, moodle-v2, event-management, face-reco, otm | mysql/mariadb (khuôn đã proof bằng okr) |
| 3 | feedback360, moodle | postgres + app-config; moodle dùng DB ngoài |
| 4 | shift-handover, security-cloud, passbolt, passbolt-v4 | mongodb + backup; passbolt có PVC đặc thù |
| 5 | acs | redis + arangodb (arangodb dựng tay — xem docs/mapping) |
| — | keycloak, svms | KHÔNG migrate như app — hạ tầng (đánh giá trong docs/mapping) |

Mỗi app trong wave: dựng/đăng ký cụm của app (Bước 5a) → lặp Bước 2→3 bằng chính
score.yaml của app đó với kubeconfig cụm đó → thêm file placement → bật CI.

Gợi ý thực dụng: 22 cụm riêng là nhiều — nếu hạ tầng chưa đủ, placement cho phép trộn
(vài app chung một cụm, app nhạy cảm cụm riêng) mà không đổi cơ chế: chỉ là giá trị
trong `clusters/placement/<app>.yaml`.

## Checklist nghiệm thu (đối chiếu §10 tài liệu yêu cầu)

- [ ] Bước 1 pass: `score-k8s generate` OK cho 3 app mẫu (onprem+cloud, staging+prod)
- [ ] Bước 2 pass: dry-run server 3 app trên cụm mới, namespace sandbox, 0 FAIL
- [ ] `git grep CHANGE_ME -- '*-config'` và config repo không chứa secret nào; `secrets.yaml`/`.sandbox/` nằm trong .gitignore
- [ ] Mỗi provisioner mới có doc params/outputs (đầu block) + ví dụ (examples/migration)
- [ ] Maintainer khác thêm được 1 datastore giả định theo `docs/them-provisioner-moi.md` trong < 1h
- [ ] Toàn bộ chạy offline: 3 binary chép tay + image qua Harbor proxy-cache (comment trong provisioner)
- [ ] Đa cụm: app đầu tiên deploy đúng cụm ghi trong placement (kiểm bằng `argocd app get <app>-staging-onprem` — trường Destination), secret nằm trên cụm app chứ không phải cụm quản lý
