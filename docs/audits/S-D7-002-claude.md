---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-002 修复提案 — Claude CLI 独立产出

> Phase 11 B 方案三任务并行之二（**F-005 PR review 留痕机械化**）。
> 本提案在主 worktree 独立完成，全程未读 codex / antigravity 产出。

## 1. Bug 复现与根因定位

### 1.1 现状

- `docs/workflow.md:108-120` 明文：「所有 PR 必须完成 review 后合并 + Review 结论必须留痕」
- 实证 PR #742「docs: 归零审计」MERGED：**reviews=0 / comments=0 / body 无 Codex/Gemini/Xcode review 段** → F-005 真违规
- 现有机制 `.claude/hooks/premerge-checklist.sh:23-30`：
  - 仅做「近 24h 是否更新 STATUS.md」**软提示**
  - **不**检查 PR body 含 review 留痕
  - 仅匹配 `gh pr merge` 命令，**不**拦截「直接 push 到 develop」绕道（虽然 pre-push hook 已拦 develop 直推，但 `ALLOW_DIRECT_PUSH=1` override 路径绕过整个 review 链）
- `.github/pull_request_template.md` 有 review checkbox 但**纯静态文本，无强制校验**

### 1.2 根因

机械化拦截缺失，依赖人/Claude 自觉。F-005 是「执行纪律」类规则，必须有 machine-enforceable 路径。

## 2. 7 项设计决策必答

### D1. 强化路径

**选择**：**CI step + 本地 Claude hook 双层拦截**（不依赖 GitHub Branch Protection——Free + private repo 无 server-side rules）。

| 层 | 实现 | 阻断时机 |
|---|---|---|
| CI step | `.github/workflows/ci.yml` 新增 `review-trace` job | PR 合并前 / push 到 develop 后 |
| 本地 hook | `.claude/hooks/premerge-checklist.sh` 扩展 | Claude `gh pr merge` 命令前 |
| pre-push hook | `Scripts/hooks/pre-push` 加 review 留痕检查 + `ALLOW_DIRECT_PUSH` 路径联动收紧 | 直接 push develop 前 |

### D2. 豁免条件设计

**选择**：**docs-only PR 豁免 + 显式 label override**。

豁免规则（machine-readable）：

```yaml
exempt:
  paths_only:    # 改动文件路径模式全部匹配则豁免
    - 'docs/**'
    - '*.md'
    - 'README*'
  labels:        # PR 标签
    - 'review:exempt'           # 显式豁免（需 chramboliao 添加）
    - 'docs-only'               # 文档变更
    - 'audit:phase-closeout'    # phase 收尾自动产出
not_exempt:      # 永不豁免（即使其他规则匹配）
  paths:
    - 'Packages/**/*.swift'
    - 'SnapDrill/**'
    - '.swiftlint.yml'
    - '.github/workflows/**'
    - '.claude/hooks/**'
    - 'Scripts/hooks/**'
    - 'Scripts/audit/policy.yaml'
```

### D3. 留痕格式标准化

**选择**：**PR body 段头模板**（与现有 pull_request_template.md 现状兼容 + 加机械可识别 marker）。

留痕段必须包含至少一个 marker：

```markdown
## Codex Review

<结论摘要 + 关键 finding>

## Gemini Review  <!-- 或 Antigravity Review -->

<结论摘要 + 关键 finding>

## Xcode Review  <!-- UI 变更必填 -->

<结论摘要 + 关键 finding>
```

检测正则（CI / hook 共用）：

```regex
^##\s+(Codex|Gemini|Antigravity|Xcode|Claude\s+self)\s+Review\s*$
```

至少匹配 1 次即过（**多家越多越好**）。

### D4. 检测时机

**选择**：**Claude `gh pr merge` 前 hook 阻断 + CI status check 双层**。

- 主路径：本地 Claude 调 `gh pr merge` 前，hook 拉 PR body 检查
- 备份路径：GitHub Actions `review-trace` job 在 PR push 时跑，PR 页面显示 ❌ status，人工 reviewer 看到
- 直推 develop 路径：pre-push hook 检查最近 N 个 commit 的对应 PR（若有）是否含 review marker

### D5. 历史 PR 处理

**选择**：**不追溯**。

- 历史 PR 是已知违规事实（已被 S-D7-002 finding 记录）
- 强制补 review 成本高 / 回报低（已合并 / 已稳定）
- 仅以**新 PR 起开始机械化拦截**为目标

### D6. 直推 develop 场景

**选择**：**直推不豁免**——pre-push hook 检查最近 commit msg 含 review marker，或要求用户显式 `ALLOW_DIRECT_PUSH=1 SKIP_REVIEW_TRACE=1` 双 override。

理由：若可单 override 绕过 review 留痕，机械化失去意义。两个独立 override 提高决策摩擦。

### D7. 与 sprint-contract / cross-audit skill 联动

**选择**：**cross-audit-consensus skill 完成时自动 attach review 段到 PR body**。

