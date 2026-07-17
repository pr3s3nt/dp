# scripts/ — công cụ chạy tay cho maintainer platform

| Script | Dùng để |
|---|---|
| `test-local.sh` | Render một app bằng catalog (provisioner + patch) rồi **dry-run server-side** lên cụm qua kubeconfig, vào namespace sandbox `<app>-sandbox` — không đụng app đang chạy. Có `--apply` để thử thật và `--cleanup` để dọn. |

Chạy `./scripts/test-local.sh --help` để xem đủ cờ. Hướng dẫn từng bước cho việc
kiểm thử + rollout trong công ty: xem `HUONG-DAN-THUC-THI.md` ở repo tổng (gốc `v2/`).

Yêu cầu máy chạy: `score-k8s 0.15.0` (bản pin của platform), `yq` v4, `kubectl`.
Mạng nội bộ / air-gap: chép sẵn 3 binary này vào máy, không cần internet.
