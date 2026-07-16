# REVIEW — IDP v2: tổ chức, thiết kế, khả năng mở rộng, bảo trì

Ngày review: 16/07/2026. Phương pháp: đọc tĩnh toàn bộ file trong `v2/` (platform-repo, 2 app repo, 2 config repo, terraform, 5 tài liệu md + docx/pptx). Không chạy render, không có cụm để test — các nhận định về hành vi runtime là suy luận từ code. **File này chỉ đánh giá, không kèm sửa đổi nào vào code.**

## Đánh giá tổng quát

| Tiêu chí | Mức | Nhận xét ngắn |
|---|---|---|
| Tổ chức | **Tốt** | Ranh giới 4 loại repo rõ, quy ước đặt tên nhất quán, tài liệu phủ trọn vòng đời |
| Thiết kế | **Tốt** | Đúng các pattern hiện đại (rendered manifests, orchestrator, catalog pinning); còn vài khoảng trống runtime |
| Khả năng mở rộng | **Khá** | Trục "thêm app/service/loại resource" rất tốt; trục "thêm env/target/team" còn hardcode |
| Bảo trì lâu dài | **Khá → Tốt** | Cơ chế ghim phiên bản và đường lùi hiếm dự án nội bộ nào làm được; rủi ro chính là bus factor và bash phình |

Tổng thể: đây là một scaffold chất lượng cao với tư duy vận hành trưởng thành. Điều đáng giá nhất không phải code mà là **hệ quyết định đã chốt**: manifest render sẵn vào git, credential tập trung một chỗ, mọi tầng đều ghim phiên bản và đều có đường lùi viết sẵn. Trước khi tạo repo thật cần xử lý 1 lỗi kỹ thuật (file workflow hỏng — mục P1.1) và nên vá 3–4 điểm thiết kế nêu ở phần Ưu tiên.

---

## 1. Tổ chức dự án

### Điểm mạnh

**Ranh giới sở hữu đúng theo Conway.** `platform-repo` (team hạ tầng) / `app-repos` (dev) / `config-repos` (máy ghi, người review) / `terraform` (infra cloud) — mỗi thư mục là một repo thật khi triển khai, quyền và secrets được thiết kế theo đúng ranh giới đó. App repo chỉ giữ 2 secret (Harbor push + dispatch token); toàn bộ credential hạ tầng nằm ở platform-repo. Đây là cách chia least-privilege đúng bài.

**Quy ước thay cho cấu hình.** `<app>-config` để ApplicationSet tự quét, namespace `<app>-<env>`, secret `<workload>-db-credentials`, container chính tên `main`, image `<app>-<svc>:<sha>` — thêm app mới không sửa một dòng nào phía platform. Các quy ước đều được ghi lại tại chỗ dùng (comment trong từng file) chứ không chỉ ở README.

**Tài liệu phủ trọn vòng đời, chất lượng hiếm thấy.** Bốn tài liệu md chia đúng 4 giai đoạn: cài offline → test tay → kế hoạch triển khai (có ước lượng ngày công, milestone đo được) → chiến lược migration/cập nhật (phân loại app A/B/C/D theo wave, ma trận "hỏng ở đâu → đường lùi"). HUONG-DAN-TEST-TAY còn thiết kế cả vòng lặp sửa lỗi và khối lệnh thu thập debug. Đây là tài sản lớn nhất về mặt bảo trì.

**Kỷ luật .gitignore cho secret.** `.score-k8s/` (chứa password sinh ra), `secrets.yaml`, `kubeconfig*` bị chặn ở cả root lẫn từng app repo.

### Vấn đề

**[P1] 4 file workflow của app repos bị đệm NUL bytes ở cuối file.** Kiểm tra bằng script: `shop-app/ci.yaml` (6.140 bytes, 3.813 NUL), `shop-app/promote.yaml` (4.687 NUL), `notes-app/ci.yaml` (2.184 NUL), `notes-app/promote.yaml` (3.168 NUL). Nội dung YAML phía trước vẫn đầy đủ, nhưng phần đuôi toàn `\x00` — `git diff` đã coi chúng là binary, `file` báo "data", và GitHub Actions nhiều khả năng từ chối parse. Các file phía platform-repo sạch. Có vẻ do sự cố khi ghi file (editor/sync). **Bắt buộc làm sạch trước khi push lên GHES** — nếu không, toàn bộ chuỗi CI chết ngay bước đầu và triệu chứng (workflow không chạy/parse error) không gợi ý gì về nguyên nhân.

