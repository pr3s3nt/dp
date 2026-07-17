# Mapping resource k8s cũ (cụm 1.19) → Score (catalog v2)

Dùng khi chuyển một app từ `out/old/manifests/<ns>/` sang `score.yaml`.
Ba app đã có mẫu hoàn chỉnh trong `score/examples/migration/` (feedback360, okr, shift-handover).

## Bảng mapping

| Trong cụm cũ (manifest) | → Score | Ghi chú |
|---|---|---|
| Deployment/StatefulSet app + Service | `containers.main` + `service.ports` | container chính tên `main`, image do CI điền (`image: "."`) |
| StatefulSet postgres + PVC + Secret | `type: postgres` | đã nâng cùng khuôn mysql: `params.database/image/storage/backup` (mặc định giữ hành vi cũ) |
| StatefulSet mysql/mariadb + PVC + Secret | `type: mysql` | mariadb: `params.image: mariadb:10.x` (nhận env `MYSQL_*`) |
| StatefulSet/Deployment mongodb + PVC | `type: mongodb` | outputs có thêm `authSource` |
| StatefulSet/Deployment redis | `type: redis` | mặc định KHÔNG PVC (cache); cần auth → `params.auth: true` |
| Ingress nginx (host/path/tls) | `type: route` | render Ingress nginx CHUẨN như cụm cũ; mỗi host/path = 1 resource route; `params.bodySize` → proxy-body-size, `params.tlsSecret` → khối tls |
| Service gọi Service nội bộ | `type: service` | `params: {workload, port}` |
| Secret app-config nhiều key (`be-secret`) | `type: app-config` | khai `params.keys` (TÊN key), ops điền GIÁ TRỊ trên cụm 1 lần |
| CronJob `*-auto-backup` / `*-cleanup-backup` | `params.backup` của `mysql`/`mongodb` | `{enabled, schedule, cleanupSchedule, retentionDays, storage}` |
| imagePullSecrets (artifactory/jfrog/harbor cũ) | patch env tự tiêm | tên secret cấu hình ở biến `$pullSecret` đầu `patches/<env>.tpl`; secret tạo create-if-missing |
| ConfigMap mount file cấu hình (`mysql-conf`, nginx conf) | chưa có type riêng | ít gặp; trước mắt: nướng vào image hoặc chờ type `config-file` (xem Non-goal) |
| NetworkPolicy, RBAC, ServiceAccount riêng | không map | platform chưa hỗ trợ; xử lý tay nếu app thật sự cần |
| nodeSelector/hostPath (timezone...) | không map (chủ đích) | cụm mới không nên ghim node; timezone đặt qua env `TZ` |

## Đối chiếu nhanh 22 namespace → resource cần dùng

| Namespace | score.yaml gồm | Lưu ý |
|---|---|---|
| dap, knox2fem, opn, portal, service-portal | `containers` (+`route` nếu có Ingress) | app đơn, dễ nhất — làm wave đầu |
| survey-doe | 2 workload + 4 route | 2 phiên bản chạy song song |
| fem | 1 workload + route | cũ là StatefulSet web — sang Deployment được (không state thật) |
| event-management, otm | be/fe + `mysql` (5.6) + route | **otm có mẫu sẵn** (`examples/migration/otm/` — dựng từ manifest Rancher công ty); mysql 5.6 EOL: `params.image` giữ 5.6/5.7 lúc migrate, nâng cấp sau. Lưu ý: Service DB tên `<workload>-mysql` (headless) thay vì `mysql-prd` cũ — app đọc host qua biến, không hardcode |
| moodle | workload + route | mariadb NGOÀI cụm → giữ endpoint qua `app-config` |
| moodle-v2 | workload + `mysql` (params.image mariadb) + route | |
| okr, okr-dep | be/fe + `mysql` + `redis` + route | mẫu có sẵn; okr-dep = staging của okr → cùng score.yaml, khác env |
| face-reco | 4 workload + `mysql` (5.7) | service AI nội bộ gọi nhau qua `type: service` |
| feedback360 | be/fe + `postgres` + `app-config` + 2 route | mẫu có sẵn |
| security-cloud | be/fe + `mongodb` + route | |
| shift-handover | be/fe + `mongodb` (+backup) + `app-config` + 2 route | mẫu có sẵn; PVC image của backend cũ → chuyển file vào object storage/image |
| passbolt, passbolt-v4 | workload + `mysql` (+backup) + route | passbolt có PVC riêng (gpg key) — cần mount, xử lý tay khi migrate |
| acs | be/fe + `redis` (+arangodb — xem dưới) | |

