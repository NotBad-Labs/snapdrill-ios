#!/usr/bin/env python3
"""知识体系审计引擎（Phase B PR-1 起；Phase 4 扩 verdict-sync + external-gap-expiry）。

子命令：
  all                  运行全部 checks（含 frontmatter via subprocess）
  links                Markdown 内部 broken link
  archived-refs        对 policy.yaml 声明的 archived_sources 旧路径硬引用（归档后应改用新路径）
  orphans              docs/**/*.md 在全仓零引用
  home-path-refs       仓库内对 ~/.claude/ 私有路径的硬编码
  rule-usage           F-NNN 规则外部引用计数（dead rule 候选）
  skill-inventory      skill 目录架构计数与 Claude adapter 指向
  skill-links          共享 skill 源内相对 Markdown 引用必须存在
  skill-provenance     共享 community skill 来源与本地 blob 必须被 ledger/lockfile 覆盖
  verdict-sync         verdict 分布跨文件漂移（同标签多个 distinct 数字）
  external-gap-expiry  VALID_WITH_GAP 文件 frontmatter 必须含 gap_type/gap_due/gap_owner

详见 Scripts/audit/README.md 与 Scripts/audit/policy.yaml。

用法：
    python3 Scripts/audit/docaudit.py <subcommand> [--strict] [--report] [--baseline]

退出码：0 通过 / 1 error 级命中 / 2 配置错误。
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
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
    "rule-usage",
    "skill-inventory",
    "skill-links",
    "skill-provenance",
    "verdict-sync",
    "external-gap-expiry",
]

CHECK_DESCRIPTIONS = {
    "links": {
        "help": "Detect broken Markdown links in docs.",
        "description": "扫描所有 Markdown 内部引用 [text](path.md)，目标文件不存在即 broken_link。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py links --strict",
    },
    "archived-refs": {
        "help": "Detect hardcoded references to deprecated archived_sources paths (see policy.yaml).",
        "description": "扫描对 policy.yaml 中 archived_sources 声明的 md 文件的活跃硬引用。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py archived-refs --baseline",
    },
    "orphans": {
        "help": "Detect docs/**/*.md with zero references in repo.",
        "description": "扫描 docs/**/*.md，若在全仓（docs/.claude/Scripts/STATUS.md 等）无任何引用则标记孤儿。",
        "epilog": "白名单见 policy.yaml checks.orphans.whitelist。",
    },
    "home-path-refs": {
        "help": "Detect hardcoded ~/.claude/ private path refs in repo.",
        "description": "扫描仓库内对 ~/.claude/ 私有路径的硬编码，排除 allowed_contexts（纪律说明文档）。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py home-path-refs --verbose",
    },
    "rule-usage": {
        "help": "Count F-NNN rule external references (dead rule candidates).",
        "description": "统计 docs/memory/feedback.md 中声明的 F-NNN 规则在全仓的外部引用数，低于 min_references 即 dead candidate。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py rule-usage --verbose",
    },
    "skill-inventory": {
        "help": "Validate skill inventory counts and Claude adapter targets.",
        "description": "统计 .claude/skills 与 .agents/skills，并核对 docs/standards/skill-architecture.md 的计数声明。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py skill-inventory --verbose",
    },
    "skill-links": {
        "help": "Validate relative Markdown references in shared skill sources.",
        "description": "扫描 .agents/skills/*/SKILL.md 的相对 Markdown 引用，目标文件不存在即 broken_skill_ref。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py skill-links --verbose",
    },
    "skill-provenance": {
        "help": "Validate .agents skill provenance against lockfile and source ledger.",
        "description": "核对 .agents/skills/*/SKILL.md 是否被结构化 skills-lock.json、project-owned 白名单或 legacy source-ledger snapshot 覆盖，并校验 vendored local blob。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py skill-provenance --verbose",
    },
    "verdict-sync": {
        "help": "Detect verdict distribution drift across STATUS / handoff / memory docs.",
        "description": "扫描 verdict 分布声明（如 '47 VALID', '4 NEEDS_REVISION'），同一标签出现多个 distinct 数字 → 漂移。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py verdict-sync --verbose",
    },
    "external-gap-expiry": {
        "help": "Validate VALID_WITH_GAP files have structured gap metadata (gap_type/owner/due).",
        "description": "扫描 frontmatter audit_note 标 VALID_WITH_GAP 的文件，要求同时声明 gap_type / owner / due_trigger 等结构化字段，否则 free-text 缺机械到期触发。",
        "epilog": "示例：python3 Scripts/audit/docaudit.py external-gap-expiry --verbose",
    },
}

# Markdown 内部链接正则 — [text](path.md) 或 [text](path.md#anchor) 或 [text](path.md "title")
# 排除 http/mailto/锚点/图片；支持可选 title 属性（#710 High 1）
LINK_RE = re.compile(r"(?<!\!)\[[^\]]*\]\(([^)#\s]*?\.md)(?:\s+\"[^\"]*\")?(?:#[^)]*)?\)")

# 任意 md 文件路径引用（orphan 检测）
# 要求至少包含一个 / 作为路径分隔符，避免匹配散文中的 This-is-sentence.md（#710 High 2）
# 匹配: docs/foo.md, ./foo/bar.md, ../a/b/c.md, foo/bar_baz-v2.md
# 不匹配: Just-a-sentence-like-this.md, README.md, file-name.md
PATH_REF_RE = re.compile(r"((?:\.\.?/|[A-Za-z0-9_][A-Za-z0-9_\-]*/)[A-Za-z0-9_\-./]*\.md)")

# skill 文本常见裸文件名引用：`templates.md` / `navigation-stack.md`
BARE_MD_REF_RE = re.compile(r"(?<![A-Za-z0-9_./-])([A-Za-z0-9_][A-Za-z0-9_-]*\.md)(?![A-Za-z0-9_./-])")

# ~/.claude/ 引用
HOME_CLAUDE_RE = re.compile(r"~/\.claude/[A-Za-z0-9_\-./]*")

# F-NNN 规则 ID
F_RULE_RE = re.compile(r"\bF-(\d{3})\b")

# rule-usage check 用：docs/memory/feedback.md 中的 F-rule declaration site
# 同时支持: ### F-NNN 标题 / | F-NNN | 表格行 / - F-NNN: 列表项
# 兼容前缀加粗 **F-NNN** 与反引号 `F-NNN`
# 行首 ^ 锚 + (?!\d) 防御确保不误吃 F-1234 或行内 reference site
# 已知盲区（feedback.md SSOT 结构变更时重审本正则）:
#   1. 退役记录标题改名（非「退役」/「Retired」前缀）
#   2. retired 段中间夹 active 段（状态机单向不退出）
#   3. F-NNNN 四位编号（编号规则升级时）
#   4. blockquote / HTML 注释包裹声明
#   5. 跨多行折断声明 / 表格编号列移位 / list 改用 * 或数字列表
F_RULE_DECL_RE = re.compile(r"""
    ^\s*(?:
        \|\s*`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*\|        # 表格首列声明
      | \#{1,6}\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\b      # 标题声明
      | [-*+]\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*[:：-] # 列表声明（含冒号变体）
    )
""", re.VERBOSE)
# 退役段标题识别（中英文双语，IGNORECASE）
F_RULE_RETIRED_HEADING_RE = re.compile(r"^#{1,4}\s+(?:退役|Retired)", re.IGNORECASE)

# docs/standards/skill-architecture.md inventory table rows
SKILL_ARCH_COUNT_RE = re.compile(r"^\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|", re.MULTILINE)
SKILL_ADAPTER_TARGET_RE = re.compile(r"((?:\.\./)+\.agents/skills/([A-Za-z0-9_-]+)/SKILL\.md)")
SKILL_PROVENANCE_SECTION_RE = re.compile(r"^## Current Shared `([^`]+)` Snapshot$")
SKILL_PROVENANCE_ROW_RE = re.compile(
    r"^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*`([0-9a-f]{40})`\s*\|\s*`([0-9a-f]{40})`\s*\|$"
)
SKILL_SUPPORT_FILE_ROW_RE = re.compile(
    r"^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*`([0-9a-f]{40})`\s*\|\s*`([0-9a-f]{40})`\s*\|$"
)
SKILL_CLAUDE_ONLY_SECTION_RE = re.compile(r"^## Current Claude-Only `?rshankras`? Skills$")
SKILL_CLAUDE_ONLY_ROW_RE = re.compile(
    r"^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*`([0-9a-f]{40})`\s*\|\s*`([^`]+)`\s*\|\s*`([0-9a-f]{40})`\s*\|\s*([^|]+)\s*\|$"
)
GIT_BLOB_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
LOCK_SOURCE_TYPES = {"github"}
LOCK_KINDS = {"managed", "vendored"}
LOCK_PATCH_STATUSES = {"documented-local-patch", "exact-upstream", "frontmatter-adapter-only"}
VENDORED_PATCH_RATIONALE_PREFIX = "docs/standards/skill-patches/"
MANAGED_LOCK_REQUIRED_FIELDS = (
    "source",
    "sourceType",
    "skillPath",
    "computedHash",
    "localBlob",
)
MANAGED_SUPPORT_REQUIRED_FIELDS = (
    "localPath",
    "localBlob",
)
VENDORED_LOCK_REQUIRED_FIELDS = (
    "source",
    "sourceType",
    "upstreamCommit",
    "upstreamPath",
    "upstreamBlob",
    "localPath",
    "localBlob",
    "patchStatus",
)
VENDORED_SUPPORT_REQUIRED_FIELDS = (
    "localPath",
    "upstreamPath",
    "upstreamBlob",
    "localBlob",
)


# ---------- 数据类型 ----------

@dataclass
class Finding:
    check: str
    path: str
    line: int
    category: str
    level: str                  # error / warning / info（原始级别，不受豁免影响）
    suggestion: str = ""
    matched_text: str = ""
    suppressed: bool = False    # post-filter 豁免命中标记
    suppressed_reason: str = ""

    def as_tsv(self) -> str:
        fields = [
            self.check,
            self.path,
            str(self.line),
            self.category,
            self.level,
            "suppressed" if self.suppressed else "active",
            self.suggestion,
            self.suppressed_reason,
            self.matched_text.replace("\t", " ").replace("\n", " ")[:200],
        ]
        return "\t".join(fields)


@dataclass
class CheckResult:
    check: str
    level: str                  # policy 默认级别
    findings: list[Finding] = field(default_factory=list)

    @property
    def active_findings(self) -> list[Finding]:
        return [f for f in self.findings if not f.suppressed]

    @property
    def error_count(self) -> int:
        return sum(1 for f in self.active_findings if f.level == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for f in self.active_findings if f.level == "warning")

    @property
    def info_count(self) -> int:
        return sum(1 for f in self.active_findings if f.level == "info")

    @property
    def suppressed_count(self) -> int:
        return sum(1 for f in self.findings if f.suppressed)


@dataclass(frozen=True)
class WhitelistRule:
    check: str
    reason: str
    expires_on: date
    paths: tuple[str, ...]          # glob patterns，空 tuple = 匹配该 check 的所有 findings
    categories: tuple[str, ...]     # 空 tuple = 匹配所有 category


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


def _parse_whitelist(policy: dict) -> list[WhitelistRule]:
    """解析 legacy_whitelist。无效日期 / 缺字段 → exit 2 (fail-closed)。"""
    raw = policy.get("legacy_whitelist", [])
    if raw is None:
        return []
    if not isinstance(raw, list):
        print(
            "ERROR: policy.yaml legacy_whitelist must be a list of rule objects",
            file=sys.stderr,
        )
        sys.exit(2)
    rules: list[WhitelistRule] = []
    for idx, entry in enumerate(raw):
        if not isinstance(entry, dict):
            print(
                f"ERROR: legacy_whitelist[{idx}] must be a mapping",
                file=sys.stderr,
            )
            sys.exit(2)
        check_name = entry.get("check")
        if check_name not in CHECK_NAMES:
            print(
                f"ERROR: legacy_whitelist[{idx}].check '{check_name}' unknown; must be one of {CHECK_NAMES}",
                file=sys.stderr,
            )
            sys.exit(2)
        expires_raw = entry.get("expires_on")
        if not isinstance(expires_raw, str):
            print(
                f"ERROR: legacy_whitelist[{idx}].expires_on must be a YYYY-MM-DD string (got {expires_raw!r})",
                file=sys.stderr,
            )
            sys.exit(2)
        try:
            parts = expires_raw.split("-")
            if len(parts) != 3:
                raise ValueError("expects YYYY-MM-DD")
            y, m, d = (int(p) for p in parts)
            expires_on = date(y, m, d)
        except (ValueError, TypeError) as exc:
            print(
                f"ERROR: legacy_whitelist[{idx}].expires_on '{expires_raw}' is not a valid date: {exc}",
                file=sys.stderr,
            )
            sys.exit(2)
        reason = entry.get("reason", "").strip()
        if not reason:
            print(
                f"ERROR: legacy_whitelist[{idx}].reason is required (document why this is baselined)",
                file=sys.stderr,
            )
            sys.exit(2)
        paths = tuple(entry.get("paths") or ())
        categories = tuple(entry.get("categories") or ())
        rules.append(WhitelistRule(
            check=check_name,
            reason=reason,
            expires_on=expires_on,
            paths=paths,
            categories=categories,
        ))
    return rules


def _apply_whitelist(
    result: CheckResult,
    rules: list[WhitelistRule],
    baseline_flag: bool,
) -> None:
    """Finding 级 post-filter。只在 baseline_flag 且规则未过期时降级。"""
    if not baseline_flag:
        return
    today = date.today()
    for f in result.findings:
        for rule in rules:
            if rule.check != result.check:
                continue
            if rule.expires_on < today:
                continue  # 过期规则不生效（fail-closed 到未豁免状态）
            if rule.paths and not _path_matches(f.path, rule.paths):
                continue
            if rule.categories and f.category not in rule.categories:
                continue
            f.suppressed = True
            f.suppressed_reason = f"{rule.reason} (expires_on: {rule.expires_on})"
            break


def _path_matches(path: str, patterns: Iterable[str]) -> bool:
    p_norm = path.replace(os.sep, "/")
    for pat in patterns:
        pat_norm = pat.rstrip("/")
        if pat_norm.endswith("/**"):
            base = pat_norm[:-3].rstrip("/")
            if p_norm == base or p_norm.startswith(base + "/"):
                return True
        elif fnmatch.fnmatch(p_norm, pat_norm):
            return True
        elif p_norm == pat_norm:
            return True
    return False


# ---------- 文件扫描辅助 ----------

def _iter_text_files(
    policy: dict,
    extensions: Iterable[str] = (".md", ".sh", ".py", ".yaml", ".yml"),
) -> Iterable[Path]:
    scan = policy.get("scan", {})
    includes = scan.get("include", [])
    excludes = scan.get("exclude", [])

    for inc in includes:
        inc_path = REPO_ROOT / inc
        if inc_path.is_file():
            rel = inc_path.relative_to(REPO_ROOT)
            if any(_matches_exclude(rel, ex) for ex in excludes):
                continue
            yield inc_path
            continue
        if not inc_path.is_dir():
            continue
        for root, dirs, files in os.walk(inc_path):
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
    p = pattern.rstrip("/")
    rel_str = str(rel_path).replace(os.sep, "/")
    if p.endswith("/**"):
        base = p[:-3].rstrip("/")
        return rel_str == base or rel_str.startswith(base + "/")
    if "*" not in p:
        return rel_str == p or rel_str.startswith(p + "/")
    return fnmatch.fnmatch(rel_str, p)


def _matches_whitelist_glob(rel_path: str, patterns: Iterable[str]) -> bool:
    for pat in patterns or ():
        p = pat.rstrip("/")
        rel_norm = rel_path.replace(os.sep, "/")
        if p.endswith("/**"):
            base = p[:-3].rstrip("/")
            if rel_norm == base or rel_norm.startswith(base + "/"):
                return True
        elif p == rel_norm:
            return True
        elif fnmatch.fnmatch(rel_norm, p):
            return True
    return False


def _read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []


# ---------- check: links ----------

def check_links(policy: dict) -> CheckResult:
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

def check_archived_refs(policy: dict) -> CheckResult:
    conf = policy["checks"]["archived-refs"]
    level = conf["level"]
    archived = conf.get("archived_sources", [])
    result = CheckResult(check="archived-refs", level=level)

    # 只匹配完整路径，不匹配 basename — Phase C PR-α2 修复（Issue #710 High 3）
    # 原 basename 匹配会把"新归档路径 docs/archive/research/<name>.md"也误判命中，
    # 阻碍迁移完成。完整路径匹配保持对旧路径（archived_sources 声明）的精准检测。
    patterns = [(src, re.escape(src)) for src in archived]

    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        rel = path.relative_to(REPO_ROOT)
        rel_str = str(rel)
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
                    break
    return result


# ---------- check: orphans ----------

def check_orphans(policy: dict) -> CheckResult:
    conf = policy["checks"]["orphans"]
    level = conf["level"]
    whitelist = conf.get("whitelist", [])
    result = CheckResult(check="orphans", level=level)

    docs_mds: list[Path] = []
    docs_root = REPO_ROOT / "docs"
    if docs_root.is_dir():
        for root, _dirs, files in os.walk(docs_root):
            for fn in files:
                if fn.endswith(".md"):
                    docs_mds.append(Path(root) / fn)

    referenced: set[str] = set()
    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        text = "\n".join(_read_lines(path))
        for match in PATH_REF_RE.finditer(text):
            ref = match.group(1)
            if ref.startswith("./"):
                ref = ref[2:]
            referenced.add(ref)
            referenced.add(Path(ref).name)

    for md in docs_mds:
        rel = md.relative_to(REPO_ROOT)
        rel_str = str(rel)
        if _matches_whitelist_glob(rel_str, whitelist):
            continue
        name = md.name
        if rel_str in referenced or name in referenced:
            continue
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

def check_home_path_refs(policy: dict) -> CheckResult:
    conf = policy["checks"]["home-path-refs"]
    level = conf["level"]
    allowed = conf.get("allowed_contexts", [])
    result = CheckResult(check="home-path-refs", level=level)

    for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
        rel = path.relative_to(REPO_ROOT)
        rel_str = str(rel)
        if _matches_whitelist_glob(rel_str, allowed):
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

# ---------- check: rule-usage ----------

def check_rule_usage(policy: dict) -> CheckResult:
    conf = policy["checks"]["rule-usage"]
    level = conf["level"]
    min_refs = conf.get("min_references", 1)
    result = CheckResult(check="rule-usage", level=level)

    feedback = REPO_ROOT / "docs" / "memory" / "feedback.md"
    if not feedback.is_file():
        return result
    fb_text = feedback.read_text(encoding="utf-8")
    declared = set()
    in_retired_section = False
    for line in fb_text.splitlines():
        if F_RULE_RETIRED_HEADING_RE.match(line):
            in_retired_section = True
            continue
        if in_retired_section:
            continue
        m = F_RULE_DECL_RE.match(line)
        if m:
            declared.add(next(g for g in m.groups() if g))

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
                suggestion=(
                    f"F-{rid} has {counts[rid]} external references (< {min_refs}); "
                    "consider retiring or documenting why it exists"
                ),
            ))
    return result


# ---------- check: skill-inventory ----------

def _first_level_skill_names(root: Path) -> set[str]:
    if not root.is_dir():
        return set()
    names: set[str] = set()
    for child in root.iterdir():
        if child.is_dir() and (child / "SKILL.md").is_file():
            names.add(child.name)
    return names


def _plugin_payload_count() -> int:
    root = REPO_ROOT / ".agents" / "skills"
    if not root.is_dir():
        return 0
    count = 0
    for skill_dir in root.iterdir():
        nested_root = skill_dir / "skills"
        if not nested_root.is_dir():
            continue
        for nested in nested_root.iterdir():
            if nested.is_dir() and (nested / "SKILL.md").is_file():
                count += 1
    return count


def _adapter_target(path: Path) -> tuple[str, Path] | None:
    text = path.read_text(encoding="utf-8")
    match = SKILL_ADAPTER_TARGET_RE.search(text)
    if not match:
        return None
    raw_target, target_name = match.groups()
    return target_name, (path.parent / raw_target).resolve()


def check_skill_inventory(policy: dict) -> CheckResult:
    conf = policy["checks"]["skill-inventory"]
    level = conf["level"]
    result = CheckResult(check="skill-inventory", level=level)

    claude_root = REPO_ROOT / ".claude" / "skills"
    agents_root = REPO_ROOT / ".agents" / "skills"
    claude_names = _first_level_skill_names(claude_root)
    shared_names = _first_level_skill_names(agents_root)

    adapter_names: set[str] = set()
    for name in sorted(claude_names & shared_names):
        claude_entry = claude_root / name
        if claude_entry.is_symlink():
            expected = (agents_root / name).resolve()
            actual = claude_entry.resolve()
            if actual == expected:
                adapter_names.add(name)
                continue
            result.findings.append(Finding(
                check="skill-inventory",
                path=str(claude_entry.relative_to(REPO_ROOT)),
                line=0,
                category="symlink_target_mismatch",
                level=level,
                suggestion=f"symlink for '{name}' points to {actual}; expected {expected}",
            ))
            continue

        adapter_file = claude_entry / "SKILL.md"
        target = _adapter_target(adapter_file)
        if target is None:
            result.findings.append(Finding(
                check="skill-inventory",
                path=str(adapter_file.relative_to(REPO_ROOT)),
                line=0,
                category="duplicate_without_adapter",
                level=level,
                suggestion=f"duplicate skill name '{name}' must be a Claude adapter pointing to .agents/skills/{name}/SKILL.md",
            ))
            continue
        target_name, target_path = target
        if target_name != name:
            result.findings.append(Finding(
                check="skill-inventory",
                path=str(adapter_file.relative_to(REPO_ROOT)),
                line=0,
                category="adapter_name_mismatch",
                level=level,
                suggestion=f"adapter for '{name}' points to shared skill '{target_name}'",
            ))
            continue
        if not target_path.is_file():
            result.findings.append(Finding(
                check="skill-inventory",
                path=str(adapter_file.relative_to(REPO_ROOT)),
                line=0,
                category="adapter_target_missing",
                level=level,
                suggestion=f"adapter target does not exist: {target_path.relative_to(REPO_ROOT)}",
            ))
            continue
        adapter_names.add(name)

    actual = {
        "Claude discovery entries": len(claude_names),
        "Shared first-level skill sources": len(shared_names),
        "Claude adapter entries": len(adapter_names),
        "Distinct first-level skill names": len(claude_names | shared_names),
        "Plugin payload skills": _plugin_payload_count(),
    }

    arch_path = REPO_ROOT / "docs" / "standards" / "skill-architecture.md"
    if not arch_path.is_file():
        result.findings.append(Finding(
            check="skill-inventory",
            path="docs/standards/skill-architecture.md",
            line=0,
            category="missing_architecture_doc",
            level=level,
            suggestion="create skill architecture SSOT with inventory table",
        ))
        return result

    arch_text = arch_path.read_text(encoding="utf-8")
    declared = {label.strip(): int(count) for label, count in SKILL_ARCH_COUNT_RE.findall(arch_text)}

    for label, actual_count in actual.items():
        declared_count = declared.get(label)
        if declared_count != actual_count:
            result.findings.append(Finding(
                check="skill-inventory",
                path=str(arch_path.relative_to(REPO_ROOT)),
                line=0,
                category="count_mismatch",
                level=level,
                suggestion=f"{label}: declared {declared_count}, actual {actual_count}",
            ))

    return result


# ---------- check: skill-links ----------

def _iter_shared_skill_entrypoints() -> Iterable[Path]:
    root = REPO_ROOT / ".agents" / "skills"
    if not root.is_dir():
        return
    for child in sorted(root.iterdir()):
        skill_file = child / "SKILL.md"
        if child.is_dir() and skill_file.is_file():
            yield skill_file


def _skill_ref_target(skill_file: Path, ref: str) -> Path | None:
    if ref.startswith(("http://", "https://", "mailto:", "${")):
        return None
    if ref.startswith("/"):
        return REPO_ROOT / ref.lstrip("/")
    return (skill_file.parent / ref).resolve()


def check_skill_links(policy: dict) -> CheckResult:
    conf = policy["checks"]["skill-links"]
    level = conf["level"]
    result = CheckResult(check="skill-links", level=level)

    for path in _iter_shared_skill_entrypoints():
        rel = str(path.relative_to(REPO_ROOT))
        seen_on_line: set[tuple[int, str]] = set()
        for lineno, line in enumerate(_read_lines(path), start=1):
            refs = [match.group(1).strip() for match in LINK_RE.finditer(line)]
            refs.extend(match.group(1) for match in PATH_REF_RE.finditer(line))
            refs.extend(match.group(1) for match in BARE_MD_REF_RE.finditer(line))

            for ref in refs:
                key = (lineno, ref)
                if key in seen_on_line:
                    continue
                seen_on_line.add(key)
                target = _skill_ref_target(path, ref)
                if target is None or target.is_file():
                    continue
                result.findings.append(Finding(
                    check="skill-links",
                    path=rel,
                    line=lineno,
                    category="broken_skill_ref",
                    level=level,
                    suggestion=f"shared skill reference target does not exist: {ref}",
                    matched_text=line.strip(),
                ))
    return result


# ---------- check: skill-provenance ----------

def _git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    header = f"blob {len(data)}\0".encode("utf-8")
    return hashlib.sha1(header + data).hexdigest()


def _load_skill_lock_entries(result: CheckResult) -> dict[str, object] | None:
    lock_path = REPO_ROOT / "skills-lock.json"
    if not lock_path.is_file():
        return {}
    try:
        payload = json.loads(lock_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        result.findings.append(Finding(
            check="skill-provenance",
            path="skills-lock.json",
            line=0,
            category="invalid_lockfile_json",
            level=result.level,
            suggestion=f"skills-lock.json must be valid JSON: {exc}",
        ))
        return None
    skills = payload.get("skills", {})
    if not isinstance(skills, dict):
        result.findings.append(Finding(
            check="skill-provenance",
            path="skills-lock.json",
            line=0,
            category="invalid_lockfile_schema",
            level=result.level,
            suggestion="skills-lock.json must contain a mapping at key 'skills'",
        ))
        return None
    return skills


def _lockfile_schema_finding(result: CheckResult, category: str, suggestion: str) -> None:
    result.findings.append(Finding(
        check="skill-provenance",
        path="skills-lock.json",
        line=0,
        category=category,
        level=result.level,
        suggestion=suggestion,
    ))


def _require_lock_string_fields(
    result: CheckResult,
    entry: dict[str, object],
    name: str,
    fields: tuple[str, ...],
    scope: str,
) -> bool:
    ok = True
    for field in fields:
        value = entry.get(field)
        if not isinstance(value, str) or not value:
            _lockfile_schema_finding(
                result,
                "invalid_vendored_lockfile_entry",
                f"skills-lock.json '{name}' {scope} field '{field}' must be a non-empty string",
            )
            ok = False
    return ok


def _validate_lock_blob_field(result: CheckResult, name: str, field: str, value: str, scope: str) -> bool:
    if GIT_BLOB_RE.match(value):
        return True
    _lockfile_schema_finding(
        result,
        "invalid_vendored_lockfile_entry",
        f"skills-lock.json '{name}' {scope} field '{field}' must be a 40-character git blob SHA",
    )
    return False


def _validate_lock_source_type(result: CheckResult, name: str, value: str, scope: str) -> bool:
    if value in LOCK_SOURCE_TYPES:
        return True
    _lockfile_schema_finding(
        result,
        "invalid_lockfile_schema",
        f"skills-lock.json '{name}' {scope} sourceType must be one of: {', '.join(sorted(LOCK_SOURCE_TYPES))}",
    )
    return False


def _validate_managed_lock_entry(
    result: CheckResult,
    name: str,
    entry: object,
) -> dict[str, object] | None:
    if not isinstance(entry, dict):
        _lockfile_schema_finding(
            result,
            "invalid_lockfile_schema",
            f"skills-lock.json entry '{name}' must be a mapping",
        )
        return None

    if not _require_lock_string_fields(result, entry, name, MANAGED_LOCK_REQUIRED_FIELDS, "skill"):
        return None
    if not _validate_lock_source_type(result, name, str(entry["sourceType"]), "skill"):
        return None

    expected_skill_path = f"{name}/SKILL.md"
    if entry["skillPath"] != expected_skill_path:
        _lockfile_schema_finding(
            result,
            "managed_lockfile_path_mismatch",
            f"skills-lock.json '{name}' skillPath must be '{expected_skill_path}'",
        )
        return None

    if not SHA256_RE.match(str(entry["computedHash"])):
        _lockfile_schema_finding(
            result,
            "invalid_managed_lockfile_entry",
            f"skills-lock.json '{name}' computedHash must be a 64-character SHA-256 digest",
        )
        return None

    if not _validate_lock_blob_field(result, name, "localBlob", str(entry["localBlob"]), "skill"):
        return None

    support_files = entry.get("supportFiles", [])
    if not isinstance(support_files, list):
        _lockfile_schema_finding(
            result,
            "invalid_managed_lockfile_entry",
            f"skills-lock.json '{name}' supportFiles must be a list when present",
        )
        return None

    for index, support in enumerate(support_files):
        if not isinstance(support, dict):
            _lockfile_schema_finding(
                result,
                "invalid_managed_lockfile_entry",
                f"skills-lock.json '{name}' supportFiles[{index}] must be a mapping",
            )
            return None
        if not _require_lock_string_fields(
            result,
            support,
            name,
            MANAGED_SUPPORT_REQUIRED_FIELDS,
            f"supportFiles[{index}]",
        ):
            return None
        expected_support_prefix = f".agents/skills/{name}/"
        support_local_path = str(support["localPath"])
        if not support_local_path.startswith(expected_support_prefix) or ".." in Path(support_local_path).parts:
            _lockfile_schema_finding(
                result,
                "managed_support_path_out_of_scope",
                (
                    f"skills-lock.json '{name}' support localPath must stay under "
                    f"'{expected_support_prefix}'"
                ),
            )
            return None
        if not _validate_lock_blob_field(
            result,
            name,
            "localBlob",
            str(support["localBlob"]),
            f"supportFiles[{index}]",
        ):
            return None

    return entry


def _validate_vendored_lock_entry(
    result: CheckResult,
    name: str,
    entry: object,
) -> dict[str, object] | None:
    if not isinstance(entry, dict):
        _lockfile_schema_finding(
            result,
            "invalid_lockfile_schema",
            f"skills-lock.json entry '{name}' must be a mapping",
        )
        return None

    if not _require_lock_string_fields(result, entry, name, VENDORED_LOCK_REQUIRED_FIELDS, "skill"):
        return None
    if not _validate_lock_source_type(result, name, str(entry["sourceType"]), "skill"):
        return None

    local_path = entry["localPath"]
    expected_local_path = f".agents/skills/{name}/SKILL.md"
    if local_path != expected_local_path:
        _lockfile_schema_finding(
            result,
            "vendored_lockfile_path_mismatch",
            f"skills-lock.json '{name}' localPath must be '{expected_local_path}'",
        )
        return None

    for field in ("upstreamCommit", "upstreamBlob", "localBlob"):
        if not _validate_lock_blob_field(result, name, field, str(entry[field]), "skill"):
            return None
    if entry["patchStatus"] not in LOCK_PATCH_STATUSES:
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            (
                f"skills-lock.json '{name}' patchStatus must be one of: "
                f"{', '.join(sorted(LOCK_PATCH_STATUSES))}"
            ),
        )
        return None
    if entry["localBlob"] != entry["upstreamBlob"] and entry["patchStatus"] == "exact-upstream":
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            f"skills-lock.json '{name}' patchStatus cannot be exact-upstream when localBlob differs",
        )
        return None
    if entry["localBlob"] == entry["upstreamBlob"] and entry["patchStatus"] == "frontmatter-adapter-only":
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            f"skills-lock.json '{name}' patchStatus should be exact-upstream when localBlob equals upstreamBlob",
        )
        return None
    if entry["patchStatus"] != "documented-local-patch" and "patchRationale" in entry:
        _lockfile_schema_finding(
            result,
            "stale_vendored_patch_rationale",
            f"skills-lock.json '{name}' patchRationale is only allowed for documented-local-patch",
        )
        return None
    if entry["patchStatus"] == "documented-local-patch":
        patch_rationale = entry.get("patchRationale")
        if not isinstance(patch_rationale, str) or not patch_rationale:
            _lockfile_schema_finding(
                result,
                "missing_vendored_patch_rationale",
                f"skills-lock.json '{name}' documented-local-patch requires patchRationale",
            )
            return None
        rationale_parts = Path(patch_rationale).parts
        if (
            Path(patch_rationale).is_absolute()
            or ".." in rationale_parts
            or not patch_rationale.startswith(VENDORED_PATCH_RATIONALE_PREFIX)
            or patch_rationale != f"{VENDORED_PATCH_RATIONALE_PREFIX}{name}.md"
            or not patch_rationale.endswith(".md")
        ):
            _lockfile_schema_finding(
                result,
                "invalid_vendored_patch_rationale",
                (
                    f"skills-lock.json '{name}' patchRationale must be "
                    f"'{VENDORED_PATCH_RATIONALE_PREFIX}{name}.md'"
                ),
            )
            return None
        rationale_path = REPO_ROOT / patch_rationale
        rationale_root = REPO_ROOT / VENDORED_PATCH_RATIONALE_PREFIX
        if not rationale_path.is_file() or not rationale_path.resolve().is_relative_to(rationale_root.resolve()):
            _lockfile_schema_finding(
                result,
                "vendored_patch_rationale_missing",
                f"skills-lock.json '{name}' patchRationale points to missing file '{patch_rationale}'",
            )
            return None
        rationale_text = rationale_path.read_text(encoding="utf-8")
        required_markers = ("Reason:", "Upstream status:", "Removal condition:")
        missing_markers = [marker for marker in required_markers if marker not in rationale_text]
        if missing_markers:
            _lockfile_schema_finding(
                result,
                "incomplete_vendored_patch_rationale",
                (
                    f"skills-lock.json '{name}' patchRationale must include: "
                    f"{', '.join(required_markers)}"
                ),
            )
            return None

    support_files = entry.get("supportFiles", [])
    if not isinstance(support_files, list):
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            f"skills-lock.json '{name}' supportFiles must be a list when present",
        )
        return None

    has_support_file_drift = False
    for index, support in enumerate(support_files):
        if not isinstance(support, dict):
            _lockfile_schema_finding(
                result,
                "invalid_vendored_lockfile_entry",
                f"skills-lock.json '{name}' supportFiles[{index}] must be a mapping",
            )
            return None
        if not _require_lock_string_fields(
            result,
            support,
            name,
            VENDORED_SUPPORT_REQUIRED_FIELDS,
            f"supportFiles[{index}]",
        ):
            return None
        expected_support_prefix = f".agents/skills/{name}/"
        support_local_path = str(support["localPath"])
        if not support_local_path.startswith(expected_support_prefix) or ".." in Path(support_local_path).parts:
            _lockfile_schema_finding(
                result,
                "vendored_support_path_out_of_scope",
                (
                    f"skills-lock.json '{name}' support localPath must stay under "
                    f"'{expected_support_prefix}'"
                ),
            )
            return None
        for field in ("upstreamBlob", "localBlob"):
            if not _validate_lock_blob_field(
                result,
                name,
                field,
                str(support[field]),
                f"supportFiles[{index}]",
            ):
                return None
        if support["localBlob"] != support["upstreamBlob"]:
            has_support_file_drift = True

    if has_support_file_drift and entry["patchStatus"] != "documented-local-patch":
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            (
                f"skills-lock.json '{name}' supportFiles localBlob differs from upstreamBlob; "
                "patchStatus must be documented-local-patch"
            ),
        )
        return None
    if (
        entry["localBlob"] == entry["upstreamBlob"]
        and not has_support_file_drift
        and entry["patchStatus"] == "documented-local-patch"
    ):
        _lockfile_schema_finding(
            result,
            "invalid_vendored_lockfile_entry",
            f"skills-lock.json '{name}' patchStatus cannot be documented-local-patch when no local blob differs",
        )
        return None

    return entry


