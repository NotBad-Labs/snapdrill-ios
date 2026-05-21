---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# S-D7-003 Codex 独立修复提案：F-018 Sprint Contract 机械拦截

## 结论

当前 F-018 的事实约束存在于 `docs/workflow.md` §编码前契约、`.github/ISSUE_TEMPLATE/feature_request.md` / `chore.md` 的模板段，以及 `.claude/skills/sprint-contract/SKILL.md` 的工作流说明；但现有 `.claude/settings.json` 只在 `PreToolUse Bash` 挂载 dangerous/premerge/prepush/long-session/docaudit，`Edit|Write|MultiEdit` 只有 `PostToolUse` 的 log/swiftlint/docaudit-on-doc-edit。因此 F-018 现在无法在"动第一行代码前"阻断。

建议落地为与 S-D7-002 同构的治理门：独立 policy YAML + 独立 Python checker + Claude `PreToolUse(Edit|Write|MultiEdit)` hook + unittest；PR/CI 只做补充审计，不作为主拦截点。原因是 F-018 的触发点是编码前，不是 PR 合并前。

## 设计决策 7 项

| # | 决策点 | Codex 裁决 |
|---|---|---|
| 1 | 拦截位置 | 主拦截放在 Claude `PreToolUse` 的 `Edit|Write|MultiEdit`，hook 名建议 `.claude/hooks/pre-edit-sprint-contract.sh`。Bash/commit/PR 检查只能补漏，不能替代 Edit 前门禁。 |
| 2 | 拦截强度 | 默认硬阻断 `exit 2`。允许 `F018_SPRINT_CONTRACT_OVERRIDE=1` 紧急绕过，但必须 stderr 留痕，并建议只对一次工具调用生效。软警告不足以修复已观察到的 0/5、0/4 应用率问题。 |
| 3 | Issue 状态识别 | 三层识别：`SPRINT_CONTRACT_ISSUE=<number>` 显式指定优先；否则从当前 branch 名提取 `#123` / `issue-123` / `123-...`；再 fallback 到 `gh pr view --json closingIssuesReferences`。Issue 是否 Building 用 machine-readable label，如 `status:building` / `building`。不得只搜标题正文中的 Building 字样。 |
| 4 | Appetite=Small 豁免 | 不完全豁免。`chore + Appetite=Small` 走简化 contract，必须有 Touches / No-Touch / DoD 三条。`trivial` 可豁免，但必须 machine-readable，且仅限单文件、非行为、非接口、非测试、非配置、非治理语义改动。 |
| 5 | 历史 Issue 处理 | 不追溯阻断历史 Issue；但任何历史 Issue 一旦重新进入 Building 或被当前分支/环境变量绑定，就按当前规则检查。旧 Issue 可补一条 Sprint Contract comment 后立即解锁。 |
| 6 | 与 cross-audit / post-merge 联动 | F-018 只负责开工前 scope 契约；cross-audit 用 contract 做 scope fidelity 基准；post-merge 可抽样检查 contract 是否与最终 PR 漂移。不要让 sprint-contract 自动触发 cross-audit，否则会把开工门和审查门耦合得过重。 |
| 7 | 直接 commit / 无 Issue 场景 | 修改 source/config/hook/policy/CI/测试文件时，没有 Issue 关联应硬阻断。允许两种合法路径：绑定 Issue 并贴 contract；或走 machine-readable `trivial` 豁免。纯 docs copy 小改可用 `F018_TRIVIAL_REASON` 或临时 `.git/info/sprint-contract-exemption` 文件声明。 |

## 与 S-D7-002 的联动

复用 S-D7-002 的结构，不复用同一个 policy 文件：

