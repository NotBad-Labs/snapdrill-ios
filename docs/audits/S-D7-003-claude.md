---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-003 修复提案 — Claude CLI 独立产出（v2，对齐 S-D7-002 已落地框架）

> Phase 11 B 方案串行第三战（**F-018 Sprint Contract 机械拦截**）。
> 本提案 v2 在 S-D7-002 落地后重写，命名约定 / 实现模式与 `Scripts/audit/pr_review_trace.py` + `.github/review-trace-policy.yml` 对齐。
> 全程未读 codex / antigravity 的 S-D7-003 产出。
>
> v1 历史：commit `aa2961a8`（命名约定基于空想）。本 v2 取代之，未删除 v1 commit 以保留 audit trail。

## 1. Bug 复现与根因

### 1.1 三态漂移（与 v1 一致）

- **dead-on-paper**：`docs/memory/feedback.md` F-018 + `docs/workflow.md` §编码前契约 完整声明
- **alive-in-skill**：`.claude/skills/sprint-contract/SKILL.md` 含触发条件 + 工作流（**S-D7-002 已加 Step 6** PR body Review Trace 占位）
- **not-applied-in-practice**：抽样 9 Issue (#159/#137/#136/#31/#30/#735/#684/#718/#720) = **0 / 9 有 Sprint Contract comment**，仅 epic #766 有

### 1.2 根因（与 v1 一致）

`.claude/skills/sprint-contract/SKILL.md` 是「主动触发」模式——Claude 自觉调用。无机械拦截 → Claude 漏调 → 直接 Edit 代码不被阻断。

### 1.3 v1 → v2 的差异

S-D7-002 已落地 `Scripts/audit/pr_review_trace.py` + `.github/review-trace-policy.yml` + `.claude/hooks/premerge-checklist.sh` 字段化框架。v1 提案中虚构的命名（`Scripts/hooks/check-sprint-contract.py` / `.claude/hooks/sprint-contract-policy.yaml`）已废弃，v2 全部对齐实际框架。

## 2. 7 项设计决策必答

### D1. 拦截位置

**选择**：**Claude PreToolUse Edit hook**（与 v1 一致）。

理由：
- Edit / Write 是「动代码」的最早信号——比 commit / push / merge 时拦截更早
- 与 `.claude/hooks/swift-autolint.sh`（PostToolUse Edit）配对，共享 `.claude/hooks/_hook_common.sh` 基础设施
- `.claude/hooks/log-file-change.sh` 已有 PreToolUse Edit 接入，做参考

### D2. 拦截强度

**选择**：**渐进硬化**——首 3 次软警告（exit 0 + stderr），第 4 次起硬阻断（exit 2）。

理由：
- 一上来硬阻断会让本 finding 修复期间 Claude 自己被阻断（meta loop）
- 计数器 per-Issue 累计，存 `.claude/state/sprint-contract-warnings.json`
- 用户可显式 `SKIP_SPRINT_CONTRACT=1 <command>` 单次 override（与 S-D7-002 `F005_REVIEW_TRACE_OVERRIDE=1` 双 override 哲学一致）
- 注：S-D7-002 是 PR merge 时拦截属合并前最后防线，contract 是 Edit 前预防，单 override 即可

### D3. Issue 状态识别

**选择**：**多重 fallback**——分支名 → state file → commit msg `#NNN` ref。

推导顺序：

```
1. .claude/state/current-issue.json 含 issue 号 → 取之（手动 set/clear 优先级最高）
2. 当前分支匹配 fix/<num>-* / feat/<num>-* / chore/<num>-*  → Issue #<num>
3. 最近 commit msg `(#NNN)` / `Closes #NNN` / `#NNN`
4. 都没拿到 → 视为 ad-hoc edit，按 D7 规则
```

拿到 Issue 后：

```bash
gh issue view <num> --json labels,state,body,comments
```

判断：
- 若 labels 含豁免 label（`bug` / `trivial` / `no-contract` / `epic`）→ 豁免
- 若 body 或 comments 含 `## Sprint Contract` 段头 → 有 contract
- 若 labels 含 `appetite:small` + body/comments 含简化字段（Touches / No-Touch / DoD）→ 简化合规
- 都不满足 → 拦截

### D4. Appetite=Small 豁免

**选择**：**chore Small 简化为 3 项**（与 `docs/workflow.md:45` 现有 F-018 文字对齐 + sprint-contract skill §豁免段）：

```yaml
appetite_small_simplified:
  required_keywords:
    - "Touches"
    - "No-Touch"
    - "DoD"
```

bug_report 类 + trivial 单行 typo + epic 类走豁免 label 路径（不需要 contract）。

### D5. 历史 Issue 处理

**选择**：**不追溯**（与 S-D7-002 / v1 立场一致）。仅新 Edit 起机械化拦截。

### D6. 与 cross-audit / post-merge skill 联动

**选择**：**sprint-contract closeout 时联动 cross-audit**。

- sprint-contract skill 完成时（用户说「contract 完成」/「编码结束」）写 closeout comment 到 Issue
- closeout comment 含 `## Sprint Contract Closeout` 段
- `.claude/hooks/premerge-checklist.sh` 在 `gh pr merge` 时**额外校验** Issue 是否有 closeout（与 S-D7-002 review trace 校验并列，同一 hook 两个 check）
- post-merge skill 在 PR 合并后扫 Issue closeout 状态 → 加 `status:done` label

### D7. 直接 commit / 无 Issue 关联场景

**选择**：**ad-hoc edit 软警告 + commit msg 摘要约束**。

- 无关联 Issue 的 Edit/Write → hook 输出 stderr 软警告，不阻断
- commit msg 必须含 `Touches: ... / No-Touch: ... / DoD: ...` 三行摘要——由 **S-D7-002 已建立的 commit-msg-style trailer 体系扩展**（参考 `F-005-Review-Trace:` trailer 模式，新增 `Sprint-Contract:` trailer）
- commit-msg trailer 校验留作 follow-up（本任务 §盲区 列出）

## 3. 修复方案（框架对齐 S-D7-002）

### 3.1 Policy 文件 `.github/sprint-contract-policy.yml`

命名约定：`.github/<check-name>-policy.yml`（与 `review-trace-policy.yml` 同目录同模式）。

```yaml
# F-018 Sprint Contract 检测策略（S-D7-003 共识落地）
# 命名与 .github/review-trace-policy.yml (S-D7-002) 对齐
version: 1
required_section: "## Sprint Contract"

# Issue label 豁免清单
exempt_labels:
  - "bug"              # bug_report 类（scope 天然小）
  - "trivial"          # 单行 typo / 注释 / 日志
  - "no-contract"      # 显式豁免（chramboliao 手贴）
  - "epic"             # epic 类本身就是规划

# Appetite=Small 简化版规格
appetite_small:
  trigger_label: "appetite:small"
  required_keywords:
    - "Touches"
    - "No-Touch"
    - "DoD"

# 完整版 contract 必填字段（appetite >= medium）
full_contract:
  required_keywords:
    - "Touches"
    - "No-Touch"
    - "Interface Delta"
    - "Test Additions"
    - "DoD"

# Closeout 段（PR merge 前校验）
closeout:
  required_section: "## Sprint Contract Closeout"
  required_keywords:
    - "Touches"
    - "DoD"

# 占位符防御（与 review-trace-policy.yml 同正则集，S-D7-002 落地的 placeholder_patterns）
placeholder_patterns:
  - "^\\[填[写入]"
  - "^\\[fill[ \\-]?in"
  - "^tbd$"
  - "^TBD$"
  - "^TODO$"
  - "^placeholder$"
  - "^\\.\\.\\.+$"
  - "^x$"
  - "^xxx+$"

# 渐进硬化阈值（v1 一致）
warning_threshold: 3

# 触发 hook 时机的文件路径过滤
# 与 .claude/hooks/swift-autolint.sh 风格一致：仅源码 / 配置 / hook / skill 触发；docs/* 放行
trigger_path_globs:
  - "Packages/**/*.swift"
  - "SnapDrill/**/*.swift"
  - "SnapDrillShare/**/*.swift"
  - "*.xcconfig"
  - "Package.swift"
  - ".swiftlint.yml"
  - ".github/workflows/**/*.yml"
  - ".claude/hooks/**"
  - "Scripts/**"

# 路径豁免（docs / audit / 测试基线等不触发）
ignore_path_globs:
  - "docs/**"
  - "*.md"
  - "*.tsv"
  - "Scripts/audit/tests/**"
  - "**/__Snapshots__/**"
```

### 3.2 Python 校验器 `Scripts/audit/sprint_contract_check.py`

命名约定：`Scripts/audit/<check-name>.py`（与 `pr_review_trace.py` 同目录同模式）。

复用 S-D7-002 的 `_glob_to_regex` / `matches_any` / `is_placeholder` 工具——**建议未来抽到 `Scripts/audit/_common.py`**（本提案先在新文件 import 而非重复实现，避免维护两份 glob/placeholder 逻辑）。

```python
#!/usr/bin/env python3
"""F-018 Sprint Contract 校验器（S-D7-003 共识落地，框架对齐 pr_review_trace.py）。

使用方式：
    python3 Scripts/audit/sprint_contract_check.py --issue 735
    python3 Scripts/audit/sprint_contract_check.py --check-closeout --issue 735  # PR merge 前
    python3 Scripts/audit/sprint_contract_check.py --derive-issue  # debug 推导

Override（紧急）：
    SKIP_SPRINT_CONTRACT=1 python3 ... 跳过本次校验
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

# 复用 pr_review_trace 的 glob / placeholder 工具（避免重复实现）
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from pr_review_trace import matches_any, is_placeholder  # noqa: E402


CONTRACT_SECTION_RE = re.compile(r"^##\s+Sprint\s+Contract\s*$", re.M | re.I)
CLOSEOUT_SECTION_RE = re.compile(r"^##\s+Sprint\s+Contract\s+Closeout\s*$", re.M | re.I)


def derive_issue() -> str | None:
    """推导关联 Issue: state file > branch > commit msg ref."""
    # 1. state file
    state_file = HERE.parent.parent / ".claude" / "state" / "current-issue.json"
    if state_file.exists():
        try:
            data = json.loads(state_file.read_text(encoding="utf-8"))
            if data.get("issue"):
                return str(data["issue"])
        except Exception:
            pass
    # 2. branch name
    try:
        branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
        ).strip()
        m = re.match(r"(?:fix|feat|chore)/(\d+)", branch)
        if m:
            return m.group(1)
    except Exception:
        pass
    # 3. commit msg
    try:
        msg = subprocess.check_output(
            ["git", "log", "-1", "--format=%B"], text=True
        )
        m = re.search(r"#(\d+)", msg)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def fetch_issue(issue_num: str) -> dict | None:
    try:
        return json.loads(subprocess.check_output(
            ["gh", "issue", "view", issue_num, "--json", "labels,state,body,comments"],
            text=True,
        ))
    except subprocess.CalledProcessError:
        return None


def has_contract_section(haystack: str) -> bool:
    return bool(CONTRACT_SECTION_RE.search(haystack))


def has_closeout_section(haystack: str) -> bool:
    return bool(CLOSEOUT_SECTION_RE.search(haystack))


def check_simplified(haystack: str, required_keywords: list[str], placeholders: list[str]) -> list[str]:
    """Appetite=Small 简化版：检查关键字 + 占位符。"""
    errors = []
    for kw in required_keywords:
        # 行内 `Touches: ...` 模式
        m = re.search(rf"{re.escape(kw)}\s*:\s*(.+?)(?:\n|$)", haystack)
        if not m:
            errors.append(f"appetite:small simplified contract 缺关键字 {kw!r}")
            continue
        value = m.group(1).strip()
        if is_placeholder(value, placeholders):
            errors.append(f"{kw!r} 是占位符或空: {value!r}")
    return errors


def validate(issue_num: str, policy: dict, check_closeout: bool = False) -> list[str]:
    data = fetch_issue(issue_num)
    if data is None:
        return [f"无法获取 Issue #{issue_num}（gh 命令失败）"]

    labels = {l["name"] for l in data.get("labels", [])}

    # 豁免 label 优先级最高
    exempt_labels = set(policy.get("exempt_labels", []))
    if labels & exempt_labels:
        return []

    body = data.get("body") or ""
    comments = "\n".join(c.get("body", "") for c in data.get("comments", []))
    haystack = body + "\n" + comments

    # closeout 校验路径（PR merge 时）
    if check_closeout:
        closeout = policy.get("closeout", {})
        if not has_closeout_section(haystack):
            return [
                f"Issue #{issue_num} 缺 closeout 段 {closeout.get('required_section', '## Sprint Contract Closeout')!r}",
            ]
        return check_simplified(
            haystack,
            closeout.get("required_keywords", []),
            policy.get("placeholder_patterns", []),
        )

    # 普通 contract 校验（Edit 前）
    if not has_contract_section(haystack):
        return [
            f"Issue #{issue_num} 缺 `## Sprint Contract` 段",
            "参考 .github/sprint-contract-policy.yml + .claude/skills/sprint-contract/SKILL.md",
        ]

    # Appetite=Small 简化版
    appetite_small = policy.get("appetite_small", {})
    if appetite_small.get("trigger_label") in labels:
        return check_simplified(
            haystack,
            appetite_small.get("required_keywords", []),
            policy.get("placeholder_patterns", []),
        )

    # 完整版 contract
    full = policy.get("full_contract", {})
    return check_simplified(
        haystack,
        full.get("required_keywords", []),
        policy.get("placeholder_patterns", []),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--issue", help="Issue number (skip --derive-issue if given)")
    parser.add_argument("--derive-issue", action="store_true", help="Debug: print derived issue and exit")
    parser.add_argument("--check-closeout", action="store_true", help="Check `## Sprint Contract Closeout` instead of contract")
    parser.add_argument("--policy", default=".github/sprint-contract-policy.yml")
    args = parser.parse_args()

    if os.environ.get("SKIP_SPRINT_CONTRACT") == "1":
        print("⚠️  SKIP_SPRINT_CONTRACT=1 — bypassing F-018 sprint contract check.", file=sys.stderr)
        return 0

    if args.derive_issue:
        result = derive_issue()
        print(result or "")
        return 0 if result else 1

    issue_num = args.issue or derive_issue()
    if not issue_num:
        print("无法关联 Issue（分支名 / state file / commit msg 都未指向 Issue ref）", file=sys.stderr)
        print("ad-hoc edit 软警告：commit msg 必须含 Touches:/No-Touch:/DoD: 三行摘要", file=sys.stderr)
        return 0  # ad-hoc 不阻断

    policy_path = Path(args.policy)
    if not policy_path.exists():
        print(f"policy file not found: {policy_path}", file=sys.stderr)
        return 2
    policy = yaml.safe_load(policy_path.read_text(encoding="utf-8"))

    errors = validate(issue_num, policy, check_closeout=args.check_closeout)
    if errors:
        check_name = "Sprint Contract Closeout" if args.check_closeout else "Sprint Contract"
        print(f"F-018 {check_name} check FAILED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print("", file=sys.stderr)
        print("Override: SKIP_SPRINT_CONTRACT=1 <command>", file=sys.stderr)
        return 1
    print(f"F-018 sprint contract check PASSED for Issue #{issue_num}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

### 3.3 测试 `Scripts/audit/tests/test_sprint_contract_check.py`

模式对齐 `test_pr_review_trace.py`（unittest + monkeypatch）。

```python
"""Tests for sprint_contract_check.py (S-D7-003)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import sprint_contract_check  # noqa: E402


POLICY = {
    "exempt_labels": ["bug", "trivial", "no-contract", "epic"],
    "appetite_small": {
        "trigger_label": "appetite:small",
        "required_keywords": ["Touches", "No-Touch", "DoD"],
    },
    "full_contract": {
        "required_keywords": ["Touches", "No-Touch", "Interface Delta", "Test Additions", "DoD"],
    },
    "closeout": {
        "required_section": "## Sprint Contract Closeout",
        "required_keywords": ["Touches", "DoD"],
    },
    "placeholder_patterns": [r"^\[填[写入]", r"^TBD$", r"^placeholder$"],
}


class SprintContractTests(unittest.TestCase):

    def test_exempt_label_pass(self):
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [{"name": "bug"}], "state": "OPEN", "body": "", "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_check.fetch_issue = original

    def test_missing_contract_section_rejected(self):
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [], "state": "OPEN", "body": "无 Sprint Contract", "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY)
            self.assertTrue(any("缺 `## Sprint Contract` 段" in e for e in errors))
        finally:
            sprint_contract_check.fetch_issue = original

    def test_appetite_small_simplified_pass(self):
        body = """## Sprint Contract

Touches: Packages/Foo.swift
No-Touch: docs/
DoD: tests pass + swiftlint clean
"""
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [{"name": "appetite:small"}], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_check.fetch_issue = original

    def test_appetite_small_missing_keyword_rejected(self):
        body = """## Sprint Contract

Touches: Packages/Foo.swift
DoD: tests pass
"""
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [{"name": "appetite:small"}], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY)
            self.assertTrue(any("缺关键字 'No-Touch'" in e for e in errors))
        finally:
            sprint_contract_check.fetch_issue = original

    def test_placeholder_rejected(self):
        body = """## Sprint Contract

Touches: [填写]
No-Touch: docs/
DoD: TBD
"""
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [{"name": "appetite:small"}], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY)
            self.assertTrue(any("占位符" in e for e in errors))
        finally:
            sprint_contract_check.fetch_issue = original

    def test_closeout_missing_rejected(self):
        body = """## Sprint Contract

Touches: x
No-Touch: y
DoD: z
"""
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY, check_closeout=True)
            self.assertTrue(any("缺 closeout 段" in e for e in errors))
        finally:
            sprint_contract_check.fetch_issue = original

    def test_closeout_pass(self):
        body = """## Sprint Contract Closeout

Touches 实际: Packages/Foo.swift
DoD 自检: 全部完成
"""
        original = sprint_contract_check.fetch_issue
        sprint_contract_check.fetch_issue = lambda n: {
            "labels": [], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_check.validate("735", POLICY, check_closeout=True)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_check.fetch_issue = original


if __name__ == "__main__":
    unittest.main()
```

### 3.4 PreToolUse Edit hook `.claude/hooks/pre-edit-sprint-contract.sh`

```bash
#!/bin/bash
# PreToolUse (Edit/Write/MultiEdit): F-018 Sprint Contract 校验
# Override: SKIP_SPRINT_CONTRACT=1 <command>
# 渐进硬化：软警告 3 次后升级硬阻断（.claude/state/sprint-contract-warnings.json）

set -euo pipefail

if [[ "${SKIP_SPRINT_CONTRACT:-0}" == "1" ]]; then
    exit 0
fi

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 仅对 Edit / Write / MultiEdit 触发；NotebookEdit 同
case "$TOOL" in
    Edit|Write|MultiEdit|NotebookEdit) ;;
    *) exit 0 ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -z "$PROJECT_ROOT" ]] && exit 0
