#!/usr/bin/env python3
"""F-018 Sprint Contract Gate（S-D7-003 共识落地，Phase 11 收官）。

字段化 contract schema（Codex 设计）+ Scope Creep 实时防御（Antigravity 设计融合）。

使用方式：
    # PreToolUse Edit hook 模式（hook 内调用）
    python3 Scripts/audit/sprint_contract_gate.py --file-path Packages/Foo.swift

    # 测试模式（提供 paths-file 跳过 git 推导）
    python3 Scripts/audit/sprint_contract_gate.py --paths-file /tmp/paths.txt

    # closeout 模式（PR merge 前 premerge-checklist.sh 调用）
    python3 Scripts/audit/sprint_contract_gate.py --check-closeout --issue 123

    # debug：打印推导的 Issue
    python3 Scripts/audit/sprint_contract_gate.py --derive-issue

Override（紧急）：
    F018_SPRINT_CONTRACT_OVERRIDE=1 python3 ... 跳过本次校验
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

# 复用 S-D7-002 落地的 glob / placeholder 工具
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from pr_review_trace import matches_any, is_placeholder  # noqa: E402

CONTRACT_SECTION_RE = re.compile(r"^##\s+Sprint\s+Contract\s*$", re.M | re.I)
CLOSEOUT_SECTION_RE = re.compile(r"^##\s+Sprint\s+Contract\s+Closeout\s*$", re.M | re.I)
# 字段解析：单行 `Key: value`
SINGLE_FIELD_RE = re.compile(r"^([A-Za-z][A-Za-z \-]+):\s*(.*?)\s*$")
# 多行 bullet 子项：`- value`
BULLET_RE = re.compile(r"^\s*[-*+]\s+(.+?)\s*$")


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def derive_issue(policy: dict) -> str | None:
    """推导关联 Issue: env > branch patterns > gh pr closingIssues."""
    detection = policy.get("issue_detection", {})

    # 1. env var
    env_name = detection.get("explicit_env", "SPRINT_CONTRACT_ISSUE")
    if env_value := os.environ.get(env_name):
        return env_value

    # 2. branch patterns
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if branch:
        for pattern in detection.get("branch_patterns", []):
            try:
                m = re.search(pattern, branch)
                if m and m.groupdict().get("number"):
                    return m.group("number")
            except re.error:
                continue

    # 3. PR closingIssuesReferences fallback
    if detection.get("pr_closing_issues_fallback"):
        pr_data = run(["gh", "pr", "view", "--json", "closingIssuesReferences"])
        if pr_data:
            try:
                refs = json.loads(pr_data).get("closingIssuesReferences", [])
                if refs:
                    return str(refs[0].get("number", ""))
            except (json.JSONDecodeError, ValueError):
                pass

    return None


def fetch_issue(issue_num: str) -> dict | None:
    """从 gh CLI 拉 Issue 数据。"""
    try:
        return json.loads(run([
            "gh", "issue", "view", issue_num,
            "--json", "labels,state,body,comments,title,url",
        ]))
    except (json.JSONDecodeError, ValueError):
        return None


def parse_contract(markdown: str) -> dict[str, list[str] | str]:
    """从含 `## Sprint Contract` 段的 markdown 提取字段。

    支持两种格式：
    - 单行 `Key: value`
    - 多行 `Key:\n- bullet1\n- bullet2`（值为 list）
    """
    match = CONTRACT_SECTION_RE.search(markdown)
    if not match:
        return {}
    block = markdown[match.end():]
    next_heading = re.search(r"^##\s+", block, re.M)
    if next_heading:
        block = block[:next_heading.start()]

    fields: dict[str, list[str] | str] = {}
    current_key: str | None = None
    current_bullets: list[str] = []

    def flush():
        nonlocal current_key, current_bullets
        if current_key is not None:
            if current_bullets:
                # 已有内容，转为 list 字段
                existing = fields.get(current_key)
                if existing == "":
                    fields[current_key] = list(current_bullets)
                else:
                    fields[current_key] = list(current_bullets)
        current_key = None
        current_bullets = []

    for raw_line in block.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            # 空行：清理当前 multi-line accumulator
            flush()
            continue

        # bullet 子项
        m_bullet = BULLET_RE.match(line)
        if m_bullet and current_key is not None and current_key.startswith(""):
            # 仅当 current_key 存在且其值为空字符串时，把 bullet 累计为该字段的 list
            current_bullets.append(m_bullet.group(1).strip())
            continue

        # 单行字段 `Key: value`
        m_single = SINGLE_FIELD_RE.match(line)
        if m_single:
            flush()  # 上一个字段如果还在累积，先 flush
            key = m_single.group(1).strip()
            value = m_single.group(2).strip()
            fields[key] = value
            current_key = key
            current_bullets = []

    flush()
    return fields


def field_to_list(value: list[str] | str) -> list[str]:
    """把字段值规范化为 list（支持单行 `a, b` 拆分）。"""
    if isinstance(value, list):
        return [v.strip() for v in value if v.strip()]
    if not value:
        return []
    # 单行字段可能含逗号 / 分号分隔
    parts = re.split(r"[,;\n`]+", value)
    return [p.strip() for p in parts if p.strip()]


def check_file_scope(file_path: str, contract: dict, policy: dict) -> list[str]:
    """Antigravity 设计的 Scope Creep 实时防御。

    检查 Edit 目标文件是否：
    1. 在 No-Touch 范围内 → 越界
    2. 在 Touches 范围外 → 越界（除非是 ignore_path_globs 流程文件）
    """
    errors: list[str] = []
    if not file_path:
        return errors

    # 标准化为相对路径
    try:
        rel_path = str(Path(file_path).resolve().relative_to(Path.cwd()))
    except ValueError:
        rel_path = file_path

    # 流程文件白名单（STATUS.md / .claude/state/** 等）始终放行
    ignore_globs = policy.get("ignore_path_globs", [])
    if matches_any(rel_path, ignore_globs):
        return errors

    # No-Touch 优先校验
    no_touch_list = field_to_list(contract.get("No-Touch", []))
    if no_touch_list and matches_any(rel_path, no_touch_list):
        errors.append(
            f"目标文件 {rel_path!r} 在契约 No-Touch 范围内: {no_touch_list}"
        )
        return errors  # No-Touch 阻断后不再检查 Touches

    # Touches 范围校验
    touches_list = field_to_list(contract.get("Touches", []))
    if touches_list and not matches_any(rel_path, touches_list):
        errors.append(
            f"目标文件 {rel_path!r} 不在契约 Touches 范围内: {touches_list}; "
            "若实属计划内，请先去 Issue 更新 contract Touches"
        )

    return errors


def validate_contract_fields(
    fields: dict[str, list[str] | str], appetite: str, policy: dict, paths: list[str]
) -> list[str]:
    """校验 contract 字段完整性 + placeholder 防御。"""
    errors: list[str] = []
    placeholders = policy.get("placeholder_patterns", [])

    contract_required = fields.get("Contract Required", "")
    if isinstance(contract_required, list):
        contract_required = contract_required[0] if contract_required else ""

    # exempt 路径
    if contract_required.lower() == "exempt":
        return validate_exemption_fields(fields, paths, policy)

    if contract_required.lower() != "yes":
        return [
            f"Contract Required must be 'yes' or 'exempt', got {contract_required!r}"
        ]

    # 普通契约：必填字段
    normal = policy.get("normal_contract", {})
    small_chore = policy.get("small_chore", {})
    is_small_chore = (
        appetite.lower() == small_chore.get("appetite", "small").lower()
        and (fields.get("Issue Type") or "").strip().lower() == small_chore.get("issue_type", "chore")
    )

    required = normal.get("required_fields", [])
    full_required = normal.get("full_required_fields", [])

    if is_small_chore:
        # Small chore 简化：only Touches / No-Touch / DoD Minimum
        required = small_chore.get("required_fields", [])
        full_required = []

    for key in policy.get("required_fields", []) + required + full_required:
        if key not in fields:
            errors.append(f"missing required field: {key}")
            continue
        value = fields[key]
        # 单行值占位符校验
        if isinstance(value, str):
            if is_placeholder(value, placeholders):
                errors.append(f"field {key!r} 是占位符或空: {value!r}")
        elif isinstance(value, list):
            if not value:
                errors.append(f"field {key!r} 是空 list（必须至少有 1 个 bullet）")
            else:
                for item in value:
                    if is_placeholder(item, placeholders):
                        errors.append(f"field {key!r} 列表项是占位符: {item!r}")
                        break

    # accepted values 校验
    issue_type_val = fields.get("Issue Type", "")
    if isinstance(issue_type_val, str) and issue_type_val:
        if issue_type_val not in normal.get("accepted_issue_types", []):
            errors.append(
                f"Issue Type must be in {normal.get('accepted_issue_types', [])}, "
                f"got {issue_type_val!r}"
            )

    status_val = fields.get("Status", "")
    if isinstance(status_val, str) and status_val:
        if status_val not in normal.get("accepted_status_values", []):
            errors.append(
                f"Status must be in {normal.get('accepted_status_values', [])}, "
                f"got {status_val!r}"
            )

    return errors


def validate_exemption_fields(
    fields: dict[str, list[str] | str], paths: list[str], policy: dict
) -> list[str]:
    """exempt 路径校验。"""
    errors: list[str] = []
    exemption = fields.get("Contract Exemption", "")
    if isinstance(exemption, list):
        exemption = exemption[0] if exemption else ""

    rule = policy.get("exemptions", {}).get(exemption)
    if not rule:
        return [f"unknown Contract Exemption: {exemption!r}"]

    denied = [p for p in paths if matches_any(p, rule.get("denied_globs", []))]
    if denied:
        errors.append(f"contract exemption denied for paths: {denied}")

    allowed = [p for p in paths if matches_any(p, rule.get("allowed_globs", []))]
    if len(allowed) != len(paths):
        non_allowed = sorted(set(paths) - set(allowed))
        errors.append(f"contract exemption has non-allowed paths: {non_allowed}")

    if "max_files" in rule and len(paths) > int(rule["max_files"]):
        errors.append(
            f"exemption {exemption} allows max_files={rule['max_files']}, got {len(paths)}"
        )

    for key in rule.get("required_fields", []):
        if not fields.get(key):
            errors.append(f"missing exemption field: {key}")

    return errors


def extract_appetite(fields: dict, issue_data: dict | None) -> str:
    """从 contract / Issue labels 推导 appetite。"""
    raw = fields.get("Appetite", "")
    if isinstance(raw, list):
        raw = raw[0] if raw else ""
    raw_lower = raw.strip().lower()
    if raw_lower in ("small", "medium", "large"):
        return raw_lower

    # fallback: from issue labels
    if issue_data:
        labels = {l["name"].lower() for l in issue_data.get("labels", [])}
        for level in ("small", "medium", "large"):
            if f"appetite:{level}" in labels or level in labels:
                return level

    return "medium"  # 默认 medium 严格校验


def is_path_protected(path: str, policy: dict) -> bool:
    """路径是否在 protected_edit_globs（触发 hook）。"""
    if matches_any(path, policy.get("ignore_path_globs", [])):
        return False
    if matches_any(path, policy.get("protected_edit_globs", [])):
        return True
    return False


def validate_edit(
    file_path: str | None,
    paths: list[str],
    policy: dict,
) -> tuple[int, list[str]]:
    """主入口：校验 Edit/Write 是否合规。

    Returns (exit_code, error_list).
    exit_code: 0 pass, 1 validation fail, 2 operational fail (network, no Issue等)
    """
    # 路径保护检查
    relevant_paths = [p for p in paths if is_path_protected(p, policy)]
    if not relevant_paths and file_path and not is_path_protected(file_path, policy):
        return 0, []  # 不在 protected 范围，放行

    paths_to_check = relevant_paths or ([file_path] if file_path else paths)

    # 推导 Issue
    issue_num = derive_issue(policy)
    if not issue_num:
        return 2, [
            "No associated Issue（env/branch/PR closingIssues 都未推导出 Issue ref）",
            "protected path edit 必须关联 Issue 并贴 ## Sprint Contract comment",
            f"或临时设 {policy.get('issue_detection', {}).get('explicit_env', 'SPRINT_CONTRACT_ISSUE')}=<num>",
        ]

    # 拉取 Issue
    issue_data = fetch_issue(issue_num)
    if issue_data is None:
        return 2, [
            f"无法获取 Issue #{issue_num}（gh CLI 失败 / 网络故障）",
            "Override: F018_SPRINT_CONTRACT_OVERRIDE=1 <command> 紧急跳过",
        ]

    # label 豁免
    labels = {l["name"].lower() for l in issue_data.get("labels", [])}
    exempt_labels = {l.lower() for l in policy.get("issue_detection", {}).get("exempt_labels", [])}
    if labels & exempt_labels:
        return 0, []

    # 查找 contract
    body = issue_data.get("body") or ""
    comments = issue_data.get("comments", [])

    # 逆序查找最近的 `## Sprint Contract` comment
    contract_body = ""
    for comment in reversed(comments):
        c_body = comment.get("body", "")
        if CONTRACT_SECTION_RE.search(c_body):
            contract_body = c_body
            break
    if not contract_body and CONTRACT_SECTION_RE.search(body):
        contract_body = body

    if not contract_body:
        return 1, [
            f"Issue #{issue_num} 缺 `## Sprint Contract` comment",
            "在 Issue 贴 contract: gh issue comment <num> --body \"## Sprint Contract\\n\\n...\"",
            "模板见 .claude/skills/sprint-contract/SKILL.md",
        ]

    fields = parse_contract(contract_body)
    appetite = extract_appetite(fields, issue_data)
    field_errors = validate_contract_fields(fields, appetite, policy, paths_to_check)
    if field_errors:
        return 1, [f"Issue #{issue_num} contract: {e}" for e in field_errors]

    # Scope Creep 实时防御
    for path in paths_to_check:
        scope_errors = check_file_scope(path, fields, policy)
        if scope_errors:
            return 1, scope_errors

    return 0, []


def validate_closeout(issue_num: str, policy: dict) -> list[str]:
    issue_data = fetch_issue(issue_num)
    if issue_data is None:
        return [f"无法获取 Issue #{issue_num}（gh CLI 失败）"]

    body = issue_data.get("body") or ""
    comments_text = "\n".join(c.get("body", "") for c in issue_data.get("comments", []))
    haystack = body + "\n" + comments_text

    closeout = policy.get("closeout", {})
    section_re = re.compile(
        r"^##\s+" + re.escape(closeout.get("required_section", "Sprint Contract Closeout").lstrip("# ").strip()) + r"\s*$",
        re.M | re.I,
    )
    if not section_re.search(haystack):
        return [
            f"Issue #{issue_num} 缺 closeout 段 `{closeout.get('required_section', '## Sprint Contract Closeout')}`",
        ]

    errors: list[str] = []
    placeholders = policy.get("placeholder_patterns", [])
    for kw in closeout.get("required_fields", []):
        m = re.search(rf"{re.escape(kw)}\s*[:：]\s*(.+?)(?:\n|$)", haystack)
        if not m:
            errors.append(f"closeout 缺关键字 {kw!r}")
            continue
        value = m.group(1).strip()
        if is_placeholder(value, placeholders):
            errors.append(f"closeout {kw!r} 是占位符: {value!r}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="F-018 Sprint Contract Gate")
    parser.add_argument("--file-path", help="Single file path (from Claude hook)")
    parser.add_argument("--paths-file", help="Read paths from file (one per line)")
    parser.add_argument("--issue", help="Override derived Issue number")
    parser.add_argument("--check-closeout", action="store_true", help="Check `## Sprint Contract Closeout` instead")
    parser.add_argument("--derive-issue", action="store_true", help="Debug: print derived issue and exit")
    parser.add_argument("--policy", default=".github/sprint-contract-policy.yml")
    args = parser.parse_args()

    override_env = os.environ.get("F018_SPRINT_CONTRACT_OVERRIDE")
    if override_env == "1":
        print(
            "⚠️  F018_SPRINT_CONTRACT_OVERRIDE=1 — bypassing F-018 sprint contract gate.",
            file=sys.stderr,
        )
        print(
            "    A Sprint Contract or machine-readable exemption MUST be added before commit/PR.",
            file=sys.stderr,
        )
        return 0

    policy_path = Path(args.policy)
    if not policy_path.exists():
        print(f"policy file not found: {policy_path}", file=sys.stderr)
        return 2
    policy = yaml.safe_load(policy_path.read_text(encoding="utf-8"))

    if args.derive_issue:
        result = derive_issue(policy)
        print(result or "")
        return 0 if result else 1

    if args.check_closeout:
        issue_num = args.issue or derive_issue(policy)
        if not issue_num:
            print("无法关联 Issue for closeout check", file=sys.stderr)
            return 1
        errors = validate_closeout(issue_num, policy)
        if errors:
            print(f"F-018 Sprint Contract Closeout check FAILED for Issue #{issue_num}:", file=sys.stderr)
            for e in errors:
                print(f"  - {e}", file=sys.stderr)
            return 1
        print(f"F-018 Sprint Contract Closeout check PASSED for Issue #{issue_num}")
        return 0

    # Edit gate 主路径
    paths: list[str] = []
    if args.paths_file:
        paths = [
            line.strip()
            for line in Path(args.paths_file).read_text().splitlines()
            if line.strip()
        ]
    file_path = args.file_path

    exit_code, errors = validate_edit(file_path, paths, policy)
    if exit_code != 0:
        print("F-018 Sprint Contract gate FAILED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print("", file=sys.stderr)
        print("Override: F018_SPRINT_CONTRACT_OVERRIDE=1 <command>", file=sys.stderr)
        return exit_code
    print("F-018 Sprint Contract gate PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