def _parse_shared_vendored_snapshots(result: CheckResult) -> dict[str, dict[str, str]]:
    ledger = REPO_ROOT / "docs" / "standards" / "skill-source-ledger.md"
    rel = "docs/standards/skill-source-ledger.md"
    if not ledger.is_file():
        result.findings.append(Finding(
            check="skill-provenance",
            path=rel,
            line=0,
            category="missing_source_ledger",
            level=result.level,
            suggestion="create skill-source-ledger.md with Current Shared `<vendor>` Snapshot",
        ))
        return {}

    rows: dict[str, dict[str, str]] = {}
    in_section = False
    for lineno, line in enumerate(_read_lines(ledger), start=1):
        if line.startswith("## "):
            in_section = SKILL_PROVENANCE_SECTION_RE.match(line.strip()) is not None
            continue
        if not in_section:
            continue
        match = SKILL_PROVENANCE_ROW_RE.match(line.strip())
        if not match:
            continue
        skill, upstream_path, upstream_blob, local_blob = match.groups()
        rows[skill] = {
            "line": str(lineno),
            "upstream_path": upstream_path,
            "upstream_blob": upstream_blob,
            "local_blob": local_blob,
        }
    return rows


def _parse_shared_support_file_snapshots(result: CheckResult) -> list[dict[str, str]]:
    ledger = REPO_ROOT / "docs" / "standards" / "skill-source-ledger.md"
    if not ledger.is_file():
        return []

    rows: list[dict[str, str]] = []
    in_section = False
    for lineno, line in enumerate(_read_lines(ledger), start=1):
        if line.startswith("## "):
            in_section = line.strip() == "## Current Shared Vendored Support Files"
            continue
        if not in_section:
            continue
        match = SKILL_SUPPORT_FILE_ROW_RE.match(line.strip())
        if not match:
            continue
        skill, local_path, upstream_path, upstream_blob, local_blob = match.groups()
        rows.append({
            "line": str(lineno),
            "skill": skill,
            "local_path": local_path,
            "upstream_path": upstream_path,
            "upstream_blob": upstream_blob,
            "local_blob": local_blob,
        })
    return rows


