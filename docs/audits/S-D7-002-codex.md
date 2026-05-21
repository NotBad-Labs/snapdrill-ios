---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-002 Codex 独立修复提案

## 结论

F-005 不应继续依赖“PR Checklist 勾选”。当前 `.github/PULL_REQUEST_TEMPLATE.md:46-48` 只有自由文本 checklist，`.claude/hooks/premerge-checklist.sh:21-29` 只检查 `STATUS.md` 近 24h 更新，`.github/workflows/ci.yml` 没有 PR review trace 检查。建议新增一个可复用检查器，让 local pre-merge hook 和 CI 调同一套规则。

核心策略：

1. PR body 必须包含标准段头 `## F-005 Review Trace`。
2. 非豁免 PR 必须至少有 `Codex Review: PASS|PASS_WITH_FINDINGS`。
3. UI PR 额外要求 `Xcode Review: PASS|N/A`，不能空缺。
4. docs-only / trivial 只允许走“机器可读豁免”，不是静默跳过；豁免也必须留痕。
5. `gh pr merge` 前本地 hook 阻断；GitHub Actions PR check 阻断；direct push 到 develop/main 走 pre-push 与 push CI 等价路径。

## 7 项设计决策

| 决策点 | Codex 方案 |
|---|---|
| 强化路径 | 采用三层：PR template 标准化格式 + `Scripts/audit/pr_review_trace.py` 检查器 + `.claude/hooks/premerge-checklist.sh` 与 GitHub Actions 共同调用。Branch Protection 可作为仓库设置建议，但代码内可落地的是 hook + CI。 |
| 豁免条件设计 | 不允许“无留痕豁免”。docs-only / trivial 可豁免外部对抗 review，但必须在 `## F-005 Review Trace` 中写 `Review Exemption: docs-only|trivial`，并通过文件路径与 diff 规则验证。任何 Swift/source/config/CI/security 文件变更都不可豁免。 |
| 留痕格式标准化 | 固定 PR body 段头 `## F-005 Review Trace`，字段逐行解析，不接受自由格式关键词。模板字面文本见下方 PR Template patch。 |
| 检测时机 | merge 前阻断为主：`.claude` PreToolUse hook 拦 `gh pr merge`；CI pull_request job 阻断。merge 后回溯只作审计，不作为本修复主路径。 |
| 历史 PR 处理 | 不追溯修改历史 PR；但新增 `audit` mode 可抽样历史 PR 生成报告。历史违规作为基线证据，不阻塞后续 PR。 |
| 直推 develop 场景 | direct push 不豁免。现有 `Scripts/hooks/pre-push` 已拦 develop/main；若 `ALLOW_DIRECT_PUSH=1`，必须附加 `F005_DIRECT_PUSH_REVIEW_TRACE=...` 或 commit message trailer `F-005-Review-Trace:`，并在 push CI 对 `github.event_name == 'push'` 做告警/失败策略。 |
| 与 sprint-contract / cross-audit skill 联动 | `cross-audit` 完成 PR review 后输出可粘贴的 `F-005 Review Trace` block；`sprint-contract` closeout 增加“提交 PR 前写入 Review Trace 占位”的步骤。未来 S-D7-003 可复用同一个 Python 检查器框架，只新增 sprint contract policy module。 |

## 标准留痕格式

PR body 必须包含以下段头之一。

### 正常 review

```markdown
## F-005 Review Trace

Review Required: yes
Review Scope: full-pr
Codex Review: PASS
Codex Evidence: <PR comment URL or report path>
Gemini Review: N/A
Gemini Evidence: N/A
Xcode Review: N/A
Xcode Evidence: N/A
Findings Resolved: yes
Human Merge Approval: yes
```

字段语义：

- `Review Required`: `yes` 或 `exempt`
- `Review Scope`: `full-pr` / `docs-only` / `trivial`
- `Codex Review`: `PASS` / `PASS_WITH_FINDINGS` / `N/A`
- `Gemini Review`: `PASS` / `PASS_WITH_FINDINGS` / `N/A`
- `Xcode Review`: UI 改动必须 `PASS` 或 `PASS_WITH_FINDINGS`；非 UI 改动可 `N/A`
- `Evidence`: URL、repo path、或 `/tmp/...` 原始报告路径；禁止空字符串
- `Findings Resolved`: `yes` / `no` / `n/a`
- `Human Merge Approval`: `yes` / `no`

