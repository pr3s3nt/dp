# migration-tools — trích xuất & so sánh 2 cụm k8s để migrate lên IDP v2

Bộ script Python trích xuất inventory + manifest (đã che nhạy cảm) từ **cụm cũ (1.19)** và
**cụm mới (1.35)**, rồi so sánh để biết còn phải migrate app nào lên platform v2
(Score → score-k8s → config repo → ArgoCD).

```
migration-tools/
├── extract_cluster.py       # trích xuất 1 cụm  (chạy 2 lần: old & new)
├── compare_clusters.py      # so sánh 2 inventory -> khoảng cách migrate
├── redaction.py             # module che nhạy cảm + định danh công ty
├── redaction.example.yaml   # mẫu khai báo -> copy thành redaction.yaml
├── run_all.sh               # chạy cả 3 bước một phát
├── requirements.txt
└── out/                     # kết quả (đã gitignore)
```

## Cài đặt

```bash
cd migration-tools
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

> Dùng **dynamic client** để tự khám phá API của từng cụm, nên chịu được lệch phiên bản
> giữa 1.19 và 1.35 (Ingress v1beta1 vs v1, CronJob batch/v1beta1 vs v1... đều đọc được).

## Dùng nhanh

```bash
cp redaction.example.yaml redaction.yaml   # điền domain/registry/tên công ty thật của bạn

# sửa đường dẫn kubeconfig trong run_all.sh (hoặc export biến môi trường) rồi:
OLD_KUBECONFIG=~/.kube/old.yaml NEW_KUBECONFIG=~/.kube/new.yaml ./run_all.sh
```

Hoặc chạy từng bước:

```bash
# Cụm cũ
python extract_cluster.py --kubeconfig ~/.kube/old.yaml --label old \
    --output ./out --redaction-config ./redaction.yaml

# Cụm mới — CẦN bỏ qua kiểm TLS
python extract_cluster.py --kubeconfig ~/.kube/new.yaml --label new \
    --insecure-skip-tls-verify --output ./out --redaction-config ./redaction.yaml

# So sánh
python compare_clusters.py --old ./out/old/inventory.json \
    --new ./out/new/inventory.json --output ./out/migration-gap.md
```

## Tham số `extract_cluster.py`

| Cờ | Ý nghĩa |
|---|---|
| `--kubeconfig PATH` | (bắt buộc) đường dẫn kubeconfig của cụm |
| `--context NAME` | context cụ thể trong kubeconfig (mặc định current-context) |
| `--insecure-skip-tls-verify` | bỏ kiểm chứng chỉ TLS — **dùng cho cụm mới** |
| `--label old\|new` | (bắt buộc) nhãn cụm, quyết định thư mục output |
| `--output DIR` | thư mục kết quả (mặc định `./out`) |
| `--redaction-config FILE` | file YAML khai định danh công ty cần che |
| `--no-redact` | tắt che (chỉ dùng nội bộ, **đừng** chia sẻ output) |
| `--all-kinds` | lấy MỌI kind kể cả CRD (mặc định chỉ bộ chuẩn) |
| `--kinds A B C` | chỉ lấy các kind chỉ định |
| `--include-namespaces ...` / `--exclude-namespaces ...` | lọc namespace |

Mặc định lấy toàn bộ namespace (kể cả hệ thống); báo cáo tự đánh dấu `(system)`.

## Kết quả

```
out/
├── old/
│   ├── inventory.json          # có cấu trúc, máy đọc
│   ├── inventory.md            # dễ đọc, chia theo namespace
│   ├── manifests/<ns>/<Kind>.<name>.yaml   # manifest đã làm sạch + che
│   ├── manifests/_cluster/...  # resource cấp cụm
│   └── redaction-map.json      # placeholder -> giá trị gốc  (NHẠY CẢM)
├── new/  (tương tự)
├── migration-gap.md            # workload chưa migrate / khác image / đã khớp
└── migration-gap.json
```

## Che thông tin nhạy cảm

Ba lớp, đều **giữ cấu trúc** để vẫn đối chiếu/migrate được:

1. **Secret** — mọi `data`/`stringData` → `<REDACTED:secret>` (giữ tên key để biết cần secret gì).
2. **Env/ConfigMap nhạy cảm** — key trông giống `password/token/secret/api_key/...` → `<REDACTED:env>`.
3. **Định danh công ty** — domain, email, IP nội bộ, registry host, tên công ty (khai ở `redaction.yaml`)
   → placeholder ổn định (`<COMPANY>`, `<REGISTRY>`, `<DOMAIN_1>`, `<IP_1>`...). Cùng một giá trị luôn
   ra cùng placeholder nên tham chiếu chéo giữa các manifest vẫn khớp.

Đồng thời tự bỏ metadata runtime (`resourceVersion`, `uid`, `managedFields`, `status`,
`last-applied-configuration`...) để manifest sạch, dễ tái dùng.

> ⚠️ `redaction-map.json` chứa ánh xạ ngược ra giá trị thật — đã cho vào `.gitignore`,
> **không commit / không chia sẻ**. Nếu cần đưa output ra ngoài, chỉ đưa `inventory.md`
> và thư mục `manifests/`.

## Từ inventory → score.yaml (bước migrate tiếp theo, gợi ý)

`inventory.json` đã gom sẵn đúng thứ platform cần cho `score.yaml`:

| Trong cụm cũ | → Score resource |
|---|---|
| Deployment/StatefulSet + Service | `containers` + `service` |
| Ingress (host/path) | `type: route` |
| Service gọi Service nội bộ | `type: service` |
| StatefulSet postgres + PVC + Secret `*-db-credentials` | `type: postgres` |

Xem `migration-gap.md` để biết app nào **chưa** có trên cụm mới, ưu tiên viết `score.yaml`
cho các app đó trước, rồi đẩy qua orchestrator như README gốc mô tả. (Nếu muốn, mình có thể
bổ sung `scaffold_score.py` tự sinh nháp `score.yaml` từ `inventory.json`.)
```