**[P3] Tài liệu đã bắt đầu drift — đúng rủi ro mà chính dự án cảnh báo.** Hai ví dụ cụ thể: (1) `bootstrap/onprem.md` viết storageclass "mặc định `standard`" trong khi provisioner thực tế là `rook-ceph-block`; (2) comment trong `onprem.provisioners.yaml` còn trỏ "bước 'split secrets' trong **ci.yaml**" — bước này đã dời sang orchestrator từ khi tách mô hình. Ngoài ra bảng secrets được lặp ở 4 chỗ (README gốc, platform README, bootstrap, app README) và nội dung tổng quan lặp lại trong docx/pptx. Nên chọn 1 nguồn chân lý cho mỗi loại thông tin, các chỗ khác chỉ link; docx/pptx đánh dấu rõ "snapshot ngày X, nguồn chân lý là các file md".

**[P3] `.gitignore` đang ignore `.terraform.lock.hcl`.** Lock file của Terraform nên được commit — đây chính là "platform.lock của provider". Ignore nó ngược với triết lý pinning mọi tầng mà dự án theo đuổi (score-k8s 0.15.0, catalog tag, image theo SHA).

**[P3] `platform.lock` của cả 2 app đang là `main`** trong khi tài liệu của chính dự án nhấn mạnh "app prod ghim tag, không ghim main". Hợp lý cho scaffold, nhưng nên tag `catalog/v1` ngay khi lập platform-repo thật và đổi 2 file lock trong cùng đợt, để thói quen đúng ngay từ app đầu tiên.

---

## 2. Thiết kế

### Điểm mạnh

**Rendered manifests pattern — lựa chọn đúng và nhất quán.** Bỏ Kustomize/Helm ở tầng sync, manifest hoàn chỉnh nằm trong config repo, ArgoCD chỉ sync nguyên thư mục. Hệ quả tốt lan ra khắp nơi: diff review được bằng mắt, lịch sử git = lịch sử deploy, rollback = revert commit, và "sửa platform không bao giờ tự lan sang app đang chạy" là bất biến cấu trúc chứ không phải lời hứa.

**Cơ chế `platform.lock` + catalog-ci là điểm trưởng thành nhất.** Ghim theo app, canary từng app, rollout theo wave, revert 1 dòng; ref catalog ghi vào commit message để audit; promote `re-render` đọc lock **tại đúng commit được promote** nên tái lập được quá khứ. catalog-ci render bộ score mẫu bằng catalog cũ/mới và đưa diff manifest vào job summary — reviewer nhìn output thật thay vì đoán template Go. Bộ `score/examples/` phủ đủ 3 loại resource đóng vai trò golden files. Đây là mô hình quản trị thay đổi mà nhiều platform team lớn cũng chưa làm được.

**Luồng secret kỷ luật.** Secret không bao giờ vào git (tách bằng yq trước commit); create-if-missing nên password trên cụm không bao giờ bị xoay ngoài ý muốn; app chỉ nhận qua `secretKeyRef`; tên secret là hợp đồng ổn định cho phép thay bằng Sealed Secrets/ESO sau này mà app không đổi. Phía cloud, Terraform ghi secret cùng convention — hai thế giới gặp nhau đúng một điểm nối.

**Air-gap được nghĩ từ đầu, không phải vá sau.** Không action marketplace (chỉ `actions/checkout` bundled), `${{ github.api_url }}` để tự đúng trên GHES, binary cài sẵn trên runner với install-if-missing, hướng dẫn mirror image qua Harbor, bảng rủi ro GHES thực tế (cert tự ký, npm mirror, appset SCM provider có fallback `list` viết sẵn dạng comment).

**Build một lần, promote bằng tag.** Promote không build lại image; `tag-only` vs `re-render` phân biệt đúng hai loại thay đổi; prod manual sync làm gate cuối. Staging auto-sync với prune+selfHeal — đúng vai.

**Terraform mỏng và đúng chỗ.** Bọc module cộng đồng thay vì tự viết; staging/prod cùng module chỉ khác sizing (1 NAT vs NAT/AZ, micro vs multi-AZ + deletion protection); SG của RDS chỉ mở cho node EKS; subnet tags cho ALB controller có sẵn. Giới hạn phạm vi "Terraform không deploy app" giữ cho hai hệ không dẫm chân nhau.