def _parse_claude_only_skill_snapshots(result: CheckResult) -> list[dict[str, str]]:
    ledger = REPO_ROOT / "docs" / "standards" / "skill-source-ledger.md"
    if not ledger.is_file():
        return []

    rows: list[dict[str, str]] = []
    in_section = False
    saw_section = False
    for lineno, line in enumerate(_read_lines(ledger), start=1):
        if line.startswith("## "):
            stripped = line.strip()
            if "current claude-only" in stripped.lower() and "skills" in stripped.lower():
                saw_section = True
                if not SKILL_CLAUDE_ONLY_SECTION_RE.match(stripped):
                    result.findings.append(Finding(
                        check="skill-provenance",
                        path="docs/standards/skill-source-ledger.md",
                        line=lineno,
                        category="malformed_claude_only_section_heading",
                        level=result.level,
                        suggestion="Claude-only rshankras section heading must be '## Current Claude-Only `rshankras` Skills'",
                    ))
                    in_section = False
                    continue
            in_section = SKILL_CLAUDE_ONLY_SECTION_RE.match(stripped) is not None
            continue
        if not in_section:
            continue
        match = SKILL_CLAUDE_ONLY_ROW_RE.match(line.strip())
        if not match:
            if line.strip().startswith("| `"):
                result.findings.append(Finding(
                    check="skill-provenance",
                    path="docs/standards/skill-source-ledger.md",
                    line=lineno,
                    category="malformed_claude_only_ledger_row",
                    level=result.level,
                    suggestion="Claude-only skill ledger rows must include skill, Claude path, local blob, upstream path, upstream blob, and status",
                ))
            continue
        skill, local_path, local_blob, upstream_path, upstream_blob, _status = match.groups()
        expected_local_path = f".claude/skills/{skill}/SKILL.md"
        if local_path != expected_local_path:
            result.findings.append(Finding(
                check="skill-provenance",
                path="docs/standards/skill-source-ledger.md",
                line=lineno,
                category="claude_only_ledger_path_mismatch",
                level=result.level,
                suggestion=f"Claude-only skill '{skill}' path must be '{expected_local_path}'",
            ))
            continue
        if not GIT_BLOB_RE.match(upstream_blob):
            result.findings.append(Finding(
                check="skill-provenance",
                path="docs/standards/skill-source-ledger.md",
                line=lineno,
                category="malformed_claude_only_ledger_row",
                level=result.level,
                suggestion=f"Claude-only skill '{skill}' upstream blob must be a 40-character git blob SHA",
            ))
            continue
        rows.append({
            "line": str(lineno),
            "skill": skill,
            "local_path": local_path,
            "local_blob": local_blob,
            "upstream_path": upstream_path,
            "upstream_blob": upstream_blob,
        })
    if saw_section and not rows:
        result.findings.append(Finding(
            check="skill-provenance",
            path="docs/standards/skill-source-ledger.md",
            line=0,
            category="empty_claude_only_ledger_section",
            level=result.level,
            suggestion="Claude-only rshankras section must include machine-parseable skill rows",
        ))
    return rows