- cross-audit 完成 → 生成 review 段 markdown → 通过 `gh pr edit --body-file` 追加到 PR body
- sprint-contract closeout 时检查最近 cross-audit 输出存在并已 attach
- 三方对抗 worktree 完成时（如 Phase 11 实战），consensus 文件 markdown 也算作 review 留痕

## 3. 修复方案

### 3.1 新增 CI step

`.github/workflows/ci.yml` 新增 job：

```yaml
  review-trace:
    name: Review Trace Check
    runs-on: ubuntu-latest
    timeout-minutes: 3
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - name: Check PR body for review markers
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          python3 Scripts/hooks/check-review-trace.py --pr "$PR_NUMBER" --policy Scripts/hooks/review-trace-policy.yaml
```

### 3.2 新增 hook 工具

`Scripts/hooks/check-review-trace.py`：

```python
#!/usr/bin/env python3
"""Check PR body for review trace markers.

Usage:
    check-review-trace.py --pr <number> --policy <yaml>
    check-review-trace.py --commit-range HEAD~3..HEAD --policy <yaml>  # for direct push
"""
import argparse
import re
import subprocess
import sys
import yaml
from pathlib import Path

REVIEW_MARKER_RE = re.compile(
    r"^##\s+(Codex|Gemini|Antigravity|Xcode|Claude\s+self)\s+Review\s*$",
    re.MULTILINE,
)

def is_exempt(changed_files: list[str], labels: list[str], policy: dict) -> bool:
    not_exempt = policy.get("exempt", {}).get("paths_not_exempt", [])
    if any(_matches(f, not_exempt) for f in changed_files):
        return False
    exempt_labels = set(policy.get("exempt", {}).get("labels", []))
    if set(labels) & exempt_labels:
        return True
    paths_only = policy.get("exempt", {}).get("paths_only", [])
    if all(_matches(f, paths_only) for f in changed_files):
        return True
    return False

def _matches(path: str, patterns: list[str]) -> bool:
    from fnmatch import fnmatch
    return any(fnmatch(path, p) for p in patterns)

def main() -> int:
    # ... 解析 args, 拉 PR body via gh, 跑正则检查, 输出明确错误信息
    ...

if __name__ == "__main__":
    sys.exit(main())
```

### 3.3 扩展 `premerge-checklist.sh`

```diff
 if ! echo "$COMMAND" | grep -qE '^[[:space:]]*gh pr merge\b'; then
     exit 0
 fi

 PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
 # ...

+# F-005 review 留痕检查
+if [[ "${SKIP_REVIEW_TRACE:-0}" != "1" ]]; then
+    PR_NUMBER=$(echo "$COMMAND" | grep -oE 'gh pr merge[[:space:]]+([0-9]+)' | awk '{print $NF}')
+    if [[ -n "$PR_NUMBER" ]]; then
+        if ! python3 Scripts/hooks/check-review-trace.py --pr "$PR_NUMBER" --policy Scripts/hooks/review-trace-policy.yaml; then
+            echo "PR #$PR_NUMBER 缺少 review 留痕。" >&2
+            echo "在 PR body 加 \`## Codex Review\` / \`## Gemini Review\` / \`## Antigravity Review\` 段或贴 label \`review:exempt\` / \`docs-only\` / \`audit:phase-closeout\`。" >&2
+            echo "紧急 override: SKIP_REVIEW_TRACE=1 gh pr merge ..." >&2
+            exit 2
+        fi
+    fi
+fi

+# 24h STATUS.md 检查（保持）
 LAST_STATUS_COMMIT=$(git log -1 --since="24 hours ago" --format=%H -- STATUS.md 2>/dev/null || echo "")
 # ... 现有逻辑保留
```

### 3.4 扩展 `Scripts/hooks/pre-push`

直推 develop 时检查近 3 个 commit msg 含 review marker（同正则）：

```diff
 while read -r local_ref local_sha remote_ref remote_sha; do
   for branch in "${PROTECTED_BRANCHES[@]}"; do
     if [[ "$remote_ref" == "refs/heads/$branch" ]]; then
       if [[ "${ALLOW_DIRECT_PUSH:-0}" != "1" ]]; then
         # ... 现有阻断 ...
         exit 1
       else
         echo "⚠️  ALLOW_DIRECT_PUSH=1 已设置，绕过保护推送到 '$branch'" >&2
+        # F-005 review 留痕检查（即使直推 override 也需要）
+        if [[ "${SKIP_REVIEW_TRACE:-0}" != "1" ]]; then
+            if ! python3 Scripts/hooks/check-review-trace.py --commit-range "${remote_sha}..${local_sha}" --policy Scripts/hooks/review-trace-policy.yaml; then
+                echo "❌ 直推 develop 但近 commit 无 review 留痕。" >&2
+                echo "在 commit msg 加 \`Codex Review: <摘要>\` 或 \`Antigravity Review: <摘要>\` 行；或 SKIP_REVIEW_TRACE=1 双 override 通过。" >&2
+                exit 1
+            fi
+        fi
       fi
     fi
   done
 done
```

### 3.5 PR Template 强化

`.github/pull_request_template.md` 在 Checklist 后加段头：

