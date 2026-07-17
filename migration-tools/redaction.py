"""
redaction.py — che thông tin nhạy cảm trước khi ghi inventory / manifest ra đĩa.

Ba lớp che:
  1. Secret values      : mọi .data / .stringData của kind Secret  -> <REDACTED:secret>
  2. Sensitive env/config: env var / configmap key trông giống mật khẩu/token -> <REDACTED:env>
  3. Company identifiers : domain, registry host, email, IP, tên cụm... -> placeholder ổn định

Nguyên tắc: che nhưng GIỮ CẤU TRÚC. Cùng một giá trị nhạy cảm luôn ánh xạ về cùng một
placeholder (vd harbor.acme.local -> REGISTRY_HOST_1) nên các tham chiếu chéo giữa manifest
vẫn khớp nhau — vẫn migrate/đối chiếu được, nhưng người ngoài không suy ra được công ty nào.

Bản đồ ánh xạ (placeholder -> giá trị gốc) được ghi ra file riêng `redaction-map.json`
để BẠN tự tra ngược khi cần; file này KHÔNG được commit / chia sẻ (đã cho vào .gitignore).
"""

from __future__ import annotations

import base64
import ipaddress
import re
from typing import Any


# ---------------------------------------------------------------------------
# Cấu hình mặc định
# ---------------------------------------------------------------------------

# Tên key gợi ý dữ liệu nhạy cảm (env var, configmap key, annotation...).
SENSITIVE_KEY_RE = re.compile(
    r"(pass|passwd|password|secret|token|api[_-]?key|apikey|access[_-]?key|"
    r"private[_-]?key|credential|cred|pwd|pin|auth|dsn|conn(ection)?[_-]?str|"
    r"database[_-]?url|db[_-]?url|jwt|session|salt|signature|otp|"
    r"aws[_-]?secret|client[_-]?secret|encryption)",
    re.IGNORECASE,
)

# Metadata runtime nên bỏ hẳn khi làm sạch manifest.
STRIP_METADATA_KEYS = {
    "creationTimestamp",
    "resourceVersion",
    "uid",
    "generation",
    "managedFields",
    "selfLink",
    "ownerReferences",
    "finalizers",
}

# Annotation cần bỏ hẳn (chứa bản sao spec đầy đủ -> có thể lộ secret cũ).
STRIP_ANNOTATIONS = {
    "kubectl.kubernetes.io/last-applied-configuration",
    "deployment.kubernetes.io/revision",
}

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}")
# Domain kiểu foo.bar.tld (>=2 nhãn, tld chữ). Tránh match version như 1.2.3.
DOMAIN_RE = re.compile(
    r"\b(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+"
    r"(?:local|internal|corp|lan|svc|cluster|[a-zA-Z]{2,24})\b"
)
IPV4_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")