- 共用模式：`.github/*-policy.yml` 保存字段、glob、豁免；`Scripts/audit/*_gate.py` 做解析和校验；`Scripts/audit/tests/test_*` 使用 unittest；hook 只负责提取 Claude tool input 后调用 Python。
- 建议抽出共享工具：将 `pr_review_trace.py` 内的 `_glob_to_regex()`、`matches_any()`、`is_placeholder()` 移到 `Scripts/audit/governance_policy.py`，F-005 与 F-018 同用，避免 glob 语义漂移。
- 独立 policy：F-005 是 PR body review trace；F-018 是 Issue comment sprint contract。两者字段不同，不能塞进一个 YAML。
- hook 优先级：`pre-edit-sprint-contract.sh` 属于 `PreToolUse(Edit|Write|MultiEdit)`，应在任何 PostToolUse swiftlint/docaudit 之前运行；`block-dangerous-bash.sh` 继续只管 Bash；`premerge-checklist.sh` 继续只管 `gh pr merge`。

建议 `.claude/settings.json` 增加：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-edit-sprint-contract.sh"
          }
        ]
      }
    ]
  }
}
```

## 标准化 Sprint Contract 留痕格式

Issue comment 必须保留段头和字段名。正常 contract：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #123
Issue Type: enhancement
Appetite: Medium
Status: Building
Touches:
- Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift
- Packages/SnapDrillCore/Tests/SnapDrillCoreTests/FooTests.swift
No-Touch:
- Packages/SnapDrillData/**
- SnapDrillShare/**
Interface Delta:
- public func buildFoo(input: FooInput) async throws -> FooResult
Test Additions:
- FooTests.testBuildFooRejectsInvalidInput
DoD Minimum:
- swiftlint --strict
- xcodebuild build-for-testing -scheme AllTests -testPlan AllTests
Uncertainties:
- Existing repository API may already cover query path; verify before adding abstraction.
Contract Author: claude
```

Small chore 简化 contract：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #123
Issue Type: chore
Appetite: Small
Status: Building
Touches:
- docs/product/product-vision.md
No-Touch:
- Packages/**
- .github/**
DoD Minimum:
- python3 Scripts/audit/docaudit.py all --strict --baseline
Contract Author: claude
```

Machine-readable trivial 豁免：

```markdown
## Sprint Contract

Contract Required: exempt
Contract Exemption: trivial
Issue: #123
Changed Paths Checked: yes
Disallowed Paths Present: no
Exemption Rationale: single-line typo fix; no behavior, interface, test, CI, hook, policy, or config change.
Contract Author: claude
```

无 Issue 的本地一次性豁免文件建议只允许在 `.git/info/sprint-contract-exemption`，不进 repo：

```text
Contract Required: exempt
Contract Exemption: trivial
Changed Paths:
- docs/product/product-vision.md
Disallowed Paths Present: no
Exemption Rationale: single-line typo fix; no behavior/interface/test/config/policy change.
Expires After Commit: yes
```

## Policy YAML 方案

新增 `.github/sprint-contract-policy.yml`：

```yaml
version: 1
required_section: "## Sprint Contract"

required_fields:
  - Contract Required
  - Issue
  - Contract Author

normal_contract:
  contract_required: "yes"
  required_fields:
    - Issue Type
    - Appetite
    - Status
    - Touches
    - No-Touch
    - DoD Minimum
  full_required_fields:
    - Interface Delta
    - Test Additions
    - Uncertainties
  accepted_issue_types: ["enhancement", "chore"]
  accepted_status_values: ["Building", "status:building", "building"]

small_chore:
  issue_type: "chore"
  appetite: "Small"
  required_fields:
    - Touches
    - No-Touch
    - DoD Minimum

issue_detection:
  explicit_env: "SPRINT_CONTRACT_ISSUE"
  branch_patterns:
    - "#(?P<number>[0-9]+)"
    - "issue[-/](?P<number>[0-9]+)"
    - "^(?P<number>[0-9]+)[-/]"
  building_labels: ["status:building", "building"]
  eligible_labels: ["enhancement", "chore"]
  exempt_labels: ["bug"]

protected_edit_globs:
  - "Packages/**/*.swift"
  - "SnapDrill/**/*.swift"
  - "SnapDrillShare/**/*.swift"
  - "Tests/**/*.swift"
  - ".github/**"
  - ".claude/hooks/**"
  - ".claude/skills/**"
  - "Scripts/**"
  - "*.xcodeproj/**"
  - "*.xcconfig"
  - ".swiftlint.yml"
  - "Package.swift"
  - "fastlane/**"