cd "$PROJECT_ROOT"

# 检查路径是否在触发清单内（policy.trigger_path_globs / ignore_path_globs）
# 简化处理：docs/* / *.md / *.tsv 放行；其他源码触发
case "$FILE" in
    */docs/*|*.md|*.tsv|*/Scripts/audit/tests/*|*/__Snapshots__/*|*audit-ledger-*)
        exit 0
        ;;
esac

# 推导 Issue
ISSUE=$(python3 Scripts/audit/sprint_contract_check.py --derive-issue 2>/dev/null || true)

if [[ -z "$ISSUE" ]]; then
    echo "⚠️  sprint-contract: 无关联 Issue 的 ad-hoc edit。" >&2
    echo "  commit msg 必须含 Touches/No-Touch/DoD 三行摘要。" >&2
    exit 0  # ad-hoc 软警告
fi

# 检查 contract
if python3 Scripts/audit/sprint_contract_check.py --issue "$ISSUE" 2>/dev/null; then
    exit 0  # contract 已存在 / 豁免 / 简化合规
fi

# 渐进硬化
STATE_DIR="$PROJECT_ROOT/.claude/state"
mkdir -p "$STATE_DIR"
WARN_FILE="$STATE_DIR/sprint-contract-warnings.json"

COUNT=$(python3 - "$ISSUE" "$WARN_FILE" <<'PY'
import json, os, sys
issue, warn_file = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(warn_file):
    try:
        data = json.load(open(warn_file))
    except Exception:
        pass
print(data.get(issue, 0))
PY
)

if [[ "$COUNT" -lt 3 ]]; then
    NEW=$((COUNT + 1))
    python3 - "$ISSUE" "$WARN_FILE" "$NEW" <<'PY'
import json, os, sys
issue, warn_file, new_count = sys.argv[1], sys.argv[2], int(sys.argv[3])
data = {}
if os.path.exists(warn_file):
    try:
        data = json.load(open(warn_file))
    except Exception:
        pass
data[issue] = new_count
json.dump(data, open(warn_file, "w"))
PY
    echo "⚠️  sprint-contract: Issue #$ISSUE 缺 Sprint Contract（软警告 $NEW/3）" >&2
    echo "  贴 Sprint Contract comment 到 Issue：gh issue comment $ISSUE --body \"## Sprint Contract\\n\\n...\"" >&2
    echo "  参考 .claude/skills/sprint-contract/SKILL.md" >&2
    echo "  3 次后升级硬阻断。Override: SKIP_SPRINT_CONTRACT=1 <command>" >&2
    exit 0
fi

echo "❌ sprint-contract: Issue #$ISSUE 缺 Sprint Contract（已软警告 3 次，升级硬阻断）" >&2
echo "  必须先贴 Sprint Contract 才能继续 Edit。" >&2
echo "  Override: SKIP_SPRINT_CONTRACT=1 <command>" >&2
exit 2
```

### 3.5 Hook 注册 `.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [
          {"type": "command", "command": "bash .claude/hooks/pre-edit-sprint-contract.sh"}
        ]
      }
    ]
  }
}
```

具体集成方式以现有 `settings.json` schema 为准（参考 `swift-autolint.sh` / `log-file-change.sh` 注册方式）。

### 3.6 `premerge-checklist.sh` 扩展（与 S-D7-002 共享 hook）

在 S-D7-002 已加的 F-005 校验段后追加 F-018 closeout 校验：

```diff
 # F-005 review trace 校验（S-D7-002）
 ...
+
+# F-018 sprint contract closeout 校验（S-D7-003）
+if [[ "${SKIP_SPRINT_CONTRACT:-0}" != "1" ]]; then
+    # 复用 S-D7-002 已推导的 PR_NUMBER
+    if [[ -n "${PR_NUMBER:-}" ]]; then
+        # 从 PR 关联的 Issue（gh pr view --json closingIssuesReferences）
+        LINKED_ISSUE=$(gh pr view "$PR_NUMBER" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number' 2>/dev/null || true)
+        if [[ -n "$LINKED_ISSUE" ]]; then
+            if ! python3 Scripts/audit/sprint_contract_check.py --issue "$LINKED_ISSUE" --check-closeout 2>&1; then
+                exit 2
+            fi
+        fi
+    fi
+fi
```

### 3.7 sprint-contract skill 增强

`.claude/skills/sprint-contract/SKILL.md` 加 §Closeout 段（与 S-D7-002 已加的 Step 6 互补）：

```markdown
## Closeout（编码结束时，PR merge 前必跑）

完成 Issue 编码后、提 PR merge 前，在 Issue 贴 Closeout comment：

\```
## Sprint Contract Closeout

- Touches 实际触动文件：<...>
- 偏离 Sprint Contract 的部分：<无 / 列出>
- Test Additions 实际增加：<...>
- DoD 自检：<勾选>
\```

`.claude/hooks/premerge-checklist.sh` 在 `gh pr merge` 时校验 closeout 存在且关键字非占位符（S-D7-003）。
```

### 3.8 CI 集成（与 S-D7-002 review-trace job 同 workflow）

`.github/workflows/ci.yml` 在 review-trace job 后追加：

```yaml
  sprint-contract-trace:
    name: F-018 Sprint Contract Trace
    runs-on: ubuntu-latest
    timeout-minutes: 3
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
      issues: read
      pull-requests: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: python3 -m pip install --quiet pyyaml
      - name: Check F-018 sprint contract closeout
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          LINKED=$(gh pr view "${{ github.event.pull_request.number }}" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number' 2>/dev/null || true)
          if [ -z "$LINKED" ]; then
            echo "PR not linked to an Issue; skipping F-018 closeout check (consider F-005-Review-Trace trailer)."
            exit 0
          fi
          python3 Scripts/audit/sprint_contract_check.py --issue "$LINKED" --check-closeout
```

`docs:` 单独的 self-test step 加 `test_sprint_contract_check`：

```diff
       - name: Run pr_review_trace self-test
         run: python3 -m unittest Scripts.audit.tests.test_pr_review_trace -v
+
+      - name: Run sprint_contract_check self-test
+        run: python3 -m unittest Scripts.audit.tests.test_sprint_contract_check -v
```

## 4. 测试场景（7 条）

| 场景 | 输入 | 期望 |
|---|---|---|
| T1 当前分支 `fix/735` 但 Issue #735 无 contract | Edit `Packages/.../Foo.swift` | exit 0 + 软警告（首次）|
| T2 软警告 3 次后第 4 次 | T1 重复 4 次 | 第 4 次 exit 2 |
| T3 Issue 有 contract section | Edit 任意文件 | exit 0 |
| T4 Issue 贴 `bug` label | Edit 文件 | exit 0（豁免）|
| T5 Issue 贴 `appetite:small` 但缺 `No-Touch` 关键字 | Edit | sprint_contract_check exit 1，hook 走渐进硬化路径 |
| T6 ad-hoc edit（无 Issue ref）| Edit | exit 0 + ad-hoc 软警告 |
| T7 PR merge 时 closeout 缺失 | `gh pr merge 123` | premerge-checklist 调 `--check-closeout` exit 2 阻断 |

测试用 `test_sprint_contract_check.py`（§3.3）覆盖 T3-T7 校验器逻辑；T1/T2 渐进硬化由 hook 集成测试覆盖（可手动验证）。

## 5. 与 S-D7-002 联动具体清单

| 共享要素 | 共用方式 |
|---|---|
| `matches_any` / `_glob_to_regex` | sprint_contract_check.py `from pr_review_trace import matches_any, is_placeholder` |
| `is_placeholder` placeholder 正则 | 复用 S-D7-002 落地的 `placeholder_patterns` 集合 |
| policy YAML 命名约定 | `.github/<check-name>-policy.yml`（review-trace + sprint-contract）|
| 校验器命名约定 | `Scripts/audit/<check-name>.py`（pr_review_trace + sprint_contract_check）|
| `premerge-checklist.sh` 集成点 | 同一 hook 串接 F-005 / F-007 / F-018 三个 check |
| CI workflow 模式 | review-trace job + sprint-contract-trace job 并列 |
| Override 哲学 | F005_REVIEW_TRACE_OVERRIDE / SKIP_SPRINT_CONTRACT 单独 override，不互相影响 |
| 未来重构方向 | 抽 `Scripts/audit/_common.py` 收纳 glob / placeholder / gh wrapper（**留给 follow-up，不在本任务范围**）|

## 6. 已知盲区（自检，7 条 future-proof 触发器）

| 盲区 | 处理 | 重审触发条件 |
|---|---|---|
| SKIP_SPRINT_CONTRACT=1 持续 override | 每次 override 写入 `.claude/session-log.txt`（已有 log-file-change.sh） | 滥用率高时 prompt 输入豁免理由 |
| Issue 有 `## Sprint Contract` 字眼但内容空 | placeholder defense 抓 `[填写]` 类；不抓「实质空白」 | 假阳性多时加字段级深度校验 |
| `gh` 网络失败 | sprint_contract_check.py exit 1 → hook 走渐进硬化路径，不阻断 | 离线模式 / VPN 切换时考虑本地缓存 |
| 分支名不规范 | derive_issue.py state_file > branch > commit 三 fallback；都没拿到走 ad-hoc | 团队扩大后统一分支命名规范 |
| Issue 在 Building 但 contract 贴在 PR body | check_sprint_contract.py 只查 Issue；PR body 走 S-D7-002 路径 | 工作流改成「PR 优先贴 contract」时扩展 |
| 同会话切换 Issue 触发计数器累计 | warnings.json 按 Issue key 累计；切换不重置 | 用户主动 reset 命令可加（follow-up）|
| `commit-msg trailer Sprint-Contract:` 验证 | 本任务不实现；S-D7-002 `F-005-Review-Trace:` trailer 已建立基础设施，follow-up 加 | trailer 滥用时启动 |

## 7. 不变性声明

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D7-003-claude.md`（v2 overwrite v1，commit msg 标明）
- ✅ 未触动 `.claude/` / `.github/` / `Scripts/` 任何可执行文件
- ✅ 未读 codex / antigravity 的 S-D7-003 产出
- ✅ 已读 S-D7-002 落地实际代码（公开主线，与外审 worktree 看到的等价基线）

## 8. 关联

- [任务定义书](S-D7-003-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- [S-D7-002-fix-consensus](S-D7-002-fix-consensus.md) **本提案 v2 复用其框架**
- `Scripts/audit/pr_review_trace.py` / `.github/review-trace-policy.yml` S-D7-002 实际落地框架
- `.claude/hooks/premerge-checklist.sh` 现有 hook（S-D7-002 已扩展 F-005 + 24h STATUS；本任务加 F-018 closeout）
- `.claude/skills/sprint-contract/SKILL.md` 现有 skill（S-D7-002 已加 Step 6；本任务加 §Closeout）
- `docs/memory/feedback.md` F-018
- `docs/workflow.md` §编码前契约
