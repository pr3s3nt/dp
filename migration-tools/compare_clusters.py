#!/usr/bin/env python3
"""
compare_clusters.py — so sánh inventory 2 cụm để biết CÒN PHẢI MIGRATE GÌ.

Đọc out/<old>/inventory.json và out/<new>/inventory.json, xuất:
  - namespace có ở cụm cũ nhưng chưa có ở cụm mới
  - workload (Deployment/StatefulSet/...) chưa tồn tại ở cụm mới
  - workload có ở cả hai nhưng khác image (đã cài tay, có thể lệch phiên bản)
  - thống kê tổng quan

Ví dụ:
    python compare_clusters.py --old ./out/old/inventory.json \
                               --new ./out/new/inventory.json \
                               --output ./out/migration-gap.md
"""

from __future__ import annotations

import argparse
import json
import os


WORKLOAD_KINDS = {"Deployment", "StatefulSet", "DaemonSet", "CronJob", "Job"}


def load(path: str) -> dict:
    with open(os.path.expanduser(path), encoding="utf-8") as f:
        return json.load(f)


def index_workloads(inv: dict) -> dict[tuple[str, str, str], dict]:
    """(namespace, kind, name) -> summary."""
    out = {}
    for it in inv["items"]:
        if it["kind"] in WORKLOAD_KINDS:
            out[(it.get("namespace"), it["kind"], it["name"])] = it
    return out


def img_set(summary: dict) -> set[str]:
    # Bỏ tag để so sánh "cùng app" bất kể phiên bản; giữ full để hiện chi tiết.
    return {i for i in (summary.get("images") or []) if i}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True, help="inventory.json cụm cũ.")
    ap.add_argument("--new", required=True, help="inventory.json cụm mới.")
    ap.add_argument("--output", default="./out/migration-gap.md")
    args = ap.parse_args()

    old, new = load(args.old), load(args.new)
    ow, nw = index_workloads(old), index_workloads(new)

    old_ns = set(old["namespaces"])
    new_ns = set(new["namespaces"])
    ns_missing = sorted(old_ns - new_ns)

    only_old, in_both_diff, in_both_same = [], [], []
    for key, o in sorted(ow.items()):
        n = nw.get(key)
        if n is None:
            only_old.append(o)
        elif img_set(o) != img_set(n):
            in_both_diff.append((o, n))
        else:
            in_both_same.append(o)

    L = []
    L.append("# Khoảng cách migrate: cụm cũ → cụm mới\n")
    L.append(f"- Cụm cũ: `{old['cluster'].get('git_version')}` — {len(ow)} workload / {len(old_ns)} ns")
    L.append(f"- Cụm mới: `{new['cluster'].get('git_version')}` — {len(nw)} workload / {len(new_ns)} ns\n")
    L.append(f"**Tóm tắt:** {len(only_old)} workload CHƯA có trên cụm mới · "
             f"{len(in_both_diff)} workload có nhưng KHÁC image · "
             f"{len(in_both_same)} workload đã khớp.\n")

    if ns_missing:
        L.append("## Namespace chưa có trên cụm mới\n")
        for ns in ns_missing:
            L.append(f"- `{ns}`")
        L.append("")

    L.append("## Workload cần migrate (chỉ có ở cụm cũ)\n")
    if only_old:
        L.append("| Namespace | Kind | Tên | Image |")
        L.append("|---|---|---|---|")
        for o in only_old:
            imgs = ", ".join(sorted(img_set(o))) or "-"
            L.append(f"| {o.get('namespace')} | {o['kind']} | {o['name']} | {imgs} |")
    else:
        L.append("_Không có — mọi workload cụm cũ đều đã tồn tại trên cụm mới._")
    L.append("")

    L.append("## Workload có ở cả hai nhưng KHÁC image (kiểm tra lệch phiên bản)\n")
    if in_both_diff:
        L.append("| Namespace | Kind | Tên | Image cũ | Image mới |")
        L.append("|---|---|---|---|---|")
        for o, n in in_both_diff:
            L.append(f"| {o.get('namespace')} | {o['kind']} | {o['name']} | "
                     f"{', '.join(sorted(img_set(o))) or '-'} | {', '.join(sorted(img_set(n))) or '-'} |")
    else:
        L.append("_Không có._")
    L.append("")

    L.append("## Workload đã khớp (đã migrate xong)\n")
    if in_both_same:
        for o in in_both_same:
            L.append(f"- `{o.get('namespace')}/{o['name']}` ({o['kind']})")
    else:
        L.append("_Chưa có workload nào khớp._")
    L.append("")

    os.makedirs(os.path.dirname(os.path.abspath(os.path.expanduser(args.output))), exist_ok=True)
    with open(os.path.expanduser(args.output), "w", encoding="utf-8") as f:
        f.write("\n".join(L))

    # Bản JSON cho máy đọc.
    gap = {
        "namespaces_missing_on_new": ns_missing,
        "workloads_to_migrate": only_old,
        "workloads_image_mismatch": [{"old": o, "new": n} for o, n in in_both_diff],
        "workloads_matched": in_both_same,
    }
    with open(os.path.expanduser(args.output).replace(".md", ".json"), "w", encoding="utf-8") as f:
        json.dump(gap, f, indent=2, ensure_ascii=False)

    print(f"So sánh xong -> {args.output}")
    print(f"  Chưa migrate: {len(only_old)} · Khác image: {len(in_both_diff)} · Khớp: {len(in_both_same)}")


if __name__ == "__main__":
    main()