exemptions:
  trivial:
    max_files: 1
    allowed_globs:
      - "docs/**/*.md"
      - "*.md"
    denied_globs:
      - "docs/workflow.md"
      - "docs/standards/**"
      - "docs/audits/**"
      - "docs/decisions/ADR-*.md"
      - "Packages/**"
      - "SnapDrill/**"
      - ".github/**"
      - ".claude/**"
      - "Scripts/**"
      - "*.xcodeproj/**"
      - "*.xcconfig"
      - "Package.swift"
      - "fastlane/**"
    required_fields:
      - Changed Paths Checked
      - Disallowed Paths Present
      - Exemption Rationale

placeholder_patterns:
  - "^\\[填[写入]"
  - "^\\[fill[ \\-]?in"
  - "^tbd$"
  - "^TODO$"
  - "^placeholder$"
  - "^\\.\\.\\.+$"
  - "^x$"
  - "^N/A$"

override:
  env: "F018_SPRINT_CONTRACT_OVERRIDE"
```

## Python checker 方案

新增 `Scripts/audit/sprint_contract_gate.py`，职责：

1. 从 Claude hook input 接收 `--file-path`，或测试时接收 `--paths-file`。
2. 根据 policy 判断当前 edit 是否属于 protected path；非 protected path 可跳过。
3. 解析 Issue number：`SPRINT_CONTRACT_ISSUE` > branch pattern > PR closing issue。
4. 读取 Issue labels/body/comments：`gh issue view <n> --json labels,body,comments,title,url`。
5. 判断 Issue 是否需 contract：enhancement 或 chore 且 Building；bug 默认豁免；trivial 必须显式豁免。
6. 在 comments 中查找最新 `## Sprint Contract` 段并字段化解析。
7. 校验字段、placeholder、Small chore 简化规则、trivial 豁免规则。
8. 返回：0 pass，1 validation fail，2 operational fail。

关键接口建议：

```python
def parse_contract(markdown: str) -> dict[str, str | list[str]]:
    """Extract fields under ## Sprint Contract. Multi-line bullet fields become lists."""

def issue_requires_contract(labels: list[str], policy: dict) -> bool:
    """enhancement/chore + Building requires a contract; bug labels are exempt."""

def validate_contract(fields: dict, issue: Issue, paths: list[str], policy: dict) -> list[str]:
    """Return validation errors. Empty list means pass."""

def validate_edit(paths: list[str], policy: dict) -> list[str]:
    """Entry point for hook and tests."""
```

多行字段解析必须支持：

```markdown
Touches:
- path/a.swift
- path/b.swift
```

不能只支持单行 `Touches: x`，否则模板可读性会倒退。

## Claude hook 方案

新增 `.claude/hooks/pre-edit-sprint-contract.sh`：

```bash
#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): F-018 Sprint Contract gate.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq
require_command git
require_command python3

if [[ "${F018_SPRINT_CONTRACT_OVERRIDE:-0}" = "1" ]]; then
  echo "F018_SPRINT_CONTRACT_OVERRIDE=1 — bypassing Sprint Contract gate for this tool call." >&2
  echo "A Sprint Contract or machine-readable exemption must be added before commit/PR." >&2
  exit 0
fi

INPUT=$(cat)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

cd "$PROJECT_ROOT"

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

case "$TOOL" in
  Edit|Write)
    echo "$INPUT" | jq -r '.tool_input.file_path // empty' > "$TMP"
    ;;
  MultiEdit)
    echo "$INPUT" | jq -r '.tool_input.file_path // empty' > "$TMP"
    ;;
  *)
    exit 0
    ;;
esac

if ! python3 Scripts/audit/sprint_contract_gate.py --paths-file "$TMP"; then
  exit 2
fi
```

说明：Claude `MultiEdit` 通常仍是单个 `file_path` 加 edits 数组，因此先按单文件处理即可；若未来 tool input 支持多文件，则 checker 已经支持 `--paths-file` 多行。

## Issue template 改进

`feature_request.md` 现已有完整段，但建议把"Claude 开工前回填"改成机器可读字段模板，减少自然语言漂移：

