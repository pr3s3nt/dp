#!/usr/bin/env python3
"""
extract_cluster.py — trích xuất inventory + manifest (đã che nhạy cảm) từ MỘT cụm k8s.

Chạy 2 lần: một lần cho cụm cũ (1.19), một lần cho cụm mới (1.35). Rồi dùng
compare_clusters.py để biết còn phải migrate gì.

Ví dụ:
    # cụm cũ
    python extract_cluster.py \
        --kubeconfig ~/.kube/old-cluster.yaml \
        --label old \
        --output ./out \
        --redaction-config ./redaction.yaml

    # cụm mới (cần bỏ qua kiểm TLS)
    python extract_cluster.py \
        --kubeconfig ~/.kube/new-cluster.yaml \
        --label new \
        --insecure-skip-tls-verify \
        --output ./out \
        --redaction-config ./redaction.yaml

Đầu ra trong ./out/<label>/:
    inventory.json          báo cáo có cấu trúc (máy đọc)
    inventory.md            báo cáo dễ đọc
    manifests/<ns>/<kind>.<name>.yaml   manifest thô đã làm sạch + che
    manifests/_cluster/...  resource cấp cụm (Namespace, PV, ...)
    redaction-map.json      ánh xạ placeholder -> giá trị gốc (NHẠY CẢM, đừng chia sẻ)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib3
from collections import defaultdict
from typing import Any

import yaml

try:
    from kubernetes import client, config
    from kubernetes.dynamic import DynamicClient
except ImportError:
    sys.exit(
        "Thiếu thư viện. Cài: pip install 'kubernetes>=26' pyyaml\n"
        "(xem requirements.txt)"
    )

from redaction import Redactor


# Bộ kind mặc định — đủ để tái dựng app khi migrate. Dùng --all-kinds để lấy hết (kể cả CRD).
DEFAULT_KINDS = [
    "Namespace",
    "Deployment",
    "StatefulSet",
    "DaemonSet",
    "CronJob",
    "Job",
    "Service",
    "Ingress",
    "ConfigMap",
    "Secret",
    "PersistentVolumeClaim",
    "PersistentVolume",
    "ServiceAccount",
    "HorizontalPodAutoscaler",
    "Role",
    "RoleBinding",
    "NetworkPolicy",
    "ResourceQuota",
    "LimitRange",
]

# Namespace hệ thống — vẫn lấy (user yêu cầu), nhưng đánh dấu để báo cáo tách nhóm.
SYSTEM_NAMESPACES = {
    "kube-system", "kube-public", "kube-node-lease", "kube-flannel",
    "argocd", "traefik", "ingress-nginx", "cert-manager", "monitoring",
    "rook-ceph", "metallb-system", "local-path-storage",
}


# ---------------------------------------------------------------------------
# Kết nối cụm
# ---------------------------------------------------------------------------
def build_dynamic_client(kubeconfig: str, context: str | None, insecure: bool) -> DynamicClient:
    kubeconfig = os.path.expanduser(kubeconfig)
    if not os.path.isfile(kubeconfig):
        sys.exit(f"Không thấy kubeconfig: {kubeconfig}")

    cfg = client.Configuration()
    config.load_kube_config(config_file=kubeconfig, context=context, client_configuration=cfg)

    if insecure:
        cfg.verify_ssl = False
        cfg.ssl_ca_cert = None
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    api_client = client.ApiClient(cfg)
    return DynamicClient(api_client)


def discover_resources(dyn: DynamicClient, wanted_kinds: list[str] | None) -> list[Any]:
    """Trả về danh sách resource (ưu tiên version preferred), lọc theo kind mong muốn."""
    picked: dict[tuple[str, str], Any] = {}
    for res in dyn.resources.search():
        # Bỏ subresource (pods/status), và resource không list được.
        if "/" in getattr(res, "name", ""):
            continue
        if "list" not in (getattr(res, "verbs", None) or []):
            continue
        kind = getattr(res, "kind", None)
        if not kind:
            continue
        if wanted_kinds is not None and kind not in wanted_kinds:
            continue
        group = getattr(res, "group", "") or ""
        key = (group, kind)
        # Giữ bản preferred; nếu chưa có thì giữ tạm.
        if key not in picked or getattr(res, "preferred", False):
            picked[key] = res
    return list(picked.values())


# ---------------------------------------------------------------------------
# Làm sạch + tóm tắt
# ---------------------------------------------------------------------------
def clean_manifest(obj: dict[str, Any]) -> dict[str, Any]:
    """Giữ apiVersion/kind/metadata(name,namespace,labels,annotations)/spec/data/... bỏ runtime."""
    obj.pop("status", None)
    md = obj.get("metadata", {})
    for k in ("resourceVersion", "uid", "creationTimestamp", "generation",
              "managedFields", "selfLink", "ownerReferences", "finalizers"):
        md.pop(k, None)
    return obj


def _containers(spec: dict) -> list[dict]:
    tmpl = spec.get("template", {}).get("spec", {})
    if not tmpl:  # CronJob
        tmpl = (spec.get("jobTemplate", {}).get("spec", {})
                .get("template", {}).get("spec", {}))
    return (tmpl.get("containers", []) or []) + (tmpl.get("initContainers", []) or [])


def summarize(kind: str, obj: dict) -> dict:
    md = obj.get("metadata", {})
    spec = obj.get("spec", {}) or {}
    base = {"kind": kind, "name": md.get("name"), "namespace": md.get("namespace")}

    if kind in ("Deployment", "StatefulSet", "DaemonSet", "Job", "CronJob", "ReplicaSet"):
        conts = _containers(spec)
        base.update(
            replicas=spec.get("replicas"),
            images=[c.get("image") for c in conts],
            containers=[c.get("name") for c in conts],
            ports=[p for c in conts for p in (c.get("ports") or [])],
            env_keys=[e.get("name") for c in conts for e in (c.get("env") or [])],
            env_from=[list((ef.get("configMapRef") or ef.get("secretRef") or {}).values())
                      for c in conts for ef in (c.get("envFrom") or [])],
            volume_mounts=[vm.get("name") for c in conts for vm in (c.get("volumeMounts") or [])],
        )
    elif kind == "Service":
        base.update(type=spec.get("type"), cluster_ip=spec.get("clusterIP"),
                    ports=spec.get("ports"), selector=spec.get("selector"))
    elif kind == "Ingress":
        rules = spec.get("rules", []) or []
        base.update(
            hosts=[r.get("host") for r in rules],
            paths=[{"host": r.get("host"), "path": p.get("path"),
                    "backend": p.get("backend")}
                   for r in rules for p in (r.get("http", {}).get("paths", []) or [])],
            tls=[t.get("hosts") for t in (spec.get("tls", []) or [])],
        )
    elif kind == "ConfigMap":
        base.update(keys=sorted(list((obj.get("data") or {}).keys())))
    elif kind == "Secret":
        base.update(secret_type=obj.get("type"),
                    keys=sorted(list((obj.get("data") or {}).keys())))
    elif kind == "PersistentVolumeClaim":
        base.update(storage_class=spec.get("storageClassName"),
                    access_modes=spec.get("accessModes"),
                    size=spec.get("resources", {}).get("requests", {}).get("storage"))
    return base


# ---------------------------------------------------------------------------
# Ghi báo cáo Markdown
# ---------------------------------------------------------------------------
def write_markdown(path: str, label: str, inv: dict) -> None:
    L = []
    L.append(f"# Inventory cụm `{label}`\n")
    L.append(f"- Kubernetes: `{inv['cluster'].get('version', 'n/a')}`")
    L.append(f"- Số namespace: {len(inv['namespaces'])}")
    L.append(f"- Tổng resource trích xuất: {inv['totals']['resources']}\n")
    L.append("> Thông tin nhạy cảm và định danh công ty đã được che. "
             "Tra ngược placeholder ở `redaction-map.json` (không chia sẻ file này).\n")

    by_ns = inv["by_namespace"]
    for ns in sorted(by_ns):
        tag = " _(system)_" if ns in SYSTEM_NAMESPACES else ""
        items = by_ns[ns]
        L.append(f"\n## Namespace `{ns}`{tag}\n")

        workloads = [i for i in items if i["kind"] in
                     ("Deployment", "StatefulSet", "DaemonSet", "CronJob", "Job")]
        if workloads:
            L.append("| Kind | Tên | Replicas | Image |")
            L.append("|---|---|---|---|")
            for w in workloads:
                imgs = ", ".join(filter(None, w.get("images") or [])) or "-"
                L.append(f"| {w['kind']} | {w['name']} | {w.get('replicas', '-')} | {imgs} |")
            L.append("")

        svcs = [i for i in items if i["kind"] == "Service"]
        if svcs:
            L.append("| Service | Type | Ports |")
            L.append("|---|---|---|")
            for s in svcs:
                ports = ", ".join(str(p.get("port")) for p in (s.get("ports") or []))
                L.append(f"| {s['name']} | {s.get('type', '-')} | {ports} |")
            L.append("")

        ings = [i for i in items if i["kind"] == "Ingress"]
        if ings:
            L.append("| Ingress | Hosts | Paths |")
            L.append("|---|---|---|")
            for g in ings:
                hosts = ", ".join(filter(None, g.get("hosts") or [])) or "-"
                paths = ", ".join(p.get("path") or "/" for p in (g.get("paths") or []))
                L.append(f"| {g['name']} | {hosts} | {paths} |")
            L.append("")

        cms = [i for i in items if i["kind"] == "ConfigMap"]
        secs = [i for i in items if i["kind"] == "Secret"]
        pvcs = [i for i in items if i["kind"] == "PersistentVolumeClaim"]
        if cms:
            L.append("**ConfigMaps:** " + ", ".join(f"`{c['name']}`({len(c.get('keys', []))} keys)" for c in cms))
        if secs:
            L.append("\n**Secrets:** " + ", ".join(f"`{s['name']}`({s.get('secret_type', '')})" for s in secs))
        if pvcs:
            L.append("\n**PVCs:** " + ", ".join(
                f"`{p['name']}`({p.get('size', '?')},{p.get('storage_class', '?')})" for p in pvcs))
        L.append("")

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    ap = argparse.ArgumentParser(description="Trích xuất inventory + manifest đã che từ 1 cụm k8s.")
    ap.add_argument("--kubeconfig", required=True, help="Đường dẫn file kubeconfig của cụm.")
    ap.add_argument("--context", default=None, help="Context trong kubeconfig (mặc định: current-context).")
    ap.add_argument("--insecure-skip-tls-verify", action="store_true",
                    help="Bỏ qua kiểm chứng chỉ TLS (cần cho cụm mới).")
    ap.add_argument("--label", required=True, help="Nhãn cụm, vd: old / new.")
    ap.add_argument("--output", default="./out", help="Thư mục kết quả (mặc định ./out).")
    ap.add_argument("--redaction-config", default=None, help="File YAML khai báo định danh công ty cần che.")
    ap.add_argument("--no-redact", action="store_true", help="TẮT che (chỉ dùng nội bộ, KHÔNG chia sẻ output).")
    ap.add_argument("--all-kinds", action="store_true", help="Lấy MỌI kind kể cả CRD (mặc định chỉ bộ chuẩn).")
    ap.add_argument("--kinds", nargs="*", default=None, help="Chỉ định danh sách kind cần lấy.")
    ap.add_argument("--include-namespaces", nargs="*", default=None, help="Chỉ lấy các namespace này.")
    ap.add_argument("--exclude-namespaces", nargs="*", default=[], help="Bỏ qua các namespace này.")
    args = ap.parse_args()

    # Redactor.
    rconf = {}
    if args.redaction_config:
        with open(os.path.expanduser(args.redaction_config), encoding="utf-8") as f:
            rconf = yaml.safe_load(f) or {}
    redactor = None if args.no_redact else Redactor(rconf)

    # Kết nối.
    print(f"[{args.label}] Kết nối cụm ({'insecure' if args.insecure_skip_tls_verify else 'tls'})...")
    dyn = build_dynamic_client(args.kubeconfig, args.context, args.insecure_skip_tls_verify)

    # Phiên bản cụm.
    try:
        ver = client.VersionApi(dyn.client).get_code()
        cluster_version = f"{ver.major}.{ver.minor}".replace("+", "")
        git_version = ver.git_version
    except Exception:
        cluster_version, git_version = "unknown", "unknown"
    print(f"[{args.label}] Kubernetes {git_version}")

    wanted = None if args.all_kinds else (args.kinds or DEFAULT_KINDS)
    resources = discover_resources(dyn, wanted)
    print(f"[{args.label}] Phát hiện {len(resources)} loại resource, đang liệt kê...")

    out_dir = os.path.join(os.path.expanduser(args.output), args.label)
    man_dir = os.path.join(out_dir, "manifests")
    os.makedirs(man_dir, exist_ok=True)

    inv_items: list[dict] = []
    by_ns: dict[str, list] = defaultdict(list)
    namespaces: set[str] = set()
    total = 0

    for res in resources:
        kind = res.kind
        try:
            listing = res.get()
        except Exception as e:
            print(f"  [!] Bỏ qua {kind}: {e.__class__.__name__}")
            continue

        for item in getattr(listing, "items", []) or []:
            obj = item.to_dict()
            obj["apiVersion"] = getattr(res, "group_version", obj.get("apiVersion"))
            obj["kind"] = kind
            md = obj.get("metadata", {}) or {}
            ns = md.get("namespace")
            name = md.get("name")

            # Lọc namespace.
            if ns:
                namespaces.add(ns)
                if args.include_namespaces and ns not in args.include_namespaces:
                    continue
                if ns in args.exclude_namespaces:
                    continue

            obj = clean_manifest(obj)
            if redactor:
                obj = redactor.redact_manifest(obj, kind=kind)

            # Tóm tắt (sau che).
            summary = summarize(kind, obj)
            inv_items.append(summary)
            by_ns[ns or "_cluster"].append(summary)
            total += 1

            # Ghi manifest.
            sub = ns if ns else "_cluster"
            d = os.path.join(man_dir, sub)
            os.makedirs(d, exist_ok=True)
            fpath = os.path.join(d, f"{kind}.{name}.yaml")
            with open(fpath, "w", encoding="utf-8") as f:
                yaml.safe_dump(obj, f, sort_keys=False, allow_unicode=True, default_flow_style=False)

    inventory = {
        "cluster": {"label": args.label, "version": cluster_version, "git_version": git_version},
        "namespaces": sorted(namespaces),
        "system_namespaces": sorted(namespaces & SYSTEM_NAMESPACES),
        "totals": {"resources": total, "namespaces": len(namespaces)},
        "items": inv_items,
        "by_namespace": {k: v for k, v in sorted(by_ns.items())},
    }

    with open(os.path.join(out_dir, "inventory.json"), "w", encoding="utf-8") as f:
        json.dump(inventory, f, indent=2, ensure_ascii=False)
    write_markdown(os.path.join(out_dir, "inventory.md"), args.label, inventory)

    if redactor:
        with open(os.path.join(out_dir, "redaction-map.json"), "w", encoding="utf-8") as f:
            json.dump(redactor.dump_map(), f, indent=2, ensure_ascii=False)

    print(f"[{args.label}] Xong: {total} resource / {len(namespaces)} namespace -> {out_dir}")
    if redactor:
        print(f"[{args.label}] Ánh xạ che: redaction-map.json (NHẠY CẢM — không commit/chia sẻ).")


if __name__ == "__main__":
    main()
