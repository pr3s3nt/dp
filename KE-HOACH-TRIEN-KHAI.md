# Kế hoạch triển khai IDP — đến khi "tạo repo mới, viết score, push là lên staging"

Phạm vi ước tính: từ hiện trạng (code v2 đã xong, cụm K8s + Rook Ceph + Harbor + GHES + runner self-hosted đã có) đến trạng thái **tự động hoàn toàn cho staging**. Đơn vị: **ngày công** (1 người làm platform, là bạn). Ước tính có khoảng vì phụ thuộc độ "sạch" của môi trường công ty.

## Tổng quan

| Giai đoạn | Nội dung | Ước tính |
|---|---|---|
| A | Chuẩn bị runner + image nền | 1 – 1.5 ngày |
| B | Test tay app mẫu (deploy-local) | 0.5 – 1 ngày |
| C | Nối GHES: repo + secrets + orchestrator | 2 – 3.5 ngày |
| D | ArgoCD + chuỗi tự động end-to-end | 2 – 3 ngày |
| **Tổng (mục tiêu staging tự động)** | | **5.5 – 9 ngày công** (~2 tuần lịch) |
| E (sau đó, không chặn mục tiêu) | Hardening trước khi mở cho team khác | +2 – 4 ngày |

Sau khi platform chạy: **chi phí thêm 1 app mới ≈ 30–60 phút** (tạo 2 repo, đặt 2 secrets, viết score.yaml) — đây là con số đáng đưa vào báo cáo.

---

## Giai đoạn A — Chuẩn bị runner + image nền (1 – 1.5 ngày)

| # | Việc | Ước tính | Ghi chú |
|---|---|---|---|
| A1 | Cài `score-k8s` 0.15.0 + `yq` v4 lên runner; kiểm tra `kubectl`, `docker`, quyền vào Harbor | 0.5 | binary chép tay một lần |
| A2 | Kiểm tra node cụm pull được `postgres:16-alpine` chưa; nếu chưa: mirror vào Harbor (project `dockerhub`, public) + sửa 1 dòng image trong provisioner | 0.25 | pull–tag–push từ runner |
| A3 | Kiểm tra `kubectl get storageclass` — khớp `rook-ceph-block`; kiểm tra/cài Traefik (helm, image qua Harbor) | 0.25 – 0.75 | nếu cụm đã có ingress khác, quyết định dùng chung hay cài riêng |

**Đầu ra:** runner đủ đồ nghề; cụm sẵn sàng nhận app.

## Giai đoạn B — Test tay app mẫu (0.5 – 1 ngày)

| # | Việc | Ước tính | Ghi chú |
|---|---|---|---|
| B1 | Clone `v2` lên runner, chạy `deploy-local.sh` cho notes-app | 0.25 | REGISTRY + robot Harbor |
| B2 | Xử lý vướng môi trường lần đầu: cert Harbor tự ký trên node/docker, DNS nội bộ, NetworkPolicy | 0.25 – 0.75 | đây là chỗ hay "ăn" thời gian nhất |

**Đầu ra:** notes-app chạy trên `notes-app-staging`, demo được (UI + DB sống qua restart pod). **Milestone 1 — chứng minh provisioner/score hoạt động trên cụm thật.**

## Giai đoạn C — Nối GHES (2 – 3.5 ngày)

| # | Việc | Ước tính | Ghi chú |
|---|---|---|---|
| C1 | Tạo 3 repo trên GHES (`platform-repo`, `notes-app`, `notes-app-config`), push code, sửa TODO (`your-org`, domain Harbor) | 0.5 | |
| C2 | Gán runner cho 3 repo (hoặc org-level runner group) | 0.25 | |
| C3 | Tạo credentials: PAT dispatch, PAT đọc app repo, PAT push config repo, robot Harbor, kubeconfig cho CI (ServiceAccount riêng, chỉ quyền namespace + secret) | 0.5 – 1 | nên làm SA ít quyền ngay từ đầu, đừng dùng admin |
| C4 | Điền secrets vào 2 repo theo bảng trong `platform-repo/README.md` | 0.25 | |
| C5 | Chạy thử chuỗi: push notes-app → build → dispatch → orchestrator render → commit config repo; debug vòng đầu | 0.5 – 1.5 | kiểm tra actions bundled của GHES, log 2 phía |

**Đầu ra:** push code là manifest mới tự xuất hiện trong `notes-app-config`. **Milestone 2 — CI/orchestrator thông suốt.**

## Giai đoạn D — ArgoCD + tự động end-to-end (2 – 3 ngày)

| # | Việc | Ước tính | Ghi chú |
|---|---|---|---|
| D1 | Mirror image ArgoCD vào Harbor, sửa manifest install trỏ Harbor, cài vào cụm | 0.5 – 1 | phần "offline hoá" ArgoCD |
| D2 | Apply `project.yaml` + `appset-onprem.yaml`; tạo secret `github-token` trỏ GHES; sửa URL org trong appset về GHES | 0.5 | SCM provider của ApplicationSet cần API GHES |
| D3 | Kiểm tra auto-discovery: ArgoCD tự thấy `notes-app-config`, tạo app staging (auto-sync) + prod (manual) | 0.5 | |
| D4 | Chạy E2E thật: sửa 1 dòng code → push → **xem staging tự đổi, không đụng tay**; test luôn nút promote + Sync prod | 0.5 – 1 | **Milestone 3 — MỤC TIÊU ĐẠT** |

**Đầu ra:** đúng yêu cầu — tạo source mới, viết score, push là lên staging.

## Giai đoạn E — Hardening trước khi mở rộng cho team (2 – 4 ngày, làm sau)

- TLS cho Traefik (entryPoint `websecure` + cert nội bộ) — 0.5–1 ngày.
- RBAC/AppProject chặt hơn: giới hạn sourceRepos, destination theo namespace — 0.5 ngày.
- Giám sát chuỗi deploy: notification ArgoCD (GHES webhook/chat nội bộ), log orchestrator — 0.5–1 ngày.
- Tài liệu onboarding cho dev (1 trang: viết score.yaml + quy trình promote) — 0.5 ngày.
- Diễn tập rollback + backup Postgres (PVC snapshot của Ceph) — 0.5–1 ngày.

## Rủi ro chính & cách né

| Rủi ro | Ảnh hưởng | Giảm thiểu |
|---|---|---|
| Cert Harbor tự ký chưa được node/docker tin | ImagePullBackOff, push fail | chuẩn bị sẵn CA vào node + docker trên runner (hay gặp nhất) |
| npm không có mirror nội bộ | build frontend fail trên runner | runner của bạn đã build được image → xác nhận sớm ở A1 |
| GHES thiếu action bundled | CI fail | workflows đã chuyển hết sang lệnh thuần, chỉ còn `actions/checkout` (bundled) |
| ApplicationSet SCM provider không hợp GHES | ArgoCD không tự thấy repo | fallback có sẵn: generator `list` (comment trong appset), thêm app = thêm 1 dòng |
| Quyền PAT/robot thiếu | chuỗi đứt giữa chừng | làm checklist C3 một lượt, test từng token bằng curl trước |

## Điều kiện tiên quyết (xin trước khi bắt đầu)

Quyền admin 1 project Harbor + tạo robot; quyền tạo repo/org trên GHES + tạo PAT; quyền cluster-admin một lần để cài Traefik/ArgoCD + tạo ServiceAccount; 1 wildcard DNS nội bộ (hoặc vài A record) trỏ node Traefik.