````markdown
## Sprint Contract（Claude 开工前以 Issue comment 回填，commit 前回读）

```markdown
## Sprint Contract

Contract Required: yes
Issue: #<issue-number>
Issue Type: enhancement
Appetite: Small|Medium|Large
Status: Building
Touches:
- <path>
No-Touch:
- <path-or-glob>
Interface Delta:
- <public signature or "none">
Test Additions:
- <test name or "none">
DoD Minimum:
- <command/check>
Uncertainties:
- <known unknown or "none">
Contract Author: claude
```
````

`chore.md` 建议提供 Small 简化模板，同时保留 Medium/Large 全量字段要求。

## sprint-contract skill 改进

`.claude/skills/sprint-contract/SKILL.md` 应新增三点：

1. Step 0：先运行 `python3 Scripts/audit/sprint_contract_gate.py --issue <number> --explain`，判断当前 Issue 是否已有合规 contract。
2. Step 3：输出必须使用字段化模板，不再只写中文 bullet。
3. Step 5：每次 scope 变化先 patch Issue comment，再继续 Edit；否则 hook 会在 protected path 上阻断。

不建议让 skill 自己绕过 hook。skill 负责生成合规 contract，hook 负责机械检查。

## PR / CI 补漏

F-018 主门禁在本地 Edit 前，但 CI 可以防止绕过本地 hook：

- PR job：读取 PR closing issue，运行 `python3 Scripts/audit/sprint_contract_gate.py --pr "$PR_NUMBER" --changed-files-from-pr`，确认对应 Issue comment 存在。
- Push job：若直推 develop/main 且改 protected paths，要求 commit message trailer：

```text
F-018-Sprint-Contract: #123
```

或：

```text
F-018-Sprint-Contract: exempt trivial <reason>
```

CI 不能阻止本地 Edit，但能阻止绕过 hook 后进入主线。

## 测试用例

新增 `Scripts/audit/tests/test_sprint_contract_gate.py`，至少覆盖以下场景。

### 1. Building Issue 无 Sprint Contract comment 被拒绝

```python
def test_building_issue_without_contract_rejected(self):
    issue = Issue(
        number=159,
        labels=["enhancement", "status:building"],
        comments=[],
    )
    errors = sprint_contract_gate.validate_issue_contract(
        issue,
        ["Packages/SnapDrillCore/Sources/Foo.swift"],
        POLICY,
    )
    self.assertTrue(any("missing ## Sprint Contract" in e for e in errors))
```

### 2. Building Issue 有完整 Sprint Contract 放行

```python
def test_building_issue_with_contract_passes(self):
    issue = Issue(
        number=159,
        labels=["enhancement", "status:building"],
        comments=[FULL_CONTRACT_COMMENT],
    )
    errors = sprint_contract_gate.validate_issue_contract(
        issue,
        ["Packages/SnapDrillCore/Sources/Foo.swift"],
        POLICY,
    )
    self.assertEqual(errors, [])
```

### 3. Small chore 使用三字段简化 contract 放行

```python
def test_small_chore_minimal_contract_passes(self):
    issue = Issue(
        number=735,
        labels=["chore", "status:building"],
        comments=[SMALL_CHORE_CONTRACT_COMMENT],
    )
    errors = sprint_contract_gate.validate_issue_contract(
        issue,
        ["docs/product/product-vision.md"],
        POLICY,
    )
    self.assertEqual(errors, [])
```

### 4. 无 Issue 关联的 protected edit 被拒绝

```python
def test_ad_hoc_protected_edit_without_issue_rejected(self):
    errors = sprint_contract_gate.validate_ad_hoc_edit(
        ["Packages/SnapDrillCore/Sources/Foo.swift"],
        POLICY,
        exemption_text=None,
    )
    self.assertTrue(any("no associated Issue" in e for e in errors))
```

### 5. 误拦截后补 contract 立即解锁