class Redactor:
    """Che nhất quán, có nhớ ánh xạ để tra ngược."""

    def __init__(self, config: dict[str, Any] | None = None):
        config = config or {}
        # Danh sách token định danh công ty người dùng khai (thay TRƯỚC, ưu tiên cao nhất).
        # Mỗi mục: {"match": "acme", "placeholder": "COMPANY"} hoặc chỉ chuỗi.
        self.company_terms: list[tuple[str, str]] = []
        for i, item in enumerate(config.get("company_identifiers", []), start=1):
            if isinstance(item, dict):
                self.company_terms.append((item["match"], item.get("placeholder", f"COMPANY_{i}")))
            else:
                self.company_terms.append((str(item), f"COMPANY_{i}"))
        # Sắp xếp match dài trước để tránh thay từng phần.
        self.company_terms.sort(key=lambda t: len(t[0]), reverse=True)

        # CIDR nội bộ người dùng khai -> che IP thuộc dải này (mặc định che private ranges).
        self.private_only = config.get("redact_private_ip_only", True)
        self.extra_cidrs = [ipaddress.ip_network(c, strict=False) for c in config.get("internal_cidrs", [])]

        # Bật/tắt từng lớp.
        self.redact_domains = config.get("redact_domains", True)
        self.redact_emails = config.get("redact_emails", True)
        self.redact_ips = config.get("redact_ips", True)
        self.redact_env = config.get("redact_sensitive_env", True)

        # Domain "công cộng" không cần che (không lộ danh tính công ty).
        self.domain_allowlist = set(
            config.get(
                "domain_allowlist",
                [
                    "cluster.local",
                    "svc.cluster.local",
                    "kubernetes.default.svc",
                    "docker.io",
                    "quay.io",
                    "gcr.io",
                    "registry.k8s.io",
                    "k8s.gcr.io",
                    "ghcr.io",
                    "amazonaws.com",
                ],
            )
        )

        # Ánh xạ giá trị gốc -> placeholder (để nhất quán + tra ngược).
        self.mapping: dict[str, str] = {}
        self._counters: dict[str, int] = {}

    # ------------------------------------------------------------------ helpers
    def _placeholder(self, kind: str, original: str) -> str:
        if original in self.mapping:
            return self.mapping[original]
        self._counters[kind] = self._counters.get(kind, 0) + 1
        ph = f"<{kind}_{self._counters[kind]}>"
        self.mapping[original] = ph
        return ph

    def _ip_is_sensitive(self, ip_str: str) -> bool:
        try:
            ip = ipaddress.ip_address(ip_str)
        except ValueError:
            return False
        if any(ip in c for c in self.extra_cidrs):
            return True
        if self.private_only:
            return ip.is_private and not ip.is_loopback and not ip.is_unspecified
        return not ip.is_loopback and not ip.is_unspecified

    # ------------------------------------------------------------------ string
    def redact_string(self, s: str) -> str:
        if not isinstance(s, str) or not s:
            return s

        # 1. Company terms khai tay (ưu tiên cao nhất).
        for term, ph in self.company_terms:
            if term and term in s:
                self.mapping[term] = f"<{ph}>"
                s = s.replace(term, f"<{ph}>")

        # 2. Email.
        if self.redact_emails:
            s = EMAIL_RE.sub(lambda m: self._placeholder("EMAIL", m.group(0)), s)

        # 3. Domain (bỏ qua allowlist).
        if self.redact_domains:
            def _dom(m):
                d = m.group(0)
                dl = d.lower()
                if dl in self.domain_allowlist or any(dl.endswith("." + a) or dl == a for a in self.domain_allowlist):
                    return d
                return self._placeholder("DOMAIN", d)

            s = DOMAIN_RE.sub(_dom, s)

        # 4. IP.
        if self.redact_ips:
            def _ip(m):
                ip = m.group(0)
                return self._placeholder("IP", ip) if self._ip_is_sensitive(ip) else ip

            s = IPV4_RE.sub(_ip, s)

        return s

    # ------------------------------------------------------------------ objects
    def redact_manifest(self, obj: Any, kind: str | None = None, _key: str | None = None) -> Any:
        """Đệ quy che một manifest (dict/list/scalar). `kind` là kind của resource gốc."""
        if isinstance(obj, dict):
            out: dict[str, Any] = {}
            for k, v in obj.items():
                # Bỏ metadata runtime.
                if k in STRIP_METADATA_KEYS:
                    continue
                if k == "annotations" and isinstance(v, dict):
                    v = {ak: av for ak, av in v.items() if ak not in STRIP_ANNOTATIONS}
                if k == "status":  # bỏ status runtime cho gọn manifest
                    continue

                # Secret data: che toàn bộ value.
                if kind == "Secret" and k in ("data", "stringData") and isinstance(v, dict):
                    out[k] = {dk: "<REDACTED:secret>" for dk in v}
                    continue

                # Env var value nhạy cảm (theo tên).
                if self.redact_env and k in ("value",) and isinstance(_key, str) and SENSITIVE_KEY_RE.search(_key):
                    out[k] = "<REDACTED:env>"
                    continue

                out[k] = self.redact_manifest(v, kind=kind, _key=k)
            # Env var dạng {name, value}: nếu name nhạy cảm mà value chưa che ở trên.
            if (
                self.redact_env
                and "name" in out
                and "value" in out
                and isinstance(out.get("name"), str)
                and SENSITIVE_KEY_RE.search(out["name"])
                and isinstance(out["value"], str)
                and not out["value"].startswith("<REDACTED")
            ):
                out["value"] = "<REDACTED:env>"
            return out

        if isinstance(obj, list):
            return [self.redact_manifest(v, kind=kind, _key=_key) for v in obj]

        if isinstance(obj, str):
            # ConfigMap value nhạy cảm theo tên key.
            if self.redact_env and isinstance(_key, str) and SENSITIVE_KEY_RE.search(_key) and _key not in ("name",):
                return "<REDACTED:env>"
            return self.redact_string(obj)

        return obj

    # ------------------------------------------------------------------ export
    def dump_map(self) -> dict[str, str]:
        """placeholder -> giá trị gốc (đảo ngược mapping) để tra cứu offline."""
        return {v: k for k, v in self.mapping.items()}


def try_b64_decode(v: str) -> str | None:
    """Giải base64 nếu hợp lệ (dùng để soi tên field của Secret, không lộ value)."""
    try:
        raw = base64.b64decode(v, validate=True)
        return raw.decode("utf-8")
    except Exception:
        return None
