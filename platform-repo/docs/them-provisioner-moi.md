# Cách thêm một provisioner mới (checklist cho maintainer)

Mục tiêu: một maintainer mới, theo checklist này, thêm được một loại datastore giả định
trong **< 1 giờ**. Nguyên tắc: mỗi loại = **một block độc lập** trong 2 file catalog,
không sửa block cũ, không copy-paste logic ra ngoài.

## Hợp đồng phải giữ (không thương lượng)

| Hạng mục | Quy ước |
|---|---|
| Biến xuất ra (datastore) | `host`, `port`, `name`, `username`, `password` — `password` LUÔN là `encodeSecretRef` |
| Tên Secret | `<workload>-db-credentials` (datastore chính) / `<workload>-<loại>-credentials` (phụ trợ như redis) |
| Ngữ nghĩa Secret | create-if-missing — CI/harness chỉ `kubectl create`, không bao giờ ghi đè, không commit git |
| Label | Deployment/StatefulSet/CronJob/PVC do provisioner sinh: `app.kubernetes.io/component: datastore` — để patch env bỏ qua replicas/resources |
| Resources | đặt NGAY trong provisioner (datastore tự biết nhu cầu); patch chỉ set cho container chưa có |
| Password | sinh trong `state:` (giữ ổn định giữa các lần generate), không nằm trong `outputs` dạng plaintext |
| Storage | `storageClassName: rook-ceph-block` (onprem), dung lượng qua `params.storage` |

Giữ đúng bảng trên thì `score.yaml` của app **không đổi** khi backend đổi
(StatefulSet → RDS, secret tay → Sealed Secrets/ESO).

## Checklist 8 bước

1. **Chọn tên `type`** (vd `rabbitmq`). Ngắn, không viết tắt tối nghĩa — dev sẽ gõ nó trong score.yaml.
2. **Viết block onprem** trong `score/provisioners/onprem.provisioners.yaml`:
   copy block `mysql` (khuôn đầy đủ nhất: params + state + backup) rồi sửa:
   - `uri: template://onprem/<type>`, `type: <type>`
   - `init:` tên tài nguyên `{{ .SourceWorkload }}-<type>`, secretName theo hợp đồng
   - image/port/env/mount đặc thù của datastore
   - phần `backup` giữ nếu có công cụ dump (đổi lệnh `mysqldump` → công cụ tương ứng), bỏ nếu không.
3. **Viết block cloud** trong `cloud.provisioners.yaml`: copy block `mysql` cloud —
   thường CHỈ là `outputs` đọc từ Secret Terraform, không manifests. Ghi rõ key Secret
   mà Terraform phải ghi (host/port/dbname/username/password).
4. **Viết doc đầu block** (comment): params nhận vào + default, biến xuất ra, giả định
   (storageClass, image, air-gap proxy-cache). Đây là tài liệu chính của provisioner.
5. **Thêm ví dụ**: cập nhật một app trong `score/examples/` (hoặc thêm app mới trong
   `examples/migration/`) dùng type mới — examples là input cho catalog-ci render-diff.
6. **Test render không cần cụm**:
   `./scripts/test-local.sh score/examples/migration/<app> --render-only`
7. **Test trên cụm**: `./scripts/test-local.sh ... --kubeconfig <kc> [--insecure-skip-tls-verify]`
   → server-side dry-run vào ns sandbox; muốn chắc hơn: `--apply` rồi `--cleanup`.
8. **PR + tag**: mở PR (catalog-ci render-diff cho reviewer soi), merge, đánh tag
   `catalog/vX+1`. App nâng `platform.lock` qua PR riêng, canary 1 app trước.

## Bẫy đã gặp (đọc trước khi viết template)

- `{{ .Params.backup.enabled }}` nổ khi params không có `backup` → luôn
  `{{ $backup := .Params.backup | default dict }}` rồi `{{ if $backup.enabled }}`.
- 2 resource cùng type trên 1 workload sẽ đụng tên (`.SourceWorkload` là thành phần duy nhất
  của tên) — quy ước hiện tại: mỗi workload 1 datastore chính. Route thì đã né bằng cách
  đưa host+path vào tên.
- Output chứa secret chỉ được đi qua `encodeSecretRef`; score-k8s **không cho nối chuỗi**
  quanh giá trị đó (không viết được `mysql://root:${password}@...`) — nhu cầu URI đầy đủ
  giải quyết bằng `type: app-config`.
- Đừng đổi tên Service do score-k8s sinh (annotation `k8s.score.dev/service-name`) —
  provisioner `service` và `route` tra theo tên workload.
- Patch template không có sprig đầy đủ như provisioner — trong `*.tpl` chỉ dùng builtins
  (`index`, `eq`, `and`, `with`, gán biến) cho chắc.
