# Yêu cầu cho Fable 5 — Mở rộng catalog IDP v2 để migrate app nghiệp vụ (cụm 1.19 → 1.35)

> Tài liệu bàn giao. Đưa nguyên văn cho Fable 5. Mọi đường dẫn tính từ gốc repo `v2/`.

## 0. Vai trò & mục tiêu

Bạn (Fable 5) đóng vai **kỹ sư platform**. Nhiệm vụ: **mở rộng catalog của IDP v2**
(thêm provisioner + cập nhật patch + bổ sung cơ chế test local) để nền tảng đủ sức
onboard **~22 app nghiệp vụ** đang chạy trên cụm cũ (k8s 1.19) sang cụm mới (1.35),
qua đúng giao diện Score hiện có.

Ưu tiên xuyên suốt: **dễ phát triển thêm, dễ mở rộng, dễ bảo trì lâu dài**. Không tối ưu
cho "chạy được một lần" mà tối ưu cho việc 6 tháng sau thêm một loại datastore mới chỉ tốn
một block cấu hình + vài dòng tài liệu.

## 1. Bối cảnh platform — ĐỌC TRƯỚC KHI CODE

Đọc theo thứ tự để nắm mô hình:

1. `README.md` (gốc) — luồng end-to-end Score → score-k8s → config repo → ArgoCD.
2. `platform-repo/README.md` — mô hình orchestrator, secret, Harbor, platform.lock.
3. `platform-repo/score/provisioners/onprem.provisioners.yaml` và `cloud.provisioners.yaml`
   — **khuôn mẫu** cho provisioner mới phải bám theo.
4. `platform-repo/score/patches/staging.tpl` và `prod.tpl` — patch theo env.
5. `platform-repo/score/examples/*.score.yaml` — score.yaml mẫu.
6. `app-repos/shop-app/*/score.yaml` — giao diện dev thực tế.

Tóm tắt nhanh mô hình (để đối chiếu, không thay cho việc đọc):

- Dev chỉ viết `score.yaml`, hiện chỉ có **3 loại resource**: `postgres`, `route`, `service`.
- CI app chỉ build image (Harbor); orchestrator ở `platform-repo` render bằng
  `score-k8s generate` + provisioner (onprem|cloud) + patch (staging|prod), tách Secret
  apply thẳng lên cụm (create-if-missing, không vào git), commit manifest sang `<app>-config`.
- Namespace: `<app>-<env>`. Convention Secret DB: `<workload>-db-credentials`.
- Pin `score-k8s 0.15.0`. onprem: StatefulSet trên `rook-ceph-block`, route qua **Traefik**.

## 2. Dữ liệu đầu vào — ĐỌC ĐỂ NẮM NHU CẦU THẬT

Đã trích xuất sẵn từ 2 cụm vào thư mục `out/` (thông tin nhạy cảm đã được che):

| File | Nội dung |
|---|---|
| `out/old/inventory.json` / `.md` | Toàn bộ resource cụm cũ (1.19), gom theo namespace |
| `out/new/inventory.json` / `.md` | Cụm mới (1.35), đã cài sẵn vài app |
| `out/migration-gap.md` / `.json` | Workload chưa migrate / khác image / đã khớp |
| `out/old/manifests/<ns>/<Kind>.<name>.yaml` | Manifest thô đã làm sạch + che, dùng để suy ra score |

**Lưu ý về redaction (quan trọng):** giá trị nhạy cảm đã bị thay bằng placeholder ổn định
(`<COMPANY>`, `<REGISTRY>`, `<DOMAIN_n>`, `<IP_n>`, `<REDACTED:secret>`, `<REDACTED:env>`).
Đừng coi placeholder là giá trị thật; hãy suy luận theo **cấu trúc**. Hai false-positive đã
biết trong bộ dump: `sessionAffinity` bị che thành `<REDACTED:env>` (khớp nhầm "session"),
và group của `apiVersion` (vd `networking.k8s.io`) bị che thành `<DOMAIN_n>`. Bỏ qua hai chỗ này.

## 3. Phạm vi — CHỈ APP NGHIỆP VỤ

22 namespace nghiệp vụ cần platform hỗ trợ (trích từ `out/old`):