### 机器可读豁免

```markdown
## F-005 Review Trace

Review Required: exempt
Review Exemption: docs-only
Review Scope: docs-only
Changed Paths Checked: yes
Disallowed Paths Present: no
Exemption Rationale: docs-only typo/copy update; no code, config, workflow, hook, policy, or generated artifact changes.
Human Merge Approval: yes
```

允许豁免值：

- `docs-only`: 仅 `docs/**/*.md`，且不能改 `docs/workflow.md` F-rule 段、`docs/standards/**`、`docs/audits/**consensus*.md`、ADR 状态字段。
- `trivial`: 单文件 typo/comment/copy，不改行为、不改接口、不改测试、不改 CI/hook/config/policy。

绝不豁免：

- `Packages/**/*.swift`
- `SnapDrill/**/*.swift`
- `SnapDrillShare/**/*.swift`
- `.github/**`
- `.claude/hooks/**`
- `.claude/skills/**`
- `Scripts/**`
- `*.xcodeproj/**`
- `*.xcconfig`
- `.swiftlint.yml`
- `Package.swift`
- `fastlane/**`
- 任何包含 `test`, `baseline`, `snapshot`, `policy`, `workflow`, `permission`, `audit` 的路径

## 实现方案

### 1. Policy 文件

新增 `.github/review-trace-policy.yml`：

```yaml
version: 1
required_section: "## F-005 Review Trace"

required_fields:
  - Review Required
  - Review Scope
  - Human Merge Approval

normal_review:
  review_required: "yes"
  required_fields:
    - Codex Review
    - Codex Evidence
    - Findings Resolved
  accepted_verdicts: ["PASS", "PASS_WITH_FINDINGS"]
  optional_review_fields:
    - Gemini Review
    - Xcode Review

ui_review:
  path_globs:
    - "Packages/SnapDrillFeatures/Sources/**/*.swift"
    - "Packages/SnapDrillUI/Sources/**/*.swift"
    - "SnapDrill/**/*.swift"
  required_fields:
    - Xcode Review
    - Xcode Evidence

exemptions:
  docs-only:
    allowed_globs:
      - "docs/**/*.md"
    denied_globs:
      - "docs/workflow.md"
      - "docs/standards/**"
      - "docs/audits/**consensus*.md"
      - "docs/decisions/ADR-*.md"
  trivial:
    max_files: 1
    allowed_globs:
      - "docs/**/*.md"
      - "*.md"
    denied_globs:
      - "Packages/**"
      - "SnapDrill/**"
      - ".github/**"
      - ".claude/**"
      - "Scripts/**"
      - "*.xcodeproj/**"
      - "*.xcconfig"
      - ".swiftlint.yml"
      - "Package.swift"
      - "fastlane/**"
```

### 2. 检查脚本

新增 `Scripts/audit/pr_review_trace.py`：

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
import sys
from pathlib import Path

import yaml


SECTION_RE = re.compile(r"^## F-005 Review Trace\s*$", re.M)
FIELD_RE = re.compile(r"^([A-Za-z][A-Za-z -]+):\s*(.*?)\s*$")


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True).strip()


def pr_body(pr: str) -> str:
    return run(["gh", "pr", "view", pr, "--json", "body", "--jq", ".body // \"\""])


def changed_paths(pr: str) -> list[str]:
    out = run(["gh", "pr", "diff", pr, "--name-only"])
    return [line.strip() for line in out.splitlines() if line.strip()]


def parse_trace(body: str) -> dict[str, str]:
    match = SECTION_RE.search(body)
    if not match:
        raise ValueError("missing required section: ## F-005 Review Trace")
    block = body[match.end():]
    next_heading = re.search(r"^##\s+", block, re.M)
    if next_heading:
        block = block[:next_heading.start()]
    fields: dict[str, str] = {}
    for line in block.splitlines():
        m = FIELD_RE.match(line.strip())
        if m:
            fields[m.group(1)] = m.group(2)
    return fields


def matches_any(path: str, globs: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in globs)