### Vấn đề

**[P1] Orchestrator không có chống chạy đua (`concurrency`).** Hai push liên tiếp vào cùng app → hai run orchestrator song song cùng checkout config repo rồi cùng push: run sau fail non-fast-forward, hoặc tệ hơn là commit của SHA cũ đè lên SHA mới (mất thứ tự deploy). Sửa rẻ: `concurrency: group: deploy-${{ github.event.client_payload.app }}` ở mức job/workflow. Với nhiều app đẩy cùng lúc, mọi deploy của cả org còn xếp hàng qua một runner self-hosted — đủ cho vài chục app nhưng nên biết trần này tồn tại.

**[P1] Orchestrator tin `client_payload` vô điều kiện.** `app` và `repo` là hai trường độc lập: bất kỳ repo nào trong org có `PLATFORM_DISPATCH_TOKEN` đều có thể gửi `app=shop-app, repo=evil-repo` — orchestrator sẽ render code của evil-repo và ghi đè `shop-app-config`, ArgoCD deploy vào namespace của shop-app. Trong org nội bộ rủi ro là mức "repo bị chiếm/cấu hình nhầm", nhưng phòng tuyến rẻ: orchestrator assert `app == basename(repo)` (hoặc duy trì whitelist app→repo) trước khi làm gì tiếp.

**[P1] Nhánh cloud thiếu `harbor-pull` — sẽ ImagePullBackOff ngay lần đầu.** Patch template tiêm `imagePullSecrets: harbor-pull` vào mọi workload cho **cả hai target** (patch chia theo env, không theo target), nhưng không ai tạo secret này trên EKS: `setup_ns` của orchestrator chỉ chạy với kubeconfig onprem, Terraform chỉ tạo namespace + `*-db-credentials`. Câu hỏi lớn hơn cùng chỗ: node EKS pull image từ Harbor on-prem qua đường mạng nào — tài liệu mới xét chiều runner→EKS API, chưa xét chiều EKS→Harbor (thực tế thường phải replicate Harbor lên registry cloud hoặc mở đường mạng riêng). Nên chốt trước khi hứa timeline Giai đoạn 2 — đúng tinh thần mà CHIEN-LUOC đã dặn cho chiều ngược lại.

**[P2] Semantics `postgres` lệch nhau giữa onprem và cloud — phá lời hứa "cùng một giao diện".** Onprem: mỗi workload khai `type: postgres` được một StatefulSet riêng, DB riêng. Cloud: `envs/*/main.tf` ghi cùng một bộ `host/dbname/username/password` cho cả `order-service` lẫn `payment-service` — hai secret khác tên nhưng nội dung y hệt, tức **hai service dùng chung một database `appdb`** trên cùng instance (bảng `orders` và `payments` nằm cạnh nhau, chung quyền). README terraform viết "dùng chung 1 instance, khác Secret" — về chữ thì đúng, về nghĩa thì đang chung cả database chứ không chỉ chung instance. Ít nhất nên tách `dbname` theo workload (cần thêm bước tạo DB trong instance — provider postgresql hoặc job init), hoặc ghi thẳng vào tài liệu rằng cloud hiện chung DB và đó là trade-off tạm.

**[P2] `appset-cloud` quét mọi repo `*-config` kể cả repo chưa có thư mục `cloud/`.** `notes-app-config` chỉ có `onprem/` — khi apply appset-cloud, ArgoCD vẫn tạo Application `notes-app-{staging,prod}-cloud` trỏ path không tồn tại → app báo lỗi vĩnh viễn trên dashboard. SCM provider generator có filter `pathsExist` — thêm `pathsExist: [cloud]` là xong.

**[P2] Không có liveness/readiness probe ở bất kỳ tầng nào.** score.yaml mẫu không khai, patch không tiêm, provisioner postgres cũng không có. Hệ quả prod: 3 replicas nhận traffic ngay khi container start (chưa chắc đã sẵn sàng), rolling update không có gate sức khỏe, selfHeal của ArgoCD không cứu được app treo-nhưng-chưa-chết. Score spec có chỗ khai probe; chỗ sửa đúng nhất là platform — tiêm default probe qua patch template (dùng chính `/health` mà mọi service mẫu đã có) và cho dev override trong score.yaml.

