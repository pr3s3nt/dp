# Chiến lược migration app vào platform & cập nhật an toàn

Tài liệu này trả lời 3 câu hỏi: (1) làm sao **ghim một app vào một trạng thái hạ tầng cụ thể** để thay đổi platform không lan sang app đang chạy, (2) **đưa các app hiện có** (cả nội bộ lẫn AWS) lên platform theo lộ trình nào, (3) **cập nhật mọi tầng của hệ thống an toàn** ra sao.

---

## Phần 1 — Cơ chế ghim phiên bản hạ tầng (`platform.lock`)

### Vấn đề

Provisioner/patch nằm ở platform-repo và dùng chung cho mọi app. Không có cơ chế ghim, một sửa đổi trên `main` (vd đổi cách sinh StatefulSet postgres) sẽ được **mọi app** nhận ngay ở lần render kế tiếp — sửa để phục vụ 1 app chưa test kỹ có thể phá app khác.

### Cơ chế (đã cài vào code)

- Mỗi app repo có file **`platform.lock`** chứa một ref của platform-repo (tag / branch / SHA).
- Orchestrator đọc lock, **checkout catalog (provisioners + patches) ở đúng ref đó** để render — không phải `main`.
- Ref catalog được ghi vào commit message của config repo (`deploy(app): staging <sha> (catalog: <ref>)`) → audit được app nào đang chạy trên phiên bản hạ tầng nào.
- `promote re-render` đọc lock **tại đúng commit được promote** → tái lập được quá khứ chính xác.

Hai lớp bảo vệ chồng nhau:

1. **Ghim chủ động** (`platform.lock`): app chỉ đổi phiên bản hạ tầng khi tự nâng lock.
2. **Bất biến của thiết kế**: manifest trong config repo là bản render sẵn — kể cả không ghim, app đang chạy **không bao giờ** bị đổi cho tới lần render kế tiếp của chính nó. Không có chuyện "sửa platform một cái, 20 app tự thay đổi trong đêm".

### Quy trình vận hành phiên bản catalog

1. Platform team phát hành catalog theo **tag**: `catalog/v1`, `catalog/v2`... (semver tùy mức thay đổi). App prod ghim tag, không ghim `main`.
2. Sửa provisioner/patch → mở PR vào platform-repo → **catalog-ci** tự render bộ score mẫu bằng catalog cũ và mới, đưa **diff manifest** vào job summary → reviewer thấy chính xác output đổi gì, không phải đoán từ template.
3. Merge + tag phiên bản mới. Lúc này **chưa app nào bị ảnh hưởng**.
4. **Canary**: chọn 1 app ít quan trọng (hoặc app đang cần tính năng mới), đổi `platform.lock` → push → staging của app đó render bằng catalog mới → test.
5. Đạt thì rollout dần các app khác theo wave (mỗi wave một PR đổi lock). Hỏng thì revert đúng 1 dòng lock của đúng 1 app.

Trạng thái mỗi app nằm ở đâu: `grep` một vòng các app repo, hoặc nhìn commit message trong config repo.

---

## Phần 2 — Chiến lược migration app hiện có vào platform

### Nguyên tắc chung

- **Migration = viết lại tầng deploy, không viết lại app.** App chỉ cần: chạy được trong container, cấu hình qua env var, log ra stdout. Đạt 3 điều đó là lên platform được.
- **Staging trước, chạy song song, cutover sau.** Không tắt hệ thống cũ cho tới khi bản trên platform chạy ổn định song song.
- **Mỗi wave nhỏ và có đường lùi.** Không migrate hàng loạt.

### Bước 0 — Kiểm kê & phân loại (1 lần cho toàn danh mục)

Lập bảng mọi app với các cột: nền tảng hiện tại (VM nội bộ / EKS / EC2...), stateful hay stateless, DB gì và bao lớn, cấu hình lấy từ đâu, có cron/queue/websocket không, lưu file local không, ai sở hữu, mức quan trọng. Từ đó xếp loại:

| Loại | Đặc điểm | Độ khó | Ưu tiên |
|---|---|---|---|
| A | Web/API stateless, config qua env, DB Postgres | Dễ — khớp catalog sẵn có | Wave đầu |
| B | Như A nhưng cần loại resource platform chưa có (redis, queue, cron) | Trung bình — cần thêm provisioner | Wave giữa |
| C | Stateful đặc thù (ghi file local, session in-memory), config hardcode | Khó — cần sửa app trước | Wave cuối |
| D | Không đáng migrate (sắp bỏ, phần mềm đóng gói, DB khác Postgres quá lớn) | — | Giữ ngoài platform, ghi rõ ngoại lệ |

### Playbook migrate MỘT app (lặp lại cho từng app)

1. **Containerize** (nếu chưa): Dockerfile theo mẫu notes-app; config chuyển hết sang env var; bỏ đường dẫn file local (chuyển sang DB hoặc chấp nhận mất — app loại C xử ở đây).
2. **Viết `score.yaml`** cho mỗi service: ports, env (`${resources.db.*}`), resources (`postgres` / `route` / `service`). Đây thường là lúc phát hiện app cần loại resource mới → thêm provisioner vào catalog **trước**, phát hành tag catalog mới.
3. **Tạo 2 repo** (`<app>`, `<app>-config`) + secrets + `platform.lock` ghim tag catalog hiện hành. ArgoCD tự nhận.
4. **Lên staging** bằng luồng chuẩn (push). Test chức năng, hiệu năng cơ bản.
5. **Chuyển dữ liệu** (app có DB):
   - Nội bộ → platform: `pg_dump` từ DB cũ → `pg_restore` vào Postgres do provisioner dựng (port-forward hoặc job trong cluster). Diễn tập trên staging trước, đo thời gian để chọn cửa bảo trì.
   - Chấp nhận một cửa dừng ghi ngắn (dump → restore → verify row count/checksum). App lớn cần near-zero-downtime thì dùng logical replication về sau — wave đầu không chọn app như vậy.
6. **Chạy song song & cutover**: deploy prod trên platform (promote) trong khi hệ cũ vẫn chạy → smoke test qua host tạm (vd `app.new.internal`) → cutover bằng **DNS/gateway** trỏ domain thật sang Traefik → theo dõi 24–48h.
7. **Đường lùi**: giữ hệ cũ ở trạng thái tắt-nhưng-bật-lại-được trong 1–2 tuần. Rollback = trỏ DNS ngược lại (kèm kế hoạch dữ liệu: trong cửa rollback, ghi nhận delta hoặc chấp nhận đồng bộ tay).
8. **Nghiệm thu & dọn**: tắt hẳn hệ cũ, thu hồi credential cũ, cập nhật tài liệu vận hành.

Chi phí điển hình: app loại A ~1–3 ngày công/app (phần lớn là bước 5–6); loại B cộng thêm thời gian viết provisioner (1 lần cho cả loại).

### Riêng app đang chạy trên AWS

Đích của app AWS là **nhánh cloud của chính platform này** (Giai đoạn 2) — không ép kéo về on-prem:

1. Dựng nền cloud một lần: `terraform/envs/staging` (VPC + EKS + RDS) → `argocd cluster add eks-staging` → apply `appset-cloud.yaml` → cài AWS Load Balancer Controller.
2. Mỗi app AWS theo đúng playbook trên, khác 3 điểm: CI đặt `TARGETS="cloud"` (hoặc cả hai nếu muốn chạy 2 nơi); DB đích là **RDS do Terraform tạo** (thêm block `module + kubernetes_secret` cho app trong env — hoặc import RDS instance hiện có vào Terraform state để giữ nguyên dữ liệu, đỡ luôn bước 5); route ra ALB thay vì Traefik.
3. Chuyển dữ liệu RDS→RDS: snapshot/restore hoặc `import` thẳng instance cũ vào Terraform — **ưu tiên import** vì không phải di chuyển dữ liệu.
4. Lưu ý mạng: runner GHES on-prem cần với được API server EKS (public endpoint có whitelist IP công ty, hoặc VPN). Xác nhận điều này **trước** khi hứa timeline.
5. Kết quả cuối: app AWS và app nội bộ dùng chung một giao diện score.yaml, một luồng deploy, chỉ khác `TARGETS`.

### Trình tự tổng thể đề xuất

Wave 0: notes-app (đã là app mẫu) → Wave 1: 1–2 app nội bộ loại A → Wave 2: các app loại A còn lại + viết provisioner cho nhu cầu loại B lộ ra → Wave 3: app loại B → Wave 4: dựng nhánh cloud, migrate app AWS → Wave 5: app loại C (sau khi sửa app). Sau mỗi wave: retro ngắn, cập nhật playbook.