def validate_exemption(fields: dict[str, str], paths: list[str], policy: dict) -> list[str]:
    errors: list[str] = []
    exemption = fields.get("Review Exemption", "")
    rule = policy["exemptions"].get(exemption)
    if not rule:
        return [f"unknown Review Exemption: {exemption!r}"]
    denied = [p for p in paths if matches_any(p, rule.get("denied_globs", []))]
    allowed = [p for p in paths if matches_any(p, rule.get("allowed_globs", []))]
    if denied:
        errors.append("review exemption denied for paths: " + ", ".join(denied))
    if len(allowed) != len(paths):
        errors.append("review exemption has non-allowed paths: " + ", ".join(sorted(set(paths) - set(allowed))))
    if "max_files" in rule and len(paths) > int(rule["max_files"]):
        errors.append(f"review exemption {exemption} allows max_files={rule['max_files']}, got {len(paths)}")
    for key in ("Changed Paths Checked", "Disallowed Paths Present", "Exemption Rationale", "Human Merge Approval"):
        if not fields.get(key):
            errors.append(f"missing exemption field: {key}")
    if fields.get("Disallowed Paths Present", "").lower() != "no":
        errors.append("Disallowed Paths Present must be no")
    return errors


def validate_normal(fields: dict[str, str], paths: list[str], policy: dict) -> list[str]:
    errors: list[str] = []
    normal = policy["normal_review"]
    for key in normal["required_fields"]:
        if not fields.get(key):
            errors.append(f"missing review field: {key}")
    verdict = fields.get("Codex Review", "")
    if verdict not in normal["accepted_verdicts"]:
        errors.append("Codex Review must be PASS or PASS_WITH_FINDINGS")
    if fields.get("Codex Evidence", "") in {"", "N/A"}:
        errors.append("Codex Evidence must point to a PR comment URL or report path")
    if fields.get("Findings Resolved", "").lower() != "yes":
        errors.append("Findings Resolved must be yes")
    if fields.get("Human Merge Approval", "").lower() != "yes":
        errors.append("Human Merge Approval must be yes")
    ui_paths = [p for p in paths if matches_any(p, policy["ui_review"]["path_globs"])]
    if ui_paths:
        for key in policy["ui_review"]["required_fields"]:
            if not fields.get(key) or fields.get(key) == "N/A":
                errors.append(f"UI-impacting PR requires {key}; UI paths: {', '.join(ui_paths)}")
    return errors