```markdown
## Codex Review
<!-- review-trace marker，必填或贴 review:exempt label。F-005 强制留痕。-->


## Antigravity Review  <!-- 或 Gemini Review -->


## Xcode Review  <!-- UI 改动必填 -->

```

### 3.6 Policy 文件

`Scripts/hooks/review-trace-policy.yaml`：

```yaml
# F-005 review trace 检测策略
markers:
  - 'Codex Review'
  - 'Gemini Review'
  - 'Antigravity Review'
  - 'Xcode Review'
  - 'Claude self Review'

exempt:
  paths_only:
    - 'docs/**'
    - '*.md'
    - 'README*'
  labels:
    - 'review:exempt'
    - 'docs-only'
    - 'audit:phase-closeout'
  paths_not_exempt:
    - 'Packages/**/*.swift'
    - 'SnapDrill/**'
    - '.swiftlint.yml'
    - '.github/workflows/**'
    - '.claude/hooks/**'
    - 'Scripts/hooks/**'
    - 'Scripts/audit/policy.yaml'

min_markers: 1  # 至少匹配 1 个 review marker
```

## 4. 测试场景（5 个）

| 场景 | 输入 | 期望 |
|---|---|---|
| T1 PR 改 Swift 无 review | body 无 marker，改动 `Packages/**/*.swift` | exit 2 + 错误信息含「在 PR body 加 ## Codex Review」 |
| T2 docs-only PR 走豁免 | body 无 marker，只改 `docs/**/*.md` | exit 0（豁免 paths_only）|
| T3 PR 有 1 个 Codex Review marker | body 含 `## Codex Review\n<...>` | exit 0（≥1 marker）|
| T4 直推 develop 无 marker | commit msg 无 review 行，`ALLOW_DIRECT_PUSH=1` 已设 | pre-push 仍 exit 1（要 SKIP_REVIEW_TRACE=1 双 override）|
| T5 PR body marker 但格式错误 | `### Codex 审计`（小写「审计」非「Review」）| exit 2，错误信息提示标准 marker 列表 |

测试可写为 `Scripts/audit/tests/test_review_trace.py`（unittest 风格，与 `test_docaudit.py` 同级）。

## 5. 已知盲区（自检）

| 盲区 | 当前处理 | 重审触发条件 |
|---|---|---|
| 用户用 `SKIP_REVIEW_TRACE=1 ALLOW_DIRECT_PUSH=1` 双 override 推 develop | 故意保留逃生路径（不能机械化到 100%）；每次双 override 写入 `.claude/session-log.txt` 留 audit trail | 滥用率高时升级到强制 prompt 用户确认 |
| 假阳性：review 内容合规但 marker 不规范（如 `## Code Review` 而非 `## Codex Review`）| 错误信息列出标准 marker 列表 | marker 名扩展需求多时改为 fuzzy 匹配 |
| PR body 在 push 后再修改的时序 | CI step 在 PR push 时跑 + hook 在 merge 时跑 — 两次都查 | 若 GitHub PR body 编辑后无重新触发 CI，需要 issue webhook 联动 |
| `audit:phase-closeout` label 滥用（任何 PR 贴此 label 都豁免） | label 配置由 chramboliao 显式贴；hook 不验证 label 合法性 | label 滥用时改为「label 必须 + 文件路径模式双匹配」 |
| 与未来 GitHub Branch Protection / Required Status Checks 的兼容性 | 本方案不依赖 server-side rules；未来引入时本 hook 链可作为本地预检 | GitHub Pro 启用 server-side rules 时重审 |
| review marker 多语言场景（中文 review 段头）| 仅匹配英文 marker。中文用户在英文段头下放中文内容 | i18n 需求出现时扩展正则 |
| commit msg review 行格式 | 直推路径要求 `Codex Review: <摘要>` 行内格式；与 PR body `## Codex Review` 段头格式不同 | 长期可统一为单一格式 |

## 6. 不变性声明

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D7-002-claude.md`
- ✅ 未触动 `.github/` / `.claude/hooks/` / `Scripts/hooks/` 任何文件
- ✅ 未读 codex / antigravity 在各自 worktree 的产出
- ✅ 不直接 apply 到代码——apply 由 cross-fix-consensus 阶段统一做

## 7. 与 S-D7-003 联动

S-D7-003（F-018 Sprint Contract 机械拦截）和本任务都是「机械化拦截 F-rule 应用率漂移」问题。建议：

- `Scripts/hooks/check-review-trace.py` 与未来 `Scripts/hooks/check-sprint-contract.py` 共用 yaml policy 路径约定（`Scripts/hooks/*.yaml`）
- `.claude/hooks/premerge-checklist.sh` 作为 F-005 / F-007 / F-018 统一前置门禁集合点（一处 hook 检多个 F-rule）
- CI step 命名约定：`*-trace` / `*-check`（如 `review-trace` / `sprint-contract-check`）

## 8. 关联

- [任务定义书](S-D7-002-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- `docs/memory/feedback.md` F-005
- `docs/workflow.md` §对抗性审查
- `.claude/hooks/premerge-checklist.sh` 现有 hook（保留 + 扩展）
- `Scripts/hooks/pre-push` 现有 hook（扩展）