**[P2] Patch template một cỡ cho tất cả.** Ba điểm cứng: (1) mọi Deployment prod đều 3 replicas — app singleton (consumer, cron-like) không express được; (2) resources 50m/64Mi (staging) và 100m/128Mi (prod) cho mọi app — team có app nặng sẽ đòi đổi ngay tuần đầu; (3) StatefulSet postgres **không được set resources** (patch chỉ đụng Deployment) — DB chạy không giới hạn trên cụm chung. Hướng mở đúng kiến trúc hiện tại: patch đọc annotation/metadata từ score.yaml (vd `k8s.score.dev/replicas`) làm kênh override có kiểm soát, thay vì mỗi nhu cầu lại một phiên bản catalog.

**[P2] Multi-tenancy chưa có hàng rào nào.** Không ResourceQuota, không LimitRange, không NetworkPolicy (pod của app này gọi thẳng postgres của app khác qua DNS cross-namespace được); AppProject cho phép destination `*`/`*`; staging và prod onprem chung một cụm. Tất cả đã nằm trong "Giai đoạn E — hardening" của kế hoạch, nhưng NetworkPolicy chặn cross-namespace và ResourceQuota per-namespace nên kéo lên **trước khi onboard team thứ hai** — sau đó mới siết là phải đàm phán lại với từng team.

**[P2] Vòng đời secret DB mới có "sinh", chưa có "xoay" và "cứu".** create-if-missing nghĩa là password sống vĩnh viễn; muốn xoay phải đồng thời `ALTER USER` trong postgres + update secret — chưa có quy trình. Kịch bản xấu đã được CHIEN-LUOC nhận diện (mất secret khi còn PVC = mất đường vào dữ liệu, vì render mới sinh password mới nhưng data dir giữ password cũ) và lời giải (backup `*-db-credentials` bằng velero/script) đang ở mục "nên làm sớm" — nên chuyển thành việc có chủ, có lịch, kèm một trang runbook khôi phục.

**[P3] Các vết gợn nhỏ đáng ghi lại.**
- `REGISTRY` khai ở 2 nơi độc lập (ci.yaml của từng app và orchestrator) — lệch nhau là orchestrator render trỏ image không tồn tại. Nên truyền registry trong payload hoặc chỉ giữ ở orchestrator.
- Promote `tag-only`: không kiểm tra tag có tồn tại trong Harbor không (gõ nhầm SHA → prod manifest trỏ image ma, phát hiện muộn ở ArgoCD); regex `sub(":[^:]+$")` sẽ hỏng nếu sau này dùng digest `@sha256:`; yq chỉ sửa Deployment — hôm nay đủ, thêm CronJob/StatefulSet app là phải nhớ mở rộng.
- Parse `platform.lock` lấy `head -1` sau khi bỏ comment: file có dòng trống đầu → âm thầm fallback `main` dù tag nằm dòng dưới.
- `eks` module: `cluster_endpoint_public_access = true` không kèm biến giới hạn CIDR (tài liệu nói whitelist IP công ty nhưng module chưa có tham số đó); `enable_cluster_creator_admin_permissions = true` đã được comment "siết lại sau" — nên có ticket thật.
- `api-gateway/src/index.js` forward bỏ rơi query string (`req.path`) và không chuyển tiếp headers — với code mẫu sẽ bị team khác copy nguyên, nên sửa hoặc chú thích rõ giới hạn.
- Orchestrator map target→kubeconfig hardcode onprem (`setup_ns` gọi thẳng 2 secret onprem) — thêm target là sửa tay nhiều chỗ; nên đưa về một map khi làm Giai đoạn 2.

---

## 3. Khả năng mở rộng

Đánh giá theo từng trục, vì dự án mở rộng rất không đều giữa các trục — đây là điều bình thường, quan trọng là biết trục nào rẻ trục nào đắt.

**Trục rẻ (thiết kế đã trả tiền trước):**
- *Thêm app*: tạo 2 repo + 2 secrets + platform.lock, ArgoCD tự nhận qua quét `*-config`. Không sửa gì phía platform. Con số 30–60 phút/app trong KE-HOACH là khả tín.
- *Thêm service vào app*: tạo thư mục + score.yaml, orchestrator tự phát hiện `*/score.yaml`. Chỉ phải nhớ thêm tên vào matrix build của ci.yaml — điểm khai báo kép duy nhất còn lại; có thể tự sinh matrix từ danh sách thư mục để triệt nốt.
- *Thêm loại resource (redis, s3, queue...)*: thêm block vào 2 file provisioner + example vào catalog-ci + tag catalog mới. Đường đi đã có sẵn lưới an toàn (render-diff, lock, canary). Đây là trục mở rộng được thiết kế tốt nhất.