def validate(pr: str, policy_path: Path) -> list[str]:
    policy = yaml.safe_load(policy_path.read_text())
    fields = parse_trace(pr_body(pr))
    paths = changed_paths(pr)
    for key in policy["required_fields"]:
        if not fields.get(key):
            return [f"missing required field: {key}"]
    required = fields.get("Review Required", "").lower()
    if required == "exempt":
        return validate_exemption(fields, paths, policy)
    if required == "yes":
        return validate_normal(fields, paths, policy)
    return ["Review Required must be yes or exempt"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr", required=True)
    parser.add_argument("--policy", default=".github/review-trace-policy.yml")
    args = parser.parse_args()
    try:
        errors = validate(args.pr, Path(args.policy))
    except Exception as exc:
        errors = [str(exc)]
    if errors:
        print("F-005 review trace check failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        print("Add a standard ## F-005 Review Trace block to the PR body.", file=sys.stderr)
        return 1
    print("F-005 review trace check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

### 3. Pre-merge hook

修改 `.claude/hooks/premerge-checklist.sh`，在原 `STATUS.md` 检查后增加 PR 号解析和 review trace 检查：

```diff
@@
 if [[ -z "$LAST_STATUS_COMMIT" ]]; then
@@
 fi
+
+PR_NUMBER=$(echo "$COMMAND" | grep -oE 'gh pr merge[[:space:]]+[0-9]+' | awk '{print $NF}')
+if [[ -z "$PR_NUMBER" ]]; then
+    PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null || true)
+fi
+
+if [[ -z "$PR_NUMBER" ]]; then
+    echo "F-005 pre-merge: cannot determine PR number. Use 'gh pr merge <number>'." >&2
+    exit 2
+fi
+
+python3 Scripts/audit/pr_review_trace.py --pr "$PR_NUMBER" || exit 2
 
 exit 0
```

Override 机制：不建议复用 `CLAUDE_HOOK_ALLOW_DANGEROUS`。若必须紧急合并，使用单独变量：

```bash
F005_REVIEW_TRACE_OVERRIDE=1 gh pr merge <number>
```

但 override 只允许在脚本输出中要求用户同步补 PR body：

```bash
if [[ "${F005_REVIEW_TRACE_OVERRIDE:-0}" = "1" ]]; then
  echo "F-005 override used; PR body must be patched with Review Trace before next merge." >&2
  exit 0
fi
```

### 4. GitHub Actions CI

新增 `review-trace` job 到 `.github/workflows/ci.yml`：

```yaml
  review-trace:
    name: F-005 Review Trace
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
      pull-requests: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install PyYAML
        run: python3 -m pip install --quiet pyyaml
      - name: Check F-005 review trace
        env:
          GH_TOKEN: ${{ github.token }}
        run: python3 Scripts/audit/pr_review_trace.py --pr "${{ github.event.pull_request.number }}"
```

Direct push push-event 补充 job：

```yaml
  direct-push-review-trace:
    name: F-005 Direct Push Trace
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 20
      - name: Reject direct push without review trailer
        run: |
          if git log -1 --pretty=%B | grep -q '^F-005-Review-Trace:'; then
            exit 0
          fi
          echo "::error::Direct push to protected branch requires commit trailer: F-005-Review-Trace: <reason/evidence>"
          exit 1
```

这不会削弱现有 `Scripts/hooks/pre-push`；它补上 `ALLOW_DIRECT_PUSH=1` 绕过本地 hook 后的远端 CI 检查。

### 5. PR Template

替换 `.github/PULL_REQUEST_TEMPLATE.md` 的 Review 段：

```markdown
### Review

<!-- F-005: Review 无留痕的 PR 不得合并。保留本段头，不要改名。 -->

## F-005 Review Trace

Review Required: yes
Review Scope: full-pr
Codex Review:
Codex Evidence:
Gemini Review: N/A
Gemini Evidence: N/A
Xcode Review: N/A
Xcode Evidence: N/A
Findings Resolved:
Human Merge Approval:

<!--
允许的 docs-only/trivial 机器可读豁免格式：

Review Required: exempt
Review Exemption: docs-only
Review Scope: docs-only
Changed Paths Checked: yes
Disallowed Paths Present: no
Exemption Rationale:
Human Merge Approval:

Swift/source/config/CI/hook/policy 变更不得使用豁免。
-->
```

### 6. Skill 改进

`cross-audit` skill 在完成标准后追加：

```markdown
## F-005 PR 留痕输出

PR review 场景必须在最终回复末尾输出可粘贴块：

## F-005 Review Trace

Review Required: yes
Review Scope: full-pr
Codex Review: PASS_WITH_FINDINGS
Codex Evidence: <PR comment URL or report path>
Gemini Review: N/A
Gemini Evidence: N/A
Xcode Review: N/A
Xcode Evidence: N/A
Findings Resolved: yes
Human Merge Approval: yes
```

`sprint-contract` skill 在 Step 5 后追加 closeout 提醒：

```markdown
### Step 6：PR body Review Trace 占位

创建 PR 时必须保留 `## F-005 Review Trace` 段。开工前可留空；merge 前必须由 cross-audit 输出填充。docs-only/trivial 只能使用机器可读 exemption block。
```

## 测试用例

新增 `Scripts/audit/tests/test_pr_review_trace.py`。核心测试不需要访问 GitHub，可直接测试 `parse_trace` 和 `validate_*`，再用 monkeypatch 替换 `pr_body` / `changed_paths`。

```python
from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

import yaml

from Scripts.audit import pr_review_trace


POLICY = {
    "required_fields": ["Review Required", "Review Scope", "Human Merge Approval"],
    "normal_review": {
        "required_fields": ["Codex Review", "Codex Evidence", "Findings Resolved"],
        "accepted_verdicts": ["PASS", "PASS_WITH_FINDINGS"],
    },
    "ui_review": {
        "path_globs": ["Packages/SnapDrillFeatures/Sources/**/*.swift"],
        "required_fields": ["Xcode Review", "Xcode Evidence"],
    },
    "exemptions": {
        "docs-only": {
            "allowed_globs": ["docs/**/*.md"],
            "denied_globs": ["docs/workflow.md", "docs/standards/**"],
        }
    },
}


class ReviewTraceTests(TestCase):
    def write_policy(self, tmp: Path) -> Path:
        path = tmp / "policy.yml"
        path.write_text(yaml.safe_dump(POLICY), encoding="utf-8")
        return path

    def test_pr_without_review_trace_is_rejected(self):
        body = "## Summary\nNo review trace\n"
        with patch.object(pr_review_trace, "pr_body", return_value=body), \
             patch.object(pr_review_trace, "changed_paths", return_value=["Packages/Foo.swift"]):
            errors = pr_review_trace.validate("1", self.write_policy(Path(self.tmpdir)))
        self.assertIn("missing required section", errors[0])

    def test_docs_only_exemption_is_allowed(self):
        body = """## F-005 Review Trace
Review Required: exempt
Review Exemption: docs-only
Review Scope: docs-only
Changed Paths Checked: yes
Disallowed Paths Present: no
Exemption Rationale: docs typo only
Human Merge Approval: yes
"""
        with patch.object(pr_review_trace, "pr_body", return_value=body), \
             patch.object(pr_review_trace, "changed_paths", return_value=["docs/product/foo.md"]):
            errors = pr_review_trace.validate("1", self.write_policy(Path(self.tmpdir)))
        self.assertEqual(errors, [])

    def test_non_standard_review_format_is_rejected(self):
        body = """## F-005 Review Trace
Review Required: yes
Review Scope: full-pr
Codex Review: LGTM
Codex Evidence: looked locally
Findings Resolved: yes
Human Merge Approval: yes
"""
        with patch.object(pr_review_trace, "pr_body", return_value=body), \
             patch.object(pr_review_trace, "changed_paths", return_value=["Packages/Foo.swift"]):
            errors = pr_review_trace.validate("1", self.write_policy(Path(self.tmpdir)))
        self.assertTrue(any("Codex Review must be PASS" in e for e in errors))

    def test_ui_pr_requires_xcode_review(self):
        body = """## F-005 Review Trace
Review Required: yes
Review Scope: full-pr
Codex Review: PASS
Codex Evidence: https://github.com/org/repo/pull/1#issuecomment-1
Xcode Review: N/A
Xcode Evidence: N/A
Findings Resolved: yes
Human Merge Approval: yes
"""
        with patch.object(pr_review_trace, "pr_body", return_value=body), \
             patch.object(pr_review_trace, "changed_paths", return_value=["Packages/SnapDrillFeatures/Sources/Foo.swift"]):
            errors = pr_review_trace.validate("1", self.write_policy(Path(self.tmpdir)))
        self.assertTrue(any("UI-impacting PR requires Xcode Review" in e for e in errors))
```

Direct push shell test can be a small bats-style or Python subprocess test:

```python
def test_direct_push_commit_without_f005_trailer_fails():
    message = "status: emergency update\n\n"
    assert "F-005-Review-Trace:" not in message
    # CI step should exit 1 for this message.
```

## 与现有 hook 不冲突说明

- `block-dangerous-bash.sh` 继续负责危险命令分类，不参与 PR body 语义。
- `premerge-checklist.sh` 已经拦 `gh pr merge`，最小改动是在同一拦截点追加 `pr_review_trace.py`，不会新增另一个 Bash hook matcher。
- `Scripts/hooks/pre-push` 继续禁止 direct push；本方案只在 override 之后用 CI trailer 兜底。
- `docaudit-preflight.sh` 不变；F-005 review trace 属 PR governance，不塞进 docaudit。

## 已知盲区

1. 用户仍可用 GitHub Web UI 合并绕过本地 `.claude` hook；所以 CI job 必须作为 required check 配合仓库 branch protection。若 private/free 仓库无法强制 required check，本地 hook 只能软约束。
2. `ALLOW_DIRECT_PUSH=1` 仍可绕过本地 pre-push。远端 push CI 能失败，但失败发生在 push 后，不能阻止 commit 已进入远端分支；需要管理纪律限制该变量使用。
3. 假阳性：已有合规 review 但未按 `## F-005 Review Trace` 格式写，会被拒。这个成本是有意的，用固定格式换机械可审计。
4. 假阴性：脚本验证 Evidence 非空，但不能证明 URL 内容真的是高质量 review。质量仍需 cross-audit / human review 抽检。
5. docs-only 豁免依赖 path globs。重命名或 generated docs 可能误判，需要 policy 文件维护。
6. GitHub CLI / API 输出字段变化会影响 hook；CI 中应固定 `gh` 版本或用 GitHub REST API fallback。
7. GitHub Enterprise 如果禁用 `gh pr diff --name-only` 或权限不足，检查器需要改成用 `github.event.pull_request.changed_files` / REST files endpoint。
8. S-D7-003 预期可共享 `Scripts/audit/pr_governance_check.py` 框架，把 review trace 与 sprint contract trace 做成两个 policy module；本方案先保持 `pr_review_trace.py` 单职责，避免提前耦合。