```python
def test_after_contract_comment_added_gate_unlocks(self):
    issue = Issue(
        number=159,
        labels=["enhancement", "status:building"],
        comments=[],
    )
    blocked = sprint_contract_gate.validate_issue_contract(issue, ["Packages/Foo.swift"], POLICY)
    self.assertTrue(blocked)

    issue.comments.append(FULL_CONTRACT_COMMENT)
    unblocked = sprint_contract_gate.validate_issue_contract(issue, ["Packages/Foo.swift"], POLICY)
    self.assertEqual(unblocked, [])
```

### 6. 占位符 contract 被拒绝

```python
def test_placeholder_contract_rejected(self):
    issue = Issue(
        number=159,
        labels=["enhancement", "status:building"],
        comments=[FULL_CONTRACT_COMMENT.replace("Packages/SnapDrillCore/Sources/Foo.swift", "TBD")],
    )
    errors = sprint_contract_gate.validate_issue_contract(issue, ["Packages/Foo.swift"], POLICY)
    self.assertTrue(any("placeholder" in e for e in errors))
```

### 7. trivial 豁免不能覆盖治理/代码路径

```python
def test_trivial_exemption_denied_for_policy_path(self):
    errors = sprint_contract_gate.validate_exemption(
        TRIVIAL_EXEMPTION_FIELDS,
        [".github/workflows/ci.yml"],
        POLICY,
    )
    self.assertTrue(any("denied" in e for e in errors))
```

## 直接 commit / push 路径

本地 `Scripts/hooks/pre-push` 目前已有 protected branch 直推阻断。F-018 应作为第二层，不替代 F-001：

1. 如果 push 目标是 develop/main，先继续执行现有禁止直推逻辑。
2. 若存在授权绕过直推，CI push job 检查 changed files。
3. 改 protected paths 时必须有 `F-018-Sprint-Contract:` trailer。
4. trailer 中的 Issue number 仍需反查 Issue comment 是否合规，不能只信 commit message。

## 已知盲区

- 用户绕过路径：可通过禁用 Claude hooks、设置 `F018_SPRINT_CONTRACT_OVERRIDE=1`、直接用非 Claude 编辑器修改文件、或离线环境绕过本地检查。CI/PR job 只能补主线入口，不能证明本地每次 Edit 都经过 hook。
- 假阳性：分支名没有 Issue number、Issue 使用 GitHub Project field 表示 Building 但没有 label、或 contract comment 是旧格式但实质完整，都会被挡。解决方式是补 `SPRINT_CONTRACT_ISSUE` 或贴字段化 comment。
- 假阴性：Issue comment 可能字段齐全但内容虚假，例如 Touches 漏列实际改动。基础 checker 只能做字段和路径粗校验；scope fidelity 仍需 cross-audit / PR review 对照 git diff。
- 关键字伪装：Issue 描述或普通 comment 提到"Sprint Contract"不应通过；必须检查 `## Sprint Contract` 段和字段。checker 必须拒绝 placeholder。
- 团队扩展：多人同时修改同一 Issue 时，"最新一条 Sprint Contract comment"可能覆盖前一人的范围。长期应支持 `Contract ID` 或按 PR branch 绑定 comment。
- GitHub API 可用性：本地 hook 依赖 `gh` 登录和网络。离线时对 protected edit 应 fail closed；若用户明确离线工作，必须临时豁免并在恢复网络后补 contract。
- Project status 语义：若团队不用 `status:building` label 而只用 GitHub Projects 字段，`gh issue view --json labels` 不够。第一版建议强制 Building label，避免 GraphQL project field 复杂度。

## 推荐落地顺序

1. 新增 `.github/sprint-contract-policy.yml` 和 `Scripts/audit/sprint_contract_gate.py`。
2. 新增 `Scripts/audit/tests/test_sprint_contract_gate.py`，先让 7 个核心场景通过。
3. 新增 `.claude/hooks/pre-edit-sprint-contract.sh`，并在 `.claude/settings.json` 的 `PreToolUse(Edit|Write|MultiEdit)` 挂载。
4. 更新 issue template 和 sprint-contract skill 的字段化输出格式。
5. 在 CI 增加 PR/push 补漏 job，但不把 CI 当作开工前主门禁。

最低可接受切片是 1-3。只改模板或只改 skill 不足以修复 not-applied-in-practice。