| Namespace | Workloads | Datastore | Route(Ingress) | Ghi chú đặc thù |
|---|---|---|---|---|
| acs | 2 Dep + 2 Sta | arangodb, redis | 0 | AI anticovid; arangodb hiếm |
| dap | 1 Dep | – | 2 | app đơn |
| event-management | 2 Dep + 1 Sta | mysql 5.6 | 2 | be/fe + db |
| face-reco | 4 Dep | mysql 5.7 | 0 | có service AI riêng |
| feedback360 | 2 Dep + 1 Sta | postgres 16 | 2 | app-config qua `be-secret` (secretKeyRef nhiều key) |
| fem | 1 Sta | – | 2 | web StatefulSet |
| keycloak | 1 Dep + 2 Sta | mysql | 0 | *(SSO — cân nhắc coi là hạ tầng, xem §8)* |
| knox2fem | 1 Dep | – | 0 | app đơn |
| moodle | 2 Dep | (mariadb ngoài) | 0 | LMS |
| moodle-v2 | 2 Dep + 1 Sta | mariadb | 2 | LMS + db |
| okr | 2 Dep + 2 Sta | mysql 8, redis | 2 | be/fe + mysql + redis |
| okr-dep | 2 Dep + 2 Sta | mysql 8, redis | 2 | bản staging của okr |
| opn | 1 Dep | – | 0 | app đơn |
| otm | 2 Dep + 1 Sta | mysql 5.6 (+xtrabackup sidecar) | 4 | đã bắt đầu có trên cụm mới |
| passbolt | 3 Sta | mysql 5.6 | 0 | |
| passbolt-v4 | 2 Sta + 8 Job + 2 CronJob | mysql 5.6 | 2 | **CronJob backup + cleanup DB** |
| portal | 1 Dep | – | 2 | devops portal |
| security-cloud | 2 Dep + 1 Sta | mongodb 6 | 2 | |
| service-portal | 1 Dep | – | 2 | |
| shift-handover | 1 Dep + 2 Sta + 6 Job + 2 CronJob | mongodb 6 | 2 | **CronJob backup**; đã có trên cụm mới |
| survey-doe | 2 Dep | – | 4 | 2 phiên bản survey |
| svms | 5 Sta | mysql + grafana/prometheus | 2 | giám sát nội bộ; cân nhắc hạ tầng |

**Nhu cầu datastore tổng hợp:** mysql/mariadb **10 app** (áp đảo), redis 3, mongodb 2,
postgres 2, arangodb 1.

Loại trừ (KHÔNG xử lý): `kube-system`, `cattle-*`, `fleet-*`, `rancher-*`, `local`,
`ceph`, `rook-ceph`, `cert-manager`, `ingress-nginx`, `argocd`, `argo-rollouts`,
`spinnaker`, `elk`, `vault`, `artifactory`, `actions-runner`, `default`, và mọi namespace
Rancher dạng `u-*`, `p-*`, `c-*`, `user-*`.

## 4. Khoảng cách năng lực → việc cần làm

Platform hiện có `postgres / route / service`. Để nuốt được nhóm app trên, cần bổ sung:

**A. Provisioner datastore mới** (viết cho cả `onprem` và `cloud`, đồng bộ 2 file):
- `mysql` — bao trùm cả **mariadb** (10 app, ưu tiên #1). Onprem: StatefulSet + PVC
  `rook-ceph-block` + Service + Secret `<workload>-db-credentials`. Cloud: RDS (Secret do
  Terraform ghi), giống khuôn `postgres` cloud hiện có.
- `mongodb` — 2 app (security-cloud, shift-handover).
- `redis` — 3 app (acs, okr, okr-dep). Thường không cần bền vững → cân nhắc Deployment + Service,
  không PVC (nêu rõ lựa chọn trong doc).
- `arangodb` — chỉ 1 app (acs). **Đề xuất để non-goal / làm tay**, ghi chú lý do; nếu làm thì làm sau cùng.

**B. Cơ chế app-config secret.** Nhiều app đọc cấu hình qua `secretKeyRef` từ một Secret
gom nhiều key (pattern `be-secret`: `NODE_ENV, PORT, DATABASE_URL, JWT_SECRET, KEYCLOAK_URL,
KEYCLOAK_REALM, KEYCLOAK_CLIENT_ID, ...`). Cần cách để dev **khai danh sách key cần thiết**
trong `score.yaml` mà **không đưa giá trị vào git**; orchestrator tạo/để trống Secret
(create-if-missing) theo convention tên. Đề xuất một resource type mới (vd `config` hoặc
`app-secret`) hoặc mở rộng cú pháp env — Fable 5 chọn và giải thích trade-off.

**C. Backup CronJob cho DB** (passbolt-v4, shift-handover: `*-auto-backup`, `*-cleanup-backup`).
Quyết định thiết kế: cho provisioner datastore tự kèm CronJob backup **tùy chọn**
(vd `params.backup: {enabled, schedule, retention}`) hay tách thành resource riêng. Ưu tiên
phương án ít lặp lại, dễ bật/tắt.

**D. Tổng quát hoá imagePullSecrets.** Cụm cũ kéo image từ nhiều registry private
(`artifactory...:30807`, `<REGISTRY>`); cụm mới dùng Harbor. Patch hiện tiêm cứng
`harbor-pull`. Làm cho phần này cấu hình được (tên pull secret theo env), giữ create-if-missing.

**E. Route.** Provisioner `route` hiện render Traefik. App cũ dùng nginx Ingress (host/path/TLS,
đa host cho be/fe như feedback360, otm). Kiểm chứng provisioner `route` phủ được: nhiều host,
path prefix, cổng backend khác nhau. Bổ sung nếu thiếu.

## 5. Hạng mục giao (deliverables)

- **D1.** Provisioner `mysql`, `mongodb`, `redis` trong cả `onprem.provisioners.yaml` và
  `cloud.provisioners.yaml`, bám khuôn provisioner `postgres` hiện có (cùng phong cách,
  cùng convention biến xuất ra: `host`, `port`, `secretRef`).
- **D2.** Cập nhật `patches/staging.tpl` + `prod.tpl` nếu cần (resources mặc định cho từng
  datastore, imagePullSecrets cấu hình được).
- **D3.** Cơ chế app-config secret (§4B) + ví dụ.
- **D4.** **Cơ chế test local** (§6): script chạy `score-k8s generate` cho 1 app rồi
  `kubectl apply --dry-run=server` lên cụm (qua kubeconfig truyền vào, cụm mới thêm
  `--insecure-skip-tls-verify`), vào **namespace sandbox riêng** để không đụng app đang chạy.
  Không cần dựng CI.
- **D5.** `score.yaml` mẫu cho **≥3 app đại diện** chứng minh catalog mới chạy được:
  `feedback360` (postgres + route + app-config), `okr` (mysql + redis + route),
  `shift-handover` (mongodb + route + backup cronjob).
- **D6.** Tài liệu: (a) **"Cách thêm một provisioner mới"** (checklist ngắn cho maintainer);
  (b) bảng **mapping resource k8s cũ → Score** (Appendix A dưới đây là điểm khởi đầu).

## 6. Cơ chế test local (bắt buộc, mô tả rõ)

Máy local kết nối được cụm k8s qua `kubectl`. Test harness cần:

1. Nhận `--kubeconfig <path>` và (cụm mới) `--insecure-skip-tls-verify`.
2. `score-k8s init` + `generate` cho một app mẫu với provisioner + patch chọn được (onprem/cloud, staging/prod).
3. Validate **không phá app đang chạy**: apply vào namespace `<app>-sandbox` bằng
   `kubectl apply --dry-run=server -f <rendered>` (server-side dry-run kiểm cả admission),
   in kết quả pass/fail từng manifest.
4. Có cờ `--apply` để thực sự áp lên namespace sandbox khi muốn thử thật, và lệnh dọn dẹp.
5. Idempotent, chạy lại nhiều lần không lỗi.

Ưu tiên script gọn (bash hoặc Python) + README ngắn. Không phụ thuộc dịch vụ ngoài.

## 7. Yêu cầu phi chức năng — maintainability & extensibility

- Mỗi datastore = **một block provisioner độc lập**, cùng một khuôn; thêm loại mới không phải
  sửa loại cũ. Không copy-paste logic rải rác.
- Giữ **convention tên Secret** `<workload>-db-credentials` và tập biến xuất ra
  (`host/port/secretRef`) đồng nhất giữa mọi datastore — để `score.yaml` của app không đổi khi
  sau này thay backend (StatefulSet → RDS, Sealed Secrets/ESO...).
- Tất cả thao tác Secret/pull-secret: **create-if-missing**, không ghi đè, không commit giá trị.
- Mỗi provisioner có phần doc: `params` nhận vào, biến xuất ra, giả định (storageClass, image).
- Ghim phiên bản qua `platform.lock` / tag catalog như cơ chế hiện có; sửa catalog không lan
  sang app đang chạy tới khi app nâng lock.
- Ưu tiên khai báo (template) hơn code mệnh lệnh; nếu cần script, tách nhỏ, đặt tên rõ.

## 8. Không thuộc phạm vi (non-goals)

- **Migrate hạ tầng**: ceph/rook, rancher/cattle/fleet, spinnaker, argocd, prometheus/grafana,
  elk, vault, artifactory, ingress-nginx, cert-manager. Không đụng.
- **Di trú dữ liệu thật** (dump/restore PVC & DB): ngoài phạm vi bản này; chỉ cần **chừa chỗ cắm**
  và ghi chú quy trình đề xuất, không code.
- `arangodb` (1 app): để làm tay, ghi chú.
- `keycloak`, `svms`: nghiêng về hạ tầng dùng chung — **Fable 5 tự đánh giá** và đề xuất coi là
  hạ tầng hay app; nêu lý do, không cần code nếu xếp vào hạ tầng.
- Xây CI/CD mới. Chỉ cần test local (§6).

## 9. Kế hoạch phát triển đề xuất (theo lát cắt, mỗi bước test được ngay)

1. `mysql` provisioner (onprem+cloud) → app mẫu `okr` → test local dry-run. *(giá trị cao nhất)*
2. `redis` provisioner → hoàn thiện `okr` (mysql+redis).
3. `mongodb` provisioner → app mẫu `shift-handover`.
4. Cơ chế app-config secret (§4B) → app mẫu `feedback360`.
5. Backup CronJob tùy chọn (§4C) → bật cho `shift-handover`/`passbolt-v4`.
6. Tổng quát imagePullSecrets (§4D) + tài liệu (§5 D6).

## 10. Tiêu chí nghiệm thu

- `score-k8s generate` cho **3 app mẫu** (§5 D5) ra manifest hợp lệ; `kubectl apply
  --dry-run=server` **pass** trên cụm mới (namespace sandbox).
- Mỗi provisioner mới có **ví dụ + tài liệu params/biến xuất**.
- **Không có giá trị secret nào bị commit** vào git.
- Có tài liệu **"cách thêm provisioner mới"**; một maintainer mới theo checklist thêm được một
  datastore giả định trong < 1 giờ.
- Toàn bộ chạy được **offline / trong mạng nội bộ** (registry private, không phụ thuộc internet).

---

## Appendix A — Mapping resource k8s cũ → Score (điểm khởi đầu)

| Trong cụm cũ (manifest) | → Score resource | Ghi chú |
|---|---|---|
| Deployment/StatefulSet app + Service | `containers` + `service` trong score.yaml | container chính tên `main`, image do CI điền |
| StatefulSet postgres + PVC + Secret | `type: postgres` | đã có |
| StatefulSet mysql/mariadb + PVC + Secret | `type: mysql` | **cần viết** |
| StatefulSet/Deployment mongodb + PVC | `type: mongodb` | **cần viết** |
| Deployment/StatefulSet redis | `type: redis` | **cần viết**, cân nhắc không PVC |
| Ingress (host/path/tls) | `type: route` | kiểm đa host (be/fe), path prefix |
| Service gọi Service nội bộ (biến host/port) | `type: service` | đã có |
| Secret app-config đọc qua secretKeyRef (`be-secret`) | cơ chế app-config (§4B) | khai key, không khai giá trị |
| CronJob `*-auto-backup` / `*-cleanup-backup` | option `backup` của provisioner DB (§4C) | tùy chọn |
| imagePullSecrets (artifactory/jfrog/harbor) | patch tiêm pull secret theo env (§4D) | create-if-missing |

## Appendix B — Ví dụ pattern app thật (đã lấy từ out/old/manifests)

- `feedback360/Deployment.feedback360-backend.yaml`: mọi biến môi trường đọc từ Secret
  `be-secret` qua `secretKeyRef` (NODE_ENV, DATABASE_URL, JWT_SECRET, KEYCLOAK_*). → dẫn động
  yêu cầu §4B.
- `feedback360/StatefulSet.postgresql.yaml`: Postgres đơn giản, PVC, Secret `postgres-secret`
  (`default-password`), có liveness/readiness `pg_isready`. → khuôn cho provisioner DB.
- `feedback360/Ingress.feedback360.yaml`: **đa host** (`feedback360.<domain>` cho FE,
  `<host2>.<domain>` cho BE) trỏ 2 service khác cổng. → yêu cầu route đa host §4E.
- `okr`: be/fe + `mysql:8.0.25` + `redis:6.2.4` (StatefulSet). → app mẫu bước 1–2.
- `shift-handover` / `passbolt-v4`: mongodb/mysql + CronJob backup & cleanup. → §4C.