def check_skill_provenance(policy: dict) -> CheckResult:
    conf = policy["checks"]["skill-provenance"]
    level = conf["level"]
    project_owned = set(conf.get("project_owned", []) or [])
    result = CheckResult(check="skill-provenance", level=level)

    shared_root = REPO_ROOT / ".agents" / "skills"
    claude_root = REPO_ROOT / ".claude" / "skills"
    shared_names = _first_level_skill_names(shared_root)
    claude_names = _first_level_skill_names(claude_root)
    lock_entries = _load_skill_lock_entries(result)
    if lock_entries is None:
        return result

    managed_lock_entries: dict[str, dict[str, object]] = {}
    vendored_lock_entries: dict[str, dict[str, object]] = {}
    for name, entry in sorted(lock_entries.items()):
        if not isinstance(entry, dict):
            _lockfile_schema_finding(
                result,
                "invalid_lockfile_schema",
                f"skills-lock.json entry '{name}' must be a mapping",
            )
            continue

        kind = entry.get("kind")
        if kind not in LOCK_KINDS:
            _lockfile_schema_finding(
                result,
                "invalid_lockfile_schema",
                f"skills-lock.json entry '{name}' kind must be one of: {', '.join(sorted(LOCK_KINDS))}",
            )
            continue

        if kind == "vendored":
            validated = _validate_vendored_lock_entry(result, name, entry)
            if validated is not None:
                vendored_lock_entries[name] = validated
        elif kind == "managed":
            validated = _validate_managed_lock_entry(result, name, entry)
            if validated is not None:
                managed_lock_entries[name] = validated

    for name, entry in managed_lock_entries.items():
        local_path = REPO_ROOT / ".agents" / "skills" / str(entry["skillPath"])
        if not local_path.is_file():
            result.findings.append(Finding(
                check="skill-provenance",
                path="skills-lock.json",
                line=0,
                category="lockfile_points_to_missing_shared_skill",
                level=level,
                suggestion=(
                    f"skills-lock.json lists managed skill '{name}' at "
                    f"'.agents/skills/{entry['skillPath']}' but it does not exist"
                ),
            ))
            continue
        actual_blob = _git_blob_sha(local_path)
        if actual_blob != entry["localBlob"]:
            result.findings.append(Finding(
                check="skill-provenance",
                path=str(local_path.relative_to(REPO_ROOT)),
                line=0,
                category="managed_local_blob_mismatch",
                level=level,
                suggestion=(
                    f"lockfile local blob is {entry['localBlob']} but current blob is {actual_blob}; "
                    "do not edit managed community skill bodies without updating provenance"
                ),
            ))

        for support in entry.get("supportFiles", []):
            support_path = REPO_ROOT / str(support["localPath"])
            if not support_path.is_file():
                result.findings.append(Finding(
                    check="skill-provenance",
                    path="skills-lock.json",
                    line=0,
                    category="lockfile_points_to_missing_support_file",
                    level=level,
                    suggestion=(
                        f"skills-lock.json lists managed support file '{support['localPath']}' "
                        "but it does not exist"
                    ),
                ))
                continue
            actual_support_blob = _git_blob_sha(support_path)
            if actual_support_blob != support["localBlob"]:
                result.findings.append(Finding(
                    check="skill-provenance",
                    path=str(support["localPath"]),
                    line=0,
                    category="managed_support_file_blob_mismatch",
                    level=level,
                    suggestion=(
                        f"lockfile local blob is {support['localBlob']} but current blob is {actual_support_blob}; "
                        "do not edit managed community support files without updating provenance"
                    ),
                ))

    for name, entry in vendored_lock_entries.items():
        local_path = REPO_ROOT / str(entry["localPath"])
        if not local_path.is_file():
            result.findings.append(Finding(
                check="skill-provenance",
                path="skills-lock.json",
                line=0,
                category="lockfile_points_to_missing_shared_skill",
                level=level,
                suggestion=(
                    f"skills-lock.json lists vendored skill '{name}' at "
                    f"'{entry['localPath']}' but it does not exist"
                ),
            ))
            continue
        actual_blob = _git_blob_sha(local_path)
        if actual_blob != entry["localBlob"]:
            result.findings.append(Finding(
                check="skill-provenance",
                path=str(entry["localPath"]),
                line=0,
                category="local_blob_mismatch",
                level=level,
                suggestion=(
                    f"lockfile local blob is {entry['localBlob']} but current blob is {actual_blob}; "
                    "do not edit vendored community skill bodies without recording a patch decision"
                ),
            ))

        for support in entry.get("supportFiles", []):
            support_path = REPO_ROOT / str(support["localPath"])
            if not support_path.is_file():
                result.findings.append(Finding(
                    check="skill-provenance",
                    path="skills-lock.json",
                    line=0,
                    category="lockfile_points_to_missing_support_file",
                    level=level,
                    suggestion=(
                        f"skills-lock.json lists support file '{support['localPath']}' "
                        "but it does not exist"
                    ),
                ))
                continue
            actual_support_blob = _git_blob_sha(support_path)
            if actual_support_blob != support["localBlob"]:
                result.findings.append(Finding(
                    check="skill-provenance",
                    path=str(support["localPath"]),
                    line=0,
                    category="support_file_blob_mismatch",
                    level=level,
                    suggestion=(
                        f"lockfile local blob is {support['localBlob']} but current blob is {actual_support_blob}; "
                        "do not edit vendored community support files without recording a patch decision"
                    ),
                ))

    locked_names = set(lock_entries.keys())
    unclassified_names = shared_names - locked_names - project_owned
    if unclassified_names:
        vendored_rows = _parse_shared_vendored_snapshots(result)
        support_rows = [
            row
            for row in _parse_shared_support_file_snapshots(result)
            if row["skill"] in unclassified_names
        ]
    else:
        vendored_rows = {}
        support_rows = []

    for name in sorted(unclassified_names):
        skill_file = shared_root / name / "SKILL.md"
        rel = str(skill_file.relative_to(REPO_ROOT))

        row = vendored_rows.get(name)
        if row is None:
            result.findings.append(Finding(
                check="skill-provenance",
                path=rel,
                line=0,
                category="missing_provenance",
                level=level,
                suggestion=(
                    f"shared skill '{name}' must be in skills-lock.json, "
                    "checks.skill-provenance.project_owned, or skill-source-ledger.md"
                ),
            ))
            continue

        actual_blob = _git_blob_sha(skill_file)
        if actual_blob != row["local_blob"]:
            result.findings.append(Finding(
                check="skill-provenance",
                path=rel,
                line=0,
                category="local_blob_mismatch",
                level=level,
                suggestion=(
                    f"ledger local blob is {row['local_blob']} but current blob is {actual_blob}; "
                    "do not edit community skill bodies without recording a vendored patch decision"
                ),
                matched_text=f"ledger line {row['line']}",
            ))

    for name, row in sorted(vendored_rows.items()):
        skill_file = shared_root / name / "SKILL.md"
        if skill_file.is_file():
            continue
        result.findings.append(Finding(
            check="skill-provenance",
            path="docs/standards/skill-source-ledger.md",
            line=int(row["line"]),
            category="ledger_points_to_missing_shared_skill",
            level=level,
            suggestion=f"ledger lists '{name}' but .agents/skills/{name}/SKILL.md does not exist",
        ))

    for row in support_rows:
        local_path = REPO_ROOT / row["local_path"]
        if not local_path.is_file():
            result.findings.append(Finding(
                check="skill-provenance",
                path="docs/standards/skill-source-ledger.md",
                line=int(row["line"]),
                category="ledger_points_to_missing_support_file",
                level=level,
                suggestion=f"ledger lists support file '{row['local_path']}' but it does not exist",
            ))
            continue
        actual_blob = _git_blob_sha(local_path)
        if actual_blob != row["local_blob"]:
            result.findings.append(Finding(
                check="skill-provenance",
                path=row["local_path"],
                line=0,
                category="support_file_blob_mismatch",
                level=level,
                suggestion=(
                    f"ledger local blob is {row['local_blob']} but current blob is {actual_blob}; "
                    "do not edit vendored community support files without recording a patch decision"
                ),
                matched_text=f"ledger line {row['line']}",
            ))

    claude_only_rows = _parse_claude_only_skill_snapshots(result)
    claude_only_ledger_names = {row["skill"] for row in claude_only_rows}
    for name in sorted(claude_names - shared_names - project_owned - claude_only_ledger_names):
        result.findings.append(Finding(
            check="skill-provenance",
            path=f".claude/skills/{name}/SKILL.md",
            line=0,
            category="untracked_claude_only_skill",
            level=level,
            suggestion=(
                f"Claude-only skill '{name}' must be listed in skill-source-ledger.md "
                "or checks.skill-provenance.project_owned"
            ),
        ))

    for row in claude_only_rows:
        local_path = REPO_ROOT / row["local_path"]
        if not local_path.is_file():
            result.findings.append(Finding(
                check="skill-provenance",
                path="docs/standards/skill-source-ledger.md",
                line=int(row["line"]),
                category="ledger_points_to_missing_claude_skill",
                level=level,
                suggestion=f"ledger lists Claude-only skill '{row['local_path']}' but it does not exist",
            ))
            continue
        actual_blob = _git_blob_sha(local_path)
        if actual_blob != row["local_blob"]:
            result.findings.append(Finding(
                check="skill-provenance",
                path=row["local_path"],
                line=0,
                category="claude_only_blob_mismatch",
                level=level,
                suggestion=(
                    f"ledger local blob is {row['local_blob']} but current blob is {actual_blob}; "
                    "do not edit Claude-only community skill bodies without recording source status"
                ),
                matched_text=f"ledger line {row['line']}",
            ))

    return result