## Các đánh giá được yêu cầu (§8 tài liệu yêu cầu)

**keycloak — xếp vào HẠ TẦNG, không onboard qua Score.** Lý do: (1) là SSO dùng chung —
gần như mọi app (`KEYCLOAK_URL` xuất hiện trong be-secret của nhiều app) phụ thuộc vào nó,
vòng đời/upgrade độc lập với mọi app; (2) cần HA + tuning DB riêng, không khớp khuôn
"mỗi workload một DB tự sinh password"; (3) đứng trong luồng đăng nhập của cả công ty —
không nên để một lần render catalog đụng vào. Đề xuất: deploy 1 lần/cụm bằng Helm chart
chính thức (hoặc operator) do team hạ tầng quản, app chỉ trỏ tới qua `app-config`
(`KEYCLOAK_URL`, `KEYCLOAK_REALM`, ...). Không cần code trong catalog.

**svms — xếp vào HẠ TẦNG (giám sát), không migrate như app.** Chứa grafana/prometheus +
mysql giám sát nội bộ. Cụm 1.35 nên có stack giám sát cụm riêng (kube-prometheus-stack)
do team hạ tầng dựng; dashboard/exporter đặc thù của svms chuyển vào stack đó. Migrate
svms như app nghiệp vụ sẽ tạo 2 hệ giám sát song song — không đáng.

**arangodb — NON-GOAL, làm tay.** Chỉ 1 app dùng (acs, bản 3.7.12 cũ). Viết provisioner
cho 1 consumer không bõ chi phí bảo trì; ArangoDB có operator riêng nếu về sau cần.
Cách làm tay: dựng StatefulSet arangodb trong ns `acs-<env>` theo khuôn manifest cũ
(`out/old/manifests/acs/`), app trỏ tới qua `app-config` (`ARANGO_URL`, ...). Nếu xuất hiện
consumer thứ 2 → viết block `arangodb` theo checklist `them-provisioner-moi.md`.

## Di trú dữ liệu (chỗ cắm — ngoài phạm vi bản này, KHÔNG tự động)

Catalog chỉ dựng datastore RỖNG với password mới. Quy trình đề xuất khi cutover từng app:

1. Deploy app lên cụm mới (staging → chạy ổn), datastore rỗng.
2. Freeze ghi ở cụm cũ (tắt route hoặc thông báo bảo trì).
3. Dump ở cụm cũ → restore vào cụm mới, chạy từ máy quản trị thấy cả 2 cụm:
   - mysql: `kubectl exec` mysqldump ở cụm cũ → `mysql -h <svc> -p"$PW"` vào pod mới
     (hoặc qua `kubectl port-forward`). Password mới: secret `<workload>-db-credentials`.
   - postgres: `pg_dump`/`pg_restore` tương tự.
   - mongodb: `mongodump`/`mongorestore --authenticationDatabase admin`.
   - PVC file (passbolt gpg, ảnh upload): `kubectl cp` hoặc job rsync tạm.
4. Điền `app-config` secret (giá trị lấy từ secret cũ: `kubectl get secret be-secret -o yaml` ở cụm cũ).
5. Trỏ DNS host sang ingress-nginx của cụm app mới; giữ cụm cũ read-only 1–2 tuần làm rollback.

CronJob backup (nếu bật) chỉ chạy sau khi datastore mới có dữ liệu — không ảnh hưởng cutover.
