#!/usr/bin/env python3
"""知识体系审计引擎（Phase B PR-1）。

6 子命令的结构性漂移检测：
  - links              Markdown 内部 broken link
  - archived-refs      对 docs/research/* (status:archived) 的活跃硬引用
  - orphans            docs/**/*.md 在全仓零引用
  - home-path-refs     仓库内对 ~/.claude/ 私有路径的硬编码
  - rule-pointer-sync  .claude/rules/*.md → docs/principles/*.md 映射
  - rule-usage         F-NNN 规则外部引用计数（dead rule 候选）

详见 Scripts/audit/README.md 与 Scripts/audit/policy.yaml。

用法：
    python3 Scripts/audit/docaudit.py <check> [--strict] [--report] [--baseline]
    python3 Scripts/audit/docaudit.py --all [--strict] [--report] [--baseline]

退出码：0 通过 / 1 error 级命中 / 2 配置错误。
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Iterable

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip3 install pyyaml", file=sys.stderr)
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parents[2]
POLICY_PATH = Path(__file__).resolve().parent / "policy.yaml"
CHECK_NAMES = [
    "links",
    "archived-refs",
    "orphans",
    "home-path-refs",
    "rule-pointer-sync",
    "rule-usage",
]

# Markdown 内部链接正则 — [text](path.md) 或 [text](path.md#anchor)
# 排除 http/https/mailto 开头 + 纯锚点 (#xxx) + 图片 ![]
LINK_RE = re.compile(
    r"(?<!\!)\[[^\]]*\]\(([^)#]*?\.md)(?:#[^)]*)?\)"
)

# 任意 md 文件路径引用 — 用于 orphan 检测（含 code 内联 `path/to/file.md`）
PATH_REF_RE = re.compile(r"([A-Za-z_\-./][A-Za-z0-9_\-./]*\.md)")

# ~/.claude/ 引用
HOME_CLAUDE_RE = re.compile(r"~/\.claude/[A-Za-z0-9_\-./]*")

# .claude/rules/ → docs/principles/ 映射模式
RULE_POINTER_RE = re.compile(
    r"(?:Read and follow|指向|→)\s+(docs/principles/[A-Za-z0-9_\-./]+\.md)"
)

# F-NNN 规则 ID
F_RULE_RE = re.compile(r"\bF-(\d{3})\b")


# ---------- 数据类型 ----------

@dataclass
class Finding:
    check: str
    path: str          # 相对于 REPO_ROOT
    line: int          # 1-based；0 表示文件级
    category: str
    level: str         # error / warning / info
    suggestion: str = ""
    matched_text: str = ""

    def as_tsv(self) -> str:
        # 用 tab 分隔，替换可能出现在字段里的 tab/newline
        fields = [
            self.check,
            self.path,
            str(self.line),
            self.category,
            self.level,
            self.suggestion,
            self.matched_text.replace("\t", " ").replace("\n", " ")[:200],
        ]
        return "\t".join(fields)


@dataclass
class CheckResult:
    check: str
    level: str         # 本次检查默认级别（policy）
    findings: list[Finding] = field(default_factory=list)
    skipped: bool = False
    skip_reason: str = ""

    @property
    def error_count(self) -> int:
        return sum(1 for f in self.findings if f.level == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for f in self.findings if f.level == "warning")

    @property
    def info_count(self) -> int:
        return sum(1 for f in self.findings if f.level == "info")


# ---------- policy 加载 ----------

def load_policy(path: Path = POLICY_PATH) -> dict:
    if not path.exists():
        print(f"ERROR: policy.yaml not found at {path}", file=sys.stderr)
        sys.exit(2)
    try:
        with path.open("r", encoding="utf-8") as fp:
            policy = yaml.safe_load(fp)
    except yaml.YAMLError as exc:
        print(f"ERROR: policy.yaml parse failed: {exc}", file=sys.stderr)
        sys.exit(2)
    if not isinstance(policy, dict) or policy.get("version") != 1:
        print("ERROR: policy.yaml version must be 1", file=sys.stderr)
        sys.exit(2)
    return policy


def _baseline_active(policy: dict, check_name: str, baseline_flag: bool) -> bool:
    """返回该 check 是否应启用 legacy_whitelist 豁免。"""
    if not baseline_flag:
        return False
    lw = policy.get("legacy_whitelist", {}).get(check_name, {})
    if not lw.get("baseline_accepted"):
        return False
    accepted_until = lw.get("accepted_until")
    if accepted_until:
        try:
            y, m, d = map(int, accepted_until.split("-"))
            if date.today() > date(y, m, d):
                return False  # 过期自动转严格
        except (ValueError, AttributeError):
            pass
    return True


# ---------- 文件扫描辅助 ----------

def _iter_text_files(policy: dict, extensions: Iterable[str] = (".md", ".sh", ".py", ".yaml", ".yml")) -> Iterable[Path]:
    """遍历 policy scan.include 中的文本文件，排除 scan.exclude。"""
    scan = policy.get("scan", {})
    includes = scan.get("include", [])
    excludes = scan.get("exclude", [])

    for inc in includes:
        inc_path = REPO_ROOT / inc
        if inc_path.is_file():
            yield inc_path
            continue
        if not inc_path.is_dir():
            continue
        for root, dirs, files in os.walk(inc_path):
            # 排除目录
            root_path = Path(root)
            rel = root_path.relative_to(REPO_ROOT)
            if any(_matches_exclude(rel, ex) for ex in excludes):
                dirs[:] = []
                continue
            for fn in files:
                if not any(fn.endswith(ext) for ext in extensions):
                    continue
                full = root_path / fn
                rel_full = full.relative_to(REPO_ROOT)
                if any(_matches_exclude(rel_full, ex) for ex in excludes):
                    continue
                yield full


def _matches_exclude(rel_path: Path, pattern: str) -> bool:
    """简单的 glob-like 匹配，支持末尾 /，以及 ** 前缀子树。"""
    p = pattern.rstrip("/")
    rel_str = str(rel_path).replace(os.sep, "/")
    if p.endswith("/**"):
        base = p[:-3].rstrip("/")
        return rel_str == base or rel_str.startswith(base + "/")
    if "*" not in p:
        return rel_str == p or rel_str.startswith(p + "/")
    # 回落到 fnmatch
    import fnmatch
    return fnmatch.fnmatch(rel_str, p)


def _matches_whitelist(rel_path: str, patterns: Iterable[str]) -> bool:
    for pat in patterns or ():
        p = pat.rstrip("/")
        rel_norm = rel_path.replace(os.sep, "/")
        if p.endswith("/**"):
            base = p[:-3].rstrip("/")
            if rel_norm == base or rel_norm.startswith(base + "/"):
                return True
        elif p == rel_norm:
            return True
        else:
            import fnmatch
            if fnmatch.fnmatch(rel_norm, p):
                return True
    return False


def _read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []


# ---------- check: links ----------

def check_links(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["links"]
    level = conf["level"]
    result = CheckResult(check="links", level=level)

    for path in _iter_text_files(policy, extensions=(".md",)):
        lines = _read_lines(path)
        for lineno, line in enumerate(lines, start=1):
            for match in LINK_RE.finditer(line):
                target = match.group(1).strip()
                if not target or target.startswith(("http://", "https://", "mailto:")):
                    continue
                # 解析为绝对路径
                if target.startswith("/"):
                    abs_target = REPO_ROOT / target.lstrip("/")
                else:
                    abs_target = (path.parent / target).resolve()
                if abs_target.exists():
                    continue
                rel = path.relative_to(REPO_ROOT)
                result.findings.append(Finding(
                    check="links",
                    path=str(rel),
                    line=lineno,
                    category="broken_link",
                    level=level,
                    suggestion=f"target does not exist: {target}",
                    matched_text=line.strip(),
                ))
    return result


# ---------- check: archived-refs ----------

def check_archived_refs(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["archived-refs"]
    level = conf["level"]
    archived = conf.get("archived_sources", [])
    result = CheckResult(check="archived-refs", level=level)

    if _baseline_active(policy, "archived-refs", baseline):
        result.skipped = True
        result.skip_reason = "baseline_whitelist_active"
        return result

    # 构造每个 archived 源的 basename 与 full-path 两种匹配模式
    patterns = []
    for src in archived:
        patterns.append((src, re.escape(src)))
        bn = Path(src).name
        patterns.append((src, re.escape(bn)))

    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        rel = path.relative_to(REPO_ROOT)
        rel_str = str(rel)
        # 跳过 archived 文件本身
        if rel_str in archived:
            continue
        lines = _read_lines(path)
        for lineno, line in enumerate(lines, start=1):
            for src, pat in patterns:
                if re.search(pat, line):
                    result.findings.append(Finding(
                        check="archived-refs",
                        path=rel_str,
                        line=lineno,
                        category="active_reference",
                        level=level,
                        suggestion=f"migrate reference to docs/archive/ or change to historical note: {src}",
                        matched_text=line.strip(),
                    ))
                    break  # 每行只报一次
    return result


# ---------- check: orphans ----------

def check_orphans(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["orphans"]
    level = conf["level"]
    whitelist = conf.get("whitelist", [])
    result = CheckResult(check="orphans", level=level)

    if _baseline_active(policy, "orphans", baseline):
        result.skipped = True
        result.skip_reason = "baseline_whitelist_active"
        return result

    # 所有 docs/**.md
    docs_mds: list[Path] = []
    docs_root = REPO_ROOT / "docs"
    if docs_root.is_dir():
        for root, dirs, files in os.walk(docs_root):
            for fn in files:
                if fn.endswith(".md"):
                    docs_mds.append(Path(root) / fn)

    # 全仓引用池
    referenced: set[str] = set()
    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        text = "\n".join(_read_lines(path))
        for match in PATH_REF_RE.finditer(text):
            ref = match.group(1)
            # 归一化：去掉 ./ 前缀
            if ref.startswith("./"):
                ref = ref[2:]
            referenced.add(ref)
            # 也记 basename 以处理 `handoff.md` 这种短引用
            referenced.add(Path(ref).name)

    for md in docs_mds:
        rel = md.relative_to(REPO_ROOT)
        rel_str = str(rel)
        if _matches_whitelist(rel_str, whitelist):
            continue
        name = md.name
        full_rel = rel_str
        if full_rel in referenced or name in referenced:
            continue
        # 也检查 docs/ 内部相对路径（去掉 docs/ 前缀）
        if rel_str.startswith("docs/") and rel_str[len("docs/"):] in referenced:
            continue
        result.findings.append(Finding(
            check="orphans",
            path=rel_str,
            line=0,
            category="unreferenced",
            level=level,
            suggestion="no reference found in repo; consider adding index entry or archive",
        ))
    return result


# ---------- check: home-path-refs ----------

def check_home_path_refs(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["home-path-refs"]
    level = conf["level"]
    allowed = conf.get("allowed_contexts", [])
    result = CheckResult(check="home-path-refs", level=level)

    if _baseline_active(policy, "home-path-refs", baseline):
        result.skipped = True
        result.skip_reason = "baseline_whitelist_active"
        return result

    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        rel = path.relative_to(REPO_ROOT)
        rel_str = str(rel)
        if _matches_whitelist(rel_str, allowed):
            continue
        lines = _read_lines(path)
        for lineno, line in enumerate(lines, start=1):
            for match in HOME_CLAUDE_RE.finditer(line):
                result.findings.append(Finding(
                    check="home-path-refs",
                    path=rel_str,
                    line=lineno,
                    category="private_path_hardcoded",
                    level=level,
                    suggestion="migrate knowledge to docs/ or mark as Claude-private with context",
                    matched_text=match.group(0),
                ))
    return result


# ---------- check: rule-pointer-sync ----------

def check_rule_pointer_sync(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["rule-pointer-sync"]
    level = conf["level"]
    allowlist = conf.get("allowlist_rules", [])
    result = CheckResult(check="rule-pointer-sync", level=level)

    rules_dir = REPO_ROOT / ".claude" / "rules"
    if not rules_dir.is_dir():
        return result

    for rule_path in rules_dir.glob("*.md"):
        rel = rule_path.relative_to(REPO_ROOT)
        rel_str = str(rel)
        if _matches_whitelist(rel_str, allowlist):
            continue
        text = "\n".join(_read_lines(rule_path))
        matches = list(RULE_POINTER_RE.finditer(text))
        if not matches:
            # 规则文件未声明指向 principle
            result.findings.append(Finding(
                check="rule-pointer-sync",
                path=rel_str,
                line=0,
                category="missing_pointer",
                level=level,
                suggestion="rule must point to a docs/principles/*.md SSOT",
            ))
            continue
        for match in matches:
            target = match.group(1).strip()
            abs_target = REPO_ROOT / target
            if not abs_target.exists():
                # 计算 line number
                lineno = text[:match.start()].count("\n") + 1
                result.findings.append(Finding(
                    check="rule-pointer-sync",
                    path=rel_str,
                    line=lineno,
                    category="broken_pointer",
                    level=level,
                    suggestion=f"principle target missing: {target}",
                    matched_text=match.group(0),
                ))
    return result


# ---------- check: rule-usage ----------

def check_rule_usage(policy: dict, baseline: bool) -> CheckResult:
    conf = policy["checks"]["rule-usage"]
    level = conf["level"]
    min_refs = conf.get("min_references", 1)
    result = CheckResult(check="rule-usage", level=level)

    feedback = REPO_ROOT / "docs" / "memory" / "feedback.md"
    if not feedback.is_file():
        return result
    fb_text = feedback.read_text(encoding="utf-8")
    # 提取声明的 F-NNN 规则 ID
    declared = set()
    # 只认 feedback.md 中形如 `## F-NNN` 或 `### F-NNN` 的声明行
    for line in fb_text.splitlines():
        m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
        if m:
            declared.add(m.group(1))

    # 在全仓统计每个 F-NNN 的引用次数（排除 feedback.md 自身的声明行）
    counts: dict[str, int] = {d: 0 for d in declared}
    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        if path.resolve() == feedback.resolve():
            continue
        text = "\n".join(_read_lines(path))
        for match in F_RULE_RE.finditer(text):
            rid = match.group(1)
            if rid in counts:
                counts[rid] += 1

    for rid in sorted(declared):
        if counts[rid] < min_refs:
            result.findings.append(Finding(
                check="rule-usage",
                path="docs/memory/feedback.md",
                line=0,
                category="dead_rule_candidate",
                level=level,
                suggestion=f"F-{rid} has {counts[rid]} external references (< {min_refs}); consider retiring or documenting why it exists",
            ))
    return result


# ---------- 报告输出 ----------

CHECK_FUNCS = {
    "links": check_links,
    "archived-refs": check_archived_refs,
    "orphans": check_orphans,
    "home-path-refs": check_home_path_refs,
    "rule-pointer-sync": check_rule_pointer_sync,
    "rule-usage": check_rule_usage,
}


def _write_tsv(results: list[CheckResult], tsv_dir: Path) -> None:
    tsv_dir.mkdir(parents=True, exist_ok=True)
    for r in results:
        path = tsv_dir / f"{r.check}.tsv"
        with path.open("w", encoding="utf-8") as fp:
            fp.write("check\tpath\tline\tcategory\tlevel\tsuggestion\tmatched\n")
            for f in r.findings:
                fp.write(f.as_tsv() + "\n")


def _print_summary(results: list[CheckResult], verbose: bool) -> None:
    total_findings = sum(len(r.findings) for r in results)
    cats_with_findings = [r.check for r in results if r.findings]
    print(f"docaudit: {len(results)} checks, {len(cats_with_findings)} categories with findings")
    print()
    for r in results:
        label = f"[{r.check}]".ljust(22)
        if r.skipped:
            print(f"{label} SKIPPED ({r.skip_reason})")
            continue
        summary_parts = []
        if r.error_count:
            summary_parts.append(f"{r.error_count} error")
        if r.warning_count:
            summary_parts.append(f"{r.warning_count} warning")
        if r.info_count:
            summary_parts.append(f"{r.info_count} info")
        summary = " / ".join(summary_parts) if summary_parts else "clean"
        print(f"{label} {summary}")
        if verbose and r.findings:
            for f in r.findings[:20]:
                loc = f"{f.path}:{f.line}" if f.line else f.path
                print(f"  · {loc}  [{f.category}]  {f.suggestion}")
            if len(r.findings) > 20:
                print(f"  ... and {len(r.findings) - 20} more")
    print()
    error_checks = [r.check for r in results if r.error_count > 0]
    if error_checks:
        print(f"Exit: 1 (error level in: {', '.join(error_checks)})")
    else:
        print("Exit: 0")


def _overall_exit_code(results: list[CheckResult], strict: bool) -> int:
    for r in results:
        if r.error_count > 0:
            return 1
        if strict and r.warning_count > 0:
            return 1
    return 0


# ---------- CLI ----------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="docaudit",
        description="SnapDrill knowledge base audit engine (Phase B).",
    )
    parser.add_argument(
        "check",
        nargs="?",
        choices=CHECK_NAMES,
        help="Run a single check. Omit and use --all for full sweep.",
    )
    parser.add_argument("--all", action="store_true", help="Run all 6 checks.")
    parser.add_argument("--strict", action="store_true", help="Treat warning as error.")
    parser.add_argument("--report", action="store_true", help="Write TSV reports to reports/.")
    parser.add_argument("--baseline", action="store_true", help="Apply legacy_whitelist baseline exemptions.")
    parser.add_argument("--verbose", "-v", action="store_true", help="Print finding details in summary.")
    parser.add_argument("--policy", type=Path, default=POLICY_PATH, help="Override policy.yaml path.")

    args = parser.parse_args(argv)
    if not args.check and not args.all:
        parser.error("specify a check name or --all")

    policy = load_policy(args.policy)

    checks_to_run = CHECK_NAMES if args.all else [args.check]
    results: list[CheckResult] = []
    for name in checks_to_run:
        func = CHECK_FUNCS[name]
        try:
            results.append(func(policy, args.baseline))
        except Exception as exc:  # noqa: BLE001
            print(f"ERROR: check {name} crashed: {exc}", file=sys.stderr)
            return 2

    if args.report:
        tsv_dir = REPO_ROOT / policy.get("output", {}).get("tsv_dir", "reports")
        _write_tsv(results, tsv_dir)

    _print_summary(results, args.verbose)
    return _overall_exit_code(results, args.strict)


if __name__ == "__main__":
    sys.exit(main())