# ---------- frontmatter via subprocess ----------

def check_frontmatter_via_subprocess(policy: dict) -> CheckResult:
    """以 subprocess 调用 Scripts/validate_frontmatter.py，结果映射为 CheckResult。

    不在 CHECK_NAMES 中（不作为独立子命令），仅 `all` 子命令自动调用。
    """
    result = CheckResult(check="frontmatter", level="error")
    script = REPO_ROOT / "Scripts" / "validate_frontmatter.py"
    if not script.is_file():
        result.findings.append(Finding(
            check="frontmatter",
            path="Scripts/validate_frontmatter.py",
            line=0,
            category="missing_orchestrator_target",
            level="error",
            suggestion="Scripts/validate_frontmatter.py expected by docaudit all; restore it.",
        ))
        return result
    try:
        completed = subprocess.run(
            ["python3", str(script), "--check"],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        result.findings.append(Finding(
            check="frontmatter",
            path="Scripts/validate_frontmatter.py",
            line=0,
            category="orchestrator_invocation_failed",
            level="error",
            suggestion=f"failed to invoke validate_frontmatter.py: {exc}",
        ))
        return result
    if completed.returncode == 0:
        return result  # clean
    # 解析输出 — validate_frontmatter.py 打印 `path: message` 格式
    combined = (completed.stdout or "") + "\n" + (completed.stderr or "")
    for raw_line in combined.splitlines():
        s = raw_line.strip()
        if not s or s.lower().startswith(("found ", "no ", "ok", "passed")):
            continue
        if ":" in s:
            pth, _, msg = s.partition(":")
            result.findings.append(Finding(
                check="frontmatter",
                path=pth.strip() or "(unknown)",
                line=0,
                category="frontmatter_violation",
                level="error",
                suggestion=msg.strip(),
                matched_text=s[:200],
            ))
    if not result.findings:
        # 非零退出但无解析 finding — 报 generic 错
        result.findings.append(Finding(
            check="frontmatter",
            path="Scripts/validate_frontmatter.py",
            line=0,
            category="orchestrator_nonzero_exit",
            level="error",
            suggestion=f"validate_frontmatter.py exit={completed.returncode}; stdout/stderr captured below",
            matched_text=combined.strip()[:200],
        ))
    return result


# ---------- 报告输出 ----------

# ---------- check: verdict-sync ----------

# 匹配 "<N> <LABEL>" 或 "<LABEL> <N>"，<LABEL> 是 audit-rubric 标签
VERDICT_PATTERN = re.compile(
    r"(?:(\d+)\s+(VALID_WITH_GAP|VALID|NEEDS_REVISION|STALE_OR_INVALID|STALE|PENDING))"
    r"|(?:(VALID_WITH_GAP|VALID|NEEDS_REVISION|STALE_OR_INVALID|STALE|PENDING)\s+(\d+))"
)


_VERDICT_CONTEXT_KEYWORDS = ("Final 分布", "Final：", "Final 终态", "终态", "verdict distribution", "verdict 分布")


def check_verdict_sync(policy: dict) -> CheckResult:
    """检测 verdict 分布声明跨文件漂移。

    扫描指定文件中 'N VALID' / 'N NEEDS_REVISION' 等声明，
    **仅当所在行附近含 Final 分布 / 终态 关键词时**，同一标签在多个文件中
    出现不同数字 → 漂移 finding。避免误抓历史步骤数量。
    """
    conf = policy["checks"]["verdict-sync"]
    level = conf["level"]
    targets = conf.get("scan_paths", [
        "STATUS.md",
        "docs/memory/handoff.md",
        "docs/memory/decisions.md",
    ])
    result = CheckResult(check="verdict-sync", level=level)

    # label -> { N: [(file, line, raw_match), ...] }
    claims: dict[str, dict[str, list[tuple[str, int, str]]]] = {}

    for relpath in targets:
        fp = REPO_ROOT / relpath
        if not fp.is_file():
            continue
        for lineno, line in enumerate(_read_lines(fp), start=1):
            # 只在包含 "Final 分布 / 终态" 等关键词的行扫匹配
            if not any(kw in line for kw in _VERDICT_CONTEXT_KEYWORDS):
                continue
            for m in VERDICT_PATTERN.finditer(line):
                if m.group(1):
                    n, label = m.group(1), m.group(2)
                else:
                    label, n = m.group(3), m.group(4)
                claims.setdefault(label, {}).setdefault(n, []).append(
                    (relpath, lineno, m.group(0))
                )

    # 对每个标签：如果出现 ≥2 个 distinct 数字 → 漂移
    for label, by_n in sorted(claims.items()):
        if len(by_n) < 2:
            continue
        details_parts = []
        for n, locs in sorted(by_n.items(), key=lambda kv: int(kv[0])):
            files = sorted(set(f"{f}:{ln}" for f, ln, _ in locs))
            details_parts.append(f"{n} (in {', '.join(files)})")
        suggestion = (
            f"{label} 出现多个 distinct 数字: {' | '.join(details_parts)}; "
            "verdict artifact drift — 同步至 audit-ledger.tsv Final_Decision 实际分布"
        )
        # 把 finding 挂到第一个出现的文件
        first_file = sorted(by_n.values(), key=lambda v: v[0][1])[0][0]
        result.findings.append(Finding(
            check="verdict-sync",
            path=first_file[0],
            line=first_file[1],
            category="verdict_distribution_drift",
            level=level,
            suggestion=suggestion,
        ))
    return result


# ---------- check: external-gap-expiry ----------

# audit_note 标 VALID_WITH_GAP 的文件应有结构化字段
_GAP_REQUIRED_FIELDS = ("gap_type", "gap_due", "gap_owner")


def check_external_gap_expiry(policy: dict) -> CheckResult:
    """扫描 frontmatter audit_note 标 VALID_WITH_GAP 的文件，
    要求同时含 gap_type / gap_due / gap_owner 结构化字段。

    精确锚定：仅当 frontmatter（首个 `---` 块）中的 `audit_note:` 行
    含 `VALID_WITH_GAP` 才触发；避免误抓 body 中提及该标签的文件。
    """
    conf = policy["checks"]["external-gap-expiry"]
    level = conf["level"]
    result = CheckResult(check="external-gap-expiry", level=level)

    for path in _iter_text_files(policy, extensions=(".md",)):
        rel = path.relative_to(REPO_ROOT)
        rel_str = str(rel)
        lines = _read_lines(path)
        if not lines or lines[0].strip() != "---":
            continue
        # 提取 frontmatter 块（首个 --- 到下一个 ---）
        fm_end = None
        for i, ln in enumerate(lines[1:], start=1):
            if ln.strip() == "---":
                fm_end = i
                break
        if fm_end is None:
            continue
        fm_block = "\n".join(lines[1:fm_end])

        # 必须在 audit_note 行有 VALID_WITH_GAP
        gap_in_audit_note = any(
            "audit_note" in ln and "VALID_WITH_GAP" in ln
            for ln in fm_block.splitlines()
        )
        if not gap_in_audit_note:
            continue

        missing = [f for f in _GAP_REQUIRED_FIELDS if f not in fm_block]
        if missing:
            result.findings.append(Finding(
                check="external-gap-expiry",
                path=rel_str,
                line=0,
                category="unstructured_gap",
                level=level,
                suggestion=(
                    f"VALID_WITH_GAP 缺结构化字段 {missing}；"
                    "需在 frontmatter 加 gap_type / gap_due / gap_owner 以支持机械到期检查"
                ),
            ))
    return result


CHECK_FUNCS = {
    "links": check_links,
    "archived-refs": check_archived_refs,
    "orphans": check_orphans,
    "home-path-refs": check_home_path_refs,
    "rule-usage": check_rule_usage,
    "skill-inventory": check_skill_inventory,
    "skill-links": check_skill_links,
    "skill-provenance": check_skill_provenance,
    "verdict-sync": check_verdict_sync,
    "external-gap-expiry": check_external_gap_expiry,
}


def _write_tsv(results: list[CheckResult], tsv_dir: Path) -> None:
    tsv_dir.mkdir(parents=True, exist_ok=True)
    for r in results:
        path = tsv_dir / f"{r.check}.tsv"
        with path.open("w", encoding="utf-8") as fp:
            fp.write("check\tpath\tline\tcategory\tlevel\tstatus\tsuggestion\tsuppressed_reason\tmatched\n")
            for f in r.findings:
                fp.write(f.as_tsv() + "\n")


def _format_check_summary(r: CheckResult) -> str:
    parts = []
    if r.error_count:
        parts.append(f"{r.error_count} error")
    if r.warning_count:
        parts.append(f"{r.warning_count} warning")
    if r.info_count:
        parts.append(f"{r.info_count} info")
    if r.suppressed_count:
        parts.append(f"{r.suppressed_count} suppressed")
    return " / ".join(parts) if parts else "clean"


def _print_summary(
    results: list[CheckResult],
    verbose: bool,
    exit_code: int,
    strict: bool,
    stream_stdout,
    stream_stderr,
) -> None:
    cats_with_active = [r.check for r in results if r.active_findings]
    header = f"docaudit: {len(results)} checks, {len(cats_with_active)} categories with findings"
    print(header, file=stream_stdout)
    print(file=stream_stdout)

    has_signal = False
    for r in results:
        label = f"[{r.check}]".ljust(22)
        summary = _format_check_summary(r)
        line = f"{label} {summary}"
        print(line, file=stream_stdout)
        if r.error_count or r.warning_count:
            has_signal = True
            # 镜像 warning/error 摘要到 stderr（策略契约）
            print(line, file=stream_stderr)
        if verbose and r.findings:
            for f in r.findings[:20]:
                loc = f"{f.path}:{f.line}" if f.line else f.path
                status = "[SUPPRESSED]" if f.suppressed else ""
                tail = f" [{f.suppressed_reason}]" if f.suppressed else ""
                print(f"  · {loc}  [{f.category}]  {f.suggestion}{tail} {status}".rstrip(),
                      file=stream_stdout)
            if len(r.findings) > 20:
                print(f"  ... and {len(r.findings) - 20} more", file=stream_stdout)
    print(file=stream_stdout)

    error_checks = [r.check for r in results if r.error_count > 0]
    strict_checks = [r.check for r in results if r.warning_count > 0 and r.error_count == 0]
    if exit_code == 0:
        print("Exit: 0", file=stream_stdout)
    elif error_checks and (strict and strict_checks):
        print(f"Exit: {exit_code} (error: {error_checks}; strict-upgraded warning: {strict_checks})",
              file=stream_stdout)
    elif error_checks:
        print(f"Exit: {exit_code} (error level in: {error_checks})", file=stream_stdout)
    elif strict and strict_checks:
        print(f"Exit: {exit_code} (strict mode; warning level in: {strict_checks})", file=stream_stdout)
    else:
        print(f"Exit: {exit_code}", file=stream_stdout)

    # 非零退出也镜像 final line 到 stderr
    if exit_code != 0:
        print(f"docaudit exit {exit_code}", file=stream_stderr)


def _overall_exit_code(results: list[CheckResult], strict: bool) -> int:
    for r in results:
        if r.error_count > 0:
            return 1
        if strict and r.warning_count > 0:
            return 1
    return 0


# ---------- CLI ----------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="docaudit",
        description="SnapDrill knowledge base audit engine (Phase B).",
    )
    parser.add_argument(
        "--policy",
        type=Path,
        default=POLICY_PATH,
        help="Override policy.yaml path (default: Scripts/audit/policy.yaml)",
    )

    sub = parser.add_subparsers(dest="command", required=True, metavar="<subcommand>")

    def _add_common(sp: argparse.ArgumentParser) -> None:
        sp.add_argument("--strict", action="store_true", help="Treat warning as error (exit 1).")
        sp.add_argument("--report", action="store_true", help="Write TSV reports to reports/.")
        sp.add_argument("--baseline", action="store_true",
                        help="Apply legacy_whitelist finding-level suppression (Phase C 过渡).")
        sp.add_argument("--verbose", "-v", action="store_true", help="Print finding details.")

    all_parser = sub.add_parser(
        "all",
        help="Run 10 structural checks + frontmatter (11 checks total).",
        description="运行 10 个结构检查，并通过 subprocess 调用 validate_frontmatter.py（共 11 个检查）。",
        epilog="示例：python3 Scripts/audit/docaudit.py all --report --verbose",
    )
    _add_common(all_parser)

    for name in CHECK_NAMES:
        desc = CHECK_DESCRIPTIONS[name]
        sp = sub.add_parser(
            name,
            help=desc["help"],
            description=desc["description"],
            epilog=desc["epilog"],
        )
        _add_common(sp)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    policy = load_policy(args.policy)
    whitelist_rules = _parse_whitelist(policy)

    if args.command == "all":
        checks_to_run = CHECK_NAMES
        include_frontmatter = True
    else:
        checks_to_run = [args.command]
        include_frontmatter = False

    results: list[CheckResult] = []
    if include_frontmatter:
        try:
            results.append(check_frontmatter_via_subprocess(policy))
        except Exception as exc:  # noqa: BLE001
            print(f"ERROR: frontmatter orchestration crashed: {exc}", file=sys.stderr)
            return 2

    for name in checks_to_run:
        func = CHECK_FUNCS[name]
        try:
            results.append(func(policy))
        except Exception as exc:  # noqa: BLE001
            print(f"ERROR: check {name} crashed: {exc}", file=sys.stderr)
            return 2

    for r in results:
        _apply_whitelist(r, whitelist_rules, args.baseline)

    if args.report:
        tsv_dir = REPO_ROOT / policy.get("output", {}).get("tsv_dir", "reports")
        _write_tsv(results, tsv_dir)

    exit_code = _overall_exit_code(results, args.strict)
    _print_summary(
        results,
        args.verbose,
        exit_code,
        args.strict,
        stream_stdout=sys.stdout,
        stream_stderr=sys.stderr,
    )
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
