# Đề xuất: xử lý đồng thời (nhiều người dùng cùng lúc) — BẢN ĐỂ REVIEW

> Trạng thái: chờ review. Phương án A đã triển khai sẵn trong repo (có thể revert);
> B/C/D là lựa chọn nâng cấp theo giai đoạn.

## 1. Các IDP/GitOps tool ngoài kia đang xử lý thế nào

| Tool / nền tảng | Cơ chế chống race khi ghi cùng lúc |
|---|---|
| **Flux (image-automation-controller)** | Optimistic concurrency: mỗi lần chạy **rebase lên trạng thái mới nhất** của nhánh rồi push; push trượt thì lần reconcile sau thử lại. Không lock. |
| **Kargo (Akuity — hệ Argo)** | Promotion là CRD, controller xử lý **tuần tự theo từng Stage**; bước `git-push` có **retry nội bộ**; khuyến cáo thiết kế để các promotion song song **không ghi cùng file** trên cùng nhánh. |
| **Argo CD / ApplicationSet** | Declarative, **last-commit-wins**: cluster luôn hội tụ về commit mới nhất; bản thân controller là single-reconciler nên không tự giẫm chân mình. |
| **Humanitec (Platform Orchestrator)** | **API-first**: desired state nằm trong DB của orchestrator, deploy là API call được tuần tự hóa giao dịch; GitOps chỉ là "đầu ra" tùy chọn. Git không còn là điểm tranh chấp. |
| **GitHub / GitLab (nền CI)** | `concurrency.group` (GitHub) / `resource_group` (GitLab) để **xếp hàng pipeline theo khóa**; **merge queue / merge train** tuần tự hóa việc merge vào nhánh bảo vệ ngay từ thượng nguồn. |
| **Atlantis / Terraform** | **Lock tường minh** theo project/workspace khi PR đang plan/apply; state backend có lock riêng (DynamoDB). |

Rút gọn: có 3 trường phái — (1) **optimistic retry+rebase** (Flux/Kargo), (2) **hàng đợi tuần tự theo khóa** (Kargo per-stage, CI concurrency group, Atlantis lock), (3) **bỏ git khỏi đường ghi, dùng DB + API** (Humanitec). Đa số nền tảng tự xây trên GitOps dùng kết hợp (1)+(2).

## 2. Race cụ thể của platform mình

- Dev push score.yaml: **git tự tuần tự hóa** (push sau bị từ chối non-fast-forward) — không phải vấn đề.
- Vấn đề thật: 2 commit liên tiếp cùng app → 2 run orchestrator **song song** cùng ghi `<app>-config` → có thể ghi ngược thứ tự (bản cũ đè bản mới).
- Lợi thế sẵn có: **mỗi app một config repo riêng** → miền tranh chấp chỉ gói trong 1 app; staging/prod nằm khác file → đúng khuyến cáo "không ghi cùng file" của Kargo.

## 3. Các phương án

### A. Concurrency group theo app + push retry/rebase — ĐÃ LÀM (baseline)

Đúng trường phái (1)+(2), trùng cách Flux/Kargo làm:
- `concurrency: group: app-<app>` trên job deploy + promote → mọi run đụng cùng app xếp hàng, khác app song song.
- Push config repo có retry 3 lần + `pull --rebase` (phòng người/công cụ ngoài Actions cũng ghi).

| Ưu | Nhược |
|---|---|
| 0 hạ tầng mới, 10 dòng YAML | Hàng đợi GitHub chỉ giữ 1 run pending (run giữa bị skip — chấp nhận được vì bản cuối là bản đúng) |
| Trùng thực hành Kargo/Flux | Chỉ bảo vệ những gì đi qua Actions; ai chạy script tay ngoài luồng thì retry+rebase là lưới duy nhất |
| Khác app không chặn nhau | Thứ tự dispatch đến muộn (hiếm) vẫn có thể lệch |

### B. Chặn từ thượng nguồn: protected branch + PR + merge queue trên app repo

Bắt buộc mọi thay đổi score.yaml đi qua PR; bật merge queue để merge tuần tự.
- Ưu: loại luôn kịch bản "2 người cùng push main"; lịch sử sạch, có review.
- Nhược: thêm ma sát quy trình cho 22 team app; không thay được A (race nằm ở orchestrator, không phải ở push).
- Đề xuất: **bật dần** cho app đông người sửa; là bổ sung, không phải thay thế.

### C. Lớp promotion chuyên dụng: Kargo (hệ Argo, self-host được)

Thay job promote (và dần cả deploy write-back) bằng Kargo: Stage staging→prod, Freight theo dõi image, promotion tuần tự per-stage, có UI + verification gate, retry git-push tích hợp.
- Ưu: đúng "mảnh còn thiếu" của GitOps (promotion); khớp hệ ArgoCD đang dùng; giải luôn nhu cầu gate/rollback có kiểm soát khi số app tăng.
- Nhược: thêm 1 hệ thống phải vận hành (CRD, controller, nâng cấp); học phí cho team; overkill khi mới 3–5 app.
- Đề xuất: **cân nhắc ở giai đoạn ≥10 app onboard** hoặc khi cần UI promotion cho nhiều team.

### D. API-first orchestrator (kiểu Humanitec) — chân trời xa

Chuyển desired state vào DB + service orchestrator riêng, git chỉ là output.
- Giải triệt để race, nhưng là **viết lại kiến trúc**; không tương xứng quy mô 22 app nội bộ. Không đề xuất trong 12 tháng tới.

## 4. Khuyến nghị (thứ tự triển khai)

1. **Giữ A** (đã có trong repo) — đây là chuẩn ngành cho quy mô hiện tại. Review 2 file:
   `.github/workflows/orchestrator.yaml` (concurrency + retry), `README.md` (bảng đồng thời).
2. **Thêm vào A một guard rẻ tiền** (nếu review đồng ý, làm sau): trước khi push config,
   so SHA của dispatch với HEAD app repo; nếu đã có commit mới hơn đang xếp hàng → bỏ qua
   run này (last-wins tường minh thay vì dựa vào hàng đợi GitHub).
3. **B cho app đông người** khi bắt đầu onboard wave 2 (mysql apps — nhiều team đụng).
4. **Đánh giá C (Kargo)** sau khi ~10 app chạy ổn: PoC thay job promote cho 1 app.
5. D: ghi nhận, không làm.

## Nguồn tham khảo

- Kargo git-push retry + khuyến cáo không ghi cùng file: https://docs.kargo.io/user-guide/reference-docs/promotion-steps/git-push
- Kargo là lớp promotion cho GitOps: https://akuity.io/blog/kargo-gitops-promotion-layer
- Flux image-automation rebase/push behavior: https://fluxcd.io/flux/components/image/imageupdateautomations/ và https://github.com/fluxcd/image-automation-controller/issues/450
- Humanitec Platform Orchestrator (API-first, GitOps là output): https://developer.humanitec.com/app-humanitec-io/docs/platform-orchestrator/overview/