**Trục trung bình (phải sửa vài chỗ có chủ đích):**
- *Thêm env (vd `uat`)*: thêm patch template mới, sửa list generator trong 2 appset, sửa vòng render + `setup_ns` trong orchestrator, thêm thư mục config repo. Khoảng 4–5 điểm chạm, đều lộ rõ, không ngầm.
- *Thêm target/cụm mới*: bộ provisioner mới + appset mới là đúng thiết kế; vướng chính là orchestrator hardcode map kubeconfig theo onprem như đã nêu.

**Trục đắt (sẽ là giới hạn thật khi platform có nhiều team):**
- *Override theo app* (replicas, resources, probe): hiện không có kênh nào ngoài sửa catalog dùng chung. Đây gần như chắc chắn là yêu cầu đầu tiên từ team thật — nên thiết kế kênh annotation trong score.yaml trước khi bị đòi.
- *Cách ly giữa team*: quota/netpol/RBAC per-team chưa có (mục 2). Mở rộng số team trước khi có hàng rào là nợ khó đòi.
- *Throughput orchestrator*: mọi deploy của mọi app đi qua một workflow trên runner self-hosted, tuần tự theo runner. Vài chục app ổn; xa hơn cần concurrency per-app, thêm runner, và tách job render/secret/commit.
- *Loại workload ngoài web service*: cron, worker không listen port, app cần volume — Score spec hỗ trợ một phần nhưng catalog và patch hiện giả định "Deployment có Service". Migration doc đã xếp các app này vào loại B/C đúng thực tế.

## 4. Bảo trì lâu dài

**Nền đã tốt.** Bốn thứ quyết định chi phí bảo trì 3–5 năm đều đã có: (1) mọi tầng ghim phiên bản (image theo SHA, catalog theo tag/lock, score-k8s pin, module terraform pin `~>`); (2) mọi thay đổi có diff review được (config repo cho app, catalog-ci cho platform); (3) đường lùi viết sẵn thành ma trận cho từng lớp hỏng; (4) trạng thái sống của hệ thống rất ít (secret trên cụm + PVC + tfstate — còn lại tất cả tái lập từ git). Chiến lược nâng cấp từng tầng trong CHIEN-LUOC (kể cả chi tiết drain node có Ceph phải chờ HEALTH_OK) cho thấy người viết đã vận hành thật chứ không chỉ thiết kế.

**Rủi ro bảo trì lớn nhất — con người, không phải code.** KE-HOACH ghi rõ "1 người làm platform, là bạn". Toàn bộ hệ ghim/canary/rollback vận hành đúng chỉ khi người vận hành hiểu nó. Tài liệu hiện tại đã giảm đáng kể rủi ro này; nên bổ sung 2 thứ nhỏ: runbook 1 trang cho 3 sự cố dữ liệu nguy hiểm nhất (mất secret DB, hỏng PVC, khôi phục từ snapshot Ceph), và đào tạo tối thiểu 1 người dự phòng trước khi mở cho team khác.

**Bash-trong-YAML sẽ là gánh nặng tăng dần.** Orchestrator hiện ~180 dòng logic bash nhúng trong workflow — đang ở ngưỡng chấp nhận được và có comment tốt. Nhưng mỗi tính năng sắp tới (validate payload, notify kết quả về app repo, stage infra Terraform, kiểm tra image tồn tại) đều cộng vào đúng file này. Khuyến nghị: tách logic ra `platform-repo/scripts/*.sh` để test được bằng bats + shellcheck, workflow chỉ còn gọi script; định trước ngưỡng (vd >300 dòng hoặc >2 target) thì chuyển orchestrator thành CLI nhỏ có test thật.

**Lỗ hổng kiểm thử tự động.** Hiện chỉ có catalog-ci là kiểm thử tự động duy nhất toàn dự án. Ba bổ sung rẻ, thứ tự theo giá trị: actionlint + shellcheck cho workflow (bắt được cả lớp lỗi kiểu NUL-byte/YAML hỏng trước khi push); kubeconform cho manifest render ra trong catalog-ci và orchestrator; một smoke test sau sync staging (curl `/health` các route — danh sách route lấy được từ chính manifest). Sample app không có unit test nào — với vai trò template cho team khác, nó đang vô tình chuẩn hóa văn hóa "không test"; thêm 1 file test tối thiểu cho notes-app backend là đủ làm mẫu.