---

## Phần 3 — Chiến lược cập nhật an toàn (theo từng tầng)

Nguyên tắc chung cho mọi tầng: **thay đổi nhỏ, có diff review được, thử ở phạm vi hẹp trước, luôn biết đường lùi trước khi tiến.**

### Tầng 1 — Code app (hằng ngày)

Đã an toàn theo thiết kế: staging auto-sync để phát hiện sớm; prod chỉ đổi qua nút promote + Sync tay; rollback = promote tag cũ. Không cần thêm gì.

### Tầng 2 — Catalog platform (provisioner/patch)

Theo đúng Phần 1: PR + catalog-ci render-diff → merge + tag → canary 1 app qua `platform.lock` → rollout wave → rollback bằng revert lock. **Không bao giờ** trỏ app prod vào `main`.

### Tầng 3 — Công cụ của luồng deploy (score-k8s, yq)

- Phiên bản pin trong workflow (`SCORE_K8S_VERSION`) và cài sẵn trên runner. Nâng cấp = một PR đổi version + chạy lại catalog-ci (render-diff sẽ lộ khác biệt output giữa 2 phiên bản công cụ y như khác biệt catalog).
- Nâng trên staging của 1 app canary trước khi đổi cho orchestrator (có thể tách: runner cài 2 phiên bản, env var chọn).

### Tầng 4 — Thành phần platform trên cụm (Traefik, ArgoCD) và chính cụm K8s

- **Trước mọi lần nâng cấp**: snapshot etcd + xác nhận PVC snapshot của Ceph hoạt động; đọc release notes phần breaking changes (đặc biệt CRD của Traefik/ArgoCD).
- **Traefik**: nâng bằng helm với image mirror qua Harbor; test bằng cách curl toàn bộ route staging sau nâng cấp (danh sách route lấy từ `kubectl get ingressroute -A`). Traefik có phiên bản CRD mới → sửa provisioner `route` là một thay đổi catalog, đi theo luồng Phần 1.
- **ArgoCD**: nâng cấp không đụng app đang chạy (app chỉ là manifest đã apply); rủi ro chính là ApplicationSet — sau nâng cấp xác nhận số Application không đổi trước khi rời màn hình.
- **Cụm K8s**: nâng node theo kiểu cuốn chiếu (drain từng node — Ceph cần chú ý quorum OSD/MON, drain chậm và chờ `ceph -s` HEALTH_OK giữa các node); staging cluster trước prod cluster nếu tách cụm, hoặc chấp nhận cửa bảo trì nếu chung cụm.
- **Harbor/GHES**: nằm ngoài đường deploy runtime của app (app đang chạy không phụ thuộc chúng) → cửa bảo trì của chúng chỉ chặn deploy mới, không chặn app. Cứ nâng trong giờ ít deploy.

### Ma trận sự cố → đường lùi

| Hỏng ở đâu | Triệu chứng | Đường lùi |
|---|---|---|
| Code app mới | staging/prod lỗi chức năng | promote tag cũ (prod) / push revert (staging) |
| Catalog mới ở 1 app canary | app canary staging hỏng sau nâng lock | revert 1 dòng `platform.lock` của app đó, push lại |
| Manifest sai đã vào config repo | ArgoCD báo degraded | revert commit trong config repo → Sync |
| score-k8s phiên bản mới | orchestrator render fail/khác thường | revert PR đổi version (binary cũ vẫn trên runner) |
| Traefik/ArgoCD nâng cấp hỏng | route chết / app không sync | helm rollback / apply lại manifest ArgoCD bản cũ (app đang chạy không chết theo) |
| Secret bị xóa nhầm | pod CrashLoop vì thiếu credential | chạy lại deploy (create-if-missing tái tạo harbor-pull; secret DB cần backup — xem dưới) |

**Việc nên làm sớm**: backup định kỳ các Secret `*-db-credentials` (velero hoặc script export vào két an toàn) — vì password nằm duy nhất trên cụm, mất namespace là mất đường vào dữ liệu cũ; và snapshot PVC Ceph theo lịch cho mọi DB prod.