**Observability chưa có cả convention.** Chưa cần dựng stack giám sát ngay, nhưng nên chốt sớm 2 convention rẻ vì retrofit rất đắt: bộ label chuẩn `app.kubernetes.io/{name,instance,part-of}` tiêm qua patch template (hiện chỉ có label `env`, và chỉ trên Deployment), và quy ước log ra stdout dạng JSON. Có convention rồi thì lúc dựng Prometheus/Loki chỉ việc trỏ vào.

**Tài liệu nhiều bản thể.** md (nguồn chính) + docx + pptx chứa cùng nội dung tổng quan; docx/pptx sẽ lạc hậu trước. Đề xuất: coi md là chân lý, docx/pptx ghi rõ ngày snapshot, hoặc sinh tự động khi cần báo cáo.

---

## 5. Ưu tiên hành động (đề xuất, không kèm sửa đổi)

| # | Việc | Vì sao | Cỡ |
|---|---|---|---|
| 1 | Làm sạch NUL bytes trong 4 file workflow của 2 app repo | Chặn toàn bộ CI ngay bước đầu, triệu chứng khó đoán | phút |
| 2 | Thêm `concurrency` group theo app + assert `app == tên repo` trong orchestrator | Chống race ghi config repo; chặn giả mạo payload | giờ |
| 3 | Quyết định đường image cho EKS (replicate Harbor / registry cloud) + tạo `harbor-pull` phía cloud | Nhánh cloud hiện chắc chắn ImagePullBackOff | ngày (quyết định mạng là phần khó) |
| 4 | Tiêm default liveness/readiness probe qua patch template | Prod 3 replicas không gate sức khỏe | giờ |
| 5 | Tách `dbname` theo workload phía cloud, hoặc ghi rõ trade-off "chung DB" vào tài liệu | Semantics onprem/cloud đang lệch ngầm | giờ→ngày |
| 6 | Thêm filter `pathsExist: [cloud]` vào appset-cloud | Tránh Application lỗi vĩnh viễn cho app chưa lên cloud | phút |
| 7 | Tag `catalog/v1` ngay khi lập platform-repo thật; đổi 2 `platform.lock` khỏi `main` | Thói quen đúng từ app đầu tiên, khớp tài liệu | phút |
| 8 | Bỏ `.terraform.lock.hcl` khỏi .gitignore (commit lock file) | Nhất quán triết lý pinning | phút |
| 9 | ResourceQuota + NetworkPolicy chặn cross-namespace, trước khi onboard team 2 | Siết sau phải đàm phán với từng team | ngày |
| 10 | Sửa 2 chỗ doc drift (storageclass trong bootstrap; comment "ci.yaml" trong provisioner) | Tài liệu là tài sản chính của dự án — giữ nó đúng | phút |

Các mục 2–4 nằm gọn trong Giai đoạn C–D của KE-HOACH-TRIEN-KHAI mà không làm phình ước lượng đáng kể; mục 3 và 5 thuộc Giai đoạn 2 (cloud) nhưng cần quyết định sớm vì dính tới mạng và dữ liệu.

## 6. Kết luận

Dự án chọn đúng gần như mọi pattern lớn: rendered manifests thay vì render-lúc-sync, orchestrator tập trung credential thay vì rải quyền ra từng repo, catalog có phiên bản + canary theo app thay vì "sửa một phát lan cả org", build một lần promote bằng tag, secret không bao giờ chạm git. Phần lớn vấn đề tìm thấy là **khoảng trống ở rìa** (nhánh cloud chưa chạy được thật, thiếu probe/quota/netpol, vòng đời secret mới đi nửa đường) chứ không phải sai ở lõi — nghĩa là sửa được bằng cách đắp thêm, không phải đập đi. Với một người làm platform, đây là thiết kế tiết kiệm đúng chỗ: độ phức tạp dồn hết về platform-repo có lưới an toàn, còn giao diện của dev giữ được tối giản thật sự. Xử lý xong mục 1–2 là đủ điều kiện bắt đầu Giai đoạn 1 theo đúng kế hoạch đã viết.

---
*Review dựa trên trạng thái code ngày 16/07/2026. Các đường dẫn file trong review là tương đối so với thư mục `v2/`.*
