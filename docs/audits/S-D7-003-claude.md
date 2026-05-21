---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-003 修复提案 — Claude CLI 独立产出

> Phase 11 B 方案三任务并行之三（**F-018 Sprint Contract 机械拦截**）。
> 本提案在主 worktree 独立完成，全程未读 codex / antigravity 产出。

## 1. Bug 复现与根因定位

### 1.1 三态漂移

- **dead-on-paper（已检）**：`docs/memory/feedback.md` F-018 列出且 `docs/workflow.md` §编码前契约 详述
- **alive-in-skill（已检）**：`.claude/skills/sprint-contract/SKILL.md` 完整定义触发条件 + 工作流
- **not-applied-in-practice（实证）**：
  - enhancement Issues #159/#137/#136/#31/#30 = **0/5 有 Sprint Contract comment**
  - chore Issues #735/#684/#718/#720 = **0/4 有 Sprint Contract comment**
  - 仅 epic #766 有

### 1.2 根因

`.claude/skills/sprint-contract/SKILL.md` 是「**用户/Claude 主动触发**」模式——Claude 必须在动代码前自觉调用 skill 贴 contract。**无机械拦截**：Claude 漏调 / 用户漏让 Claude 调 → 直接 Edit 代码也不会被阻断。

## 2. 7 项设计决策必答

### D1. 拦截位置

**选择**：**Claude PreToolUse Edit hook**——在 Claude 任何 `Edit`/`Write` 调用前，检查关联 Issue 的 Sprint Contract 状态。

理由：
- Edit / Write 是「动代码」的最早信号——拦截这个时机比 commit / push 时晚发现成本低
- 与现有 hook 体系一致（`.claude/hooks/swift-autolint.sh` 是 PostToolUse Edit；本 hook 走 PreToolUse Edit）
- `.claude/hooks/log-file-change.sh` 已有 PreToolUse 接入，做参考

### D2. 拦截强度

**选择**：**渐进硬化**——初次启用为软警告（`exit 0` + stderr log），3 次软警告后升级为硬阻断（`exit 2`）。

理由：
- 一上来硬阻断会让本 finding 修复期间的 Claude 自己被阻断（meta loop）
- 渐进式让 Claude 有时间适应「先贴 contract 再 Edit」的新流程
- 计数器存 `.claude/state/sprint-contract-warnings.json`（per-session），超阈值升级硬阻断
- 用户可显式 `SKIP_SPRINT_CONTRACT=1` 单次 override（与 review-trace 双 override 哲学一致）

### D3. Issue 状态识别

**选择**：**关联 Issue 推导 + Issue label + 最近 comment 三重 fallback**。

推导关联 Issue 顺序：

```
1. 当前分支名匹配 fix/<num>-* / feat/<num>-* / chore/<num>-* → Issue #<num>
2. .claude/state/current-issue.json 存储当前 active Issue（手动 set/clear）
3. 最近 commit msg `(#NNN)` 或 `Closes #NNN`
4. 都没拿到 → 视为 ad-hoc edit，按 D7 规则
```

拿到 Issue 后：

```bash
gh issue view <num> --json labels,state,comments
```

判断条件：
- Issue state == OPEN 且 labels 含 `status:building` → 需要 contract
- 最近 comments 含 `## Sprint Contract` 段或文字「Sprint Contract:」前缀 → 已有 contract
- 没有 → 拦截

### D4. Appetite=Small 豁免

**选择**：**chore Small 豁免简化为 3 项**（与 sprint-contract skill 豁免段对齐）：

豁免规则（machine-readable）：

```yaml
appetite_small_simplified:
  required_keywords:  # comment 必须含至少这 3 个关键字
    - 'Touches'
    - 'No-Touch'
    - 'DoD'
  # 不要求 Interface Delta / Test Additions / 预期不确定点
  # 但 Touches / No-Touch / DoD 三条仍必填
```

bug_report 类 / 改 typo / 单行改动 也走豁免（参见 sprint-contract skill 现有 §豁免段）。

### D5. 历史 Issue 处理

**选择**：**不追溯**（与 S-D7-002 立场一致）。

仅以新 Issue 起开始机械化拦截。历史 9 个无 contract 的 Issue 已记录为 finding 事实，不强制补。

### D6. 与 cross-audit / post-merge skill 联动

**选择**：**sprint-contract closeout 时联动 cross-audit + post-merge**。

- sprint-contract skill 完成时（用户说「contract 完成」/「编码结束」）写 closeout comment 到 Issue
- closeout comment 含 `## Sprint Contract Closeout` 段，触发 `.claude/hooks/premerge-checklist.sh` 在 `gh pr merge` 时验证
- post-merge skill 在 PR 合并后扫 Issue closeout 状态 → 加 `status:done` label

### D7. 直接 commit / 无 Issue 关联场景

**选择**：**ad-hoc edit 软警告 + commit msg 摘要约束**。

- 无关联 Issue 的 Edit/Write → hook 输出 stderr：「无关联 Issue。如确需 ad-hoc 修改，commit msg 必须含 `Touches: ... / No-Touch: ... / DoD: ...` 三行摘要」
- 不阻断（防止 hot-fix 场景僵化）
- 后续 commit msg 校验由独立 commit-msg hook 做（不在本任务范围）

## 3. 修复方案

### 3.1 新增 hook `.claude/hooks/pre-edit-sprint-contract.sh`

```bash
#!/bin/bash
# PreToolUse (Edit/Write): 检查关联 Issue 是否有 Sprint Contract（F-018）
# Override: SKIP_SPRINT_CONTRACT=1 跳过本次
# 渐进硬化：软警告 3 次后升级硬阻断（.claude/state/sprint-contract-warnings.json）

set -euo pipefail

if [[ "${SKIP_SPRINT_CONTRACT:-0}" == "1" ]]; then
    exit 0
fi

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# 仅对 Edit / Write / NotebookEdit 生效（Read / Grep 等只读工具放行）
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" && "$TOOL" != "MultiEdit" ]]; then
    exit 0
fi

# 仅对 Swift / 源码文件触发；docs/audits/ / docs/memory/ / docs/ 改动放行
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE" in
    */docs/*|*/.claude/*|*/Scripts/audit/tests/*|*/audit-ledger-*|*/*.tsv)
        exit 0
        ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -z "$PROJECT_ROOT" ]] && exit 0
cd "$PROJECT_ROOT"

# 推导关联 Issue
ISSUE=$(python3 .claude/hooks/derive-issue.py 2>/dev/null || true)

if [[ -z "$ISSUE" ]]; then
    echo "⚠️ sprint-contract: 无关联 Issue 的 ad-hoc edit。" >&2
    echo "  commit msg 必须含 Touches/No-Touch/DoD 三行摘要。" >&2
    exit 0  # ad-hoc 软警告，不阻断
fi

# 检查 Issue Sprint Contract 状态
if python3 .claude/hooks/check-sprint-contract.py --issue "$ISSUE"; then
    exit 0  # contract 已存在
fi

# 渐进硬化
STATE_DIR="$PROJECT_ROOT/.claude/state"
mkdir -p "$STATE_DIR"
WARN_FILE="$STATE_DIR/sprint-contract-warnings.json"
COUNT=$(python3 -c "import json,os; p='$WARN_FILE'; d=json.load(open(p)) if os.path.exists(p) else {}; print(d.get('$ISSUE', 0))")

if [[ "$COUNT" -lt 3 ]]; then
    NEW=$((COUNT + 1))
    python3 -c "import json,os; p='$WARN_FILE'; d=json.load(open(p)) if os.path.exists(p) else {}; d['$ISSUE']=$NEW; json.dump(d, open(p,'w'))"
    echo "⚠️ sprint-contract: Issue #$ISSUE 缺少 Sprint Contract（软警告 $NEW/3）" >&2
    echo "  贴 Sprint Contract comment 到 Issue：gh issue comment $ISSUE --body \"...\"" >&2
    echo "  详见 .claude/skills/sprint-contract/SKILL.md" >&2
    echo "  3 次后升级为硬阻断。Override: SKIP_SPRINT_CONTRACT=1 <command>" >&2
    exit 0
fi

# 硬阻断
echo "❌ sprint-contract: Issue #$ISSUE 缺少 Sprint Contract（已软警告 3 次，升级硬阻断）" >&2
echo "  必须先贴 Sprint Contract 才能继续 Edit。" >&2
echo "  Override: SKIP_SPRINT_CONTRACT=1 <command>" >&2
exit 2
```

### 3.2 新增辅助脚本

`.claude/hooks/derive-issue.py`:

```python
#!/usr/bin/env python3
"""Derive associated Issue number from branch / state file / commit msg."""
import json
import re
import subprocess
import sys
from pathlib import Path

def from_branch() -> str | None:
    try:
        branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
        ).strip()
        m = re.match(r"(?:fix|feat|chore)/(\d+)", branch)
        return m.group(1) if m else None
    except Exception:
        return None

def from_state_file() -> str | None:
    root = Path(__file__).parent.parent / "state" / "current-issue.json"
    if not root.exists():
        return None
    try:
        return str(json.load(open(root))["issue"])
    except Exception:
        return None

def from_commit() -> str | None:
    try:
        msg = subprocess.check_output(
            ["git", "log", "-1", "--format=%B"], text=True
        )
        m = re.search(r"#(\d+)", msg)
        return m.group(1) if m else None
    except Exception:
        return None

def main() -> int:
    for fn in (from_state_file, from_branch, from_commit):
        if result := fn():
            print(result)
            return 0
    return 1

if __name__ == "__main__":
    sys.exit(main())
```

`.claude/hooks/check-sprint-contract.py`:

```python
#!/usr/bin/env python3
"""Check if Issue has Sprint Contract comment (F-018).

Exit 0 if exists, exit 1 if missing or check failed.
"""
import argparse
import json
import re
import subprocess
import sys
import yaml
from pathlib import Path

CONTRACT_MARKER_RE = re.compile(
    r"^##\s+Sprint\s+Contract\b|^Sprint\s+Contract:",
    re.MULTILINE,
)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--issue", required=True)
    parser.add_argument("--policy", default=".claude/hooks/sprint-contract-policy.yaml")
    args = parser.parse_args()

    policy = yaml.safe_load(open(args.policy))

    try:
        data = json.loads(subprocess.check_output(
            ["gh", "issue", "view", args.issue, "--json", "labels,comments,body"],
            text=True,
        ))
    except subprocess.CalledProcessError:
        return 1  # gh failure → treat as missing

    labels = {l["name"] for l in data.get("labels", [])}

    # 豁免清单
    if labels & set(policy.get("exempt", {}).get("labels", [])):
        return 0

    # 检测 Sprint Contract marker
    body = data.get("body") or ""
    comments = "\n".join(c.get("body", "") for c in data.get("comments", []))
    haystack = body + "\n" + comments

    if CONTRACT_MARKER_RE.search(haystack):
        # Appetite=Small 简化检查
        if "appetite:small" in labels:
            required = policy.get("appetite_small_simplified", {}).get("required_keywords", [])
            for kw in required:
                if kw not in haystack:
                    print(f"sprint-contract: Appetite=Small 简化 contract 缺 {kw}", file=sys.stderr)
                    return 1
        return 0

    return 1

if __name__ == "__main__":
    sys.exit(main())
```

### 3.3 Policy 文件

`.claude/hooks/sprint-contract-policy.yaml`:

```yaml
# F-018 Sprint Contract 检测策略

exempt:
  labels:
    - 'bug'            # bug_report 类（scope 天然小）
    - 'trivial'        # 单行 typo / 注释 / 日志
    - 'no-contract'    # 显式豁免（需 chramboliao 添加）
    - 'epic'           # epic 类本身就是规划，不需 contract
  appetite_small_required_keywords:
    - 'Touches'
    - 'No-Touch'
    - 'DoD'

appetite_small_simplified:
  required_keywords:
    - 'Touches'
    - 'No-Touch'
    - 'DoD'

# 渐进硬化阈值
warning_threshold: 3
```

### 3.4 Hook 注册

`.claude/settings.json` 加（参考 swift-autolint.sh 注册方式）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": {
          "tool_name": ["Edit", "Write", "MultiEdit"]
        },
        "command": "bash .claude/hooks/pre-edit-sprint-contract.sh"
      }
    ]
  }
}
```

### 3.5 sprint-contract skill 增强

`.claude/skills/sprint-contract/SKILL.md` 加 §Closeout 段：

```markdown
## Closeout（编码结束时）

完成 Issue 编码（提 PR 前），在 Issue 贴 Closeout comment：

\```
## Sprint Contract Closeout

- Touches 实际触动文件：<...>
- 偏离 Sprint Contract 的部分：<无 / 列出>
- Test Additions 实际增加：<...>
- DoD 自检：<勾选>
\```

Closeout comment 触发 `premerge-checklist.sh` 在 `gh pr merge` 时验证。
```

## 4. 测试场景（6 个）

| 场景 | 输入 | 期望 |
|---|---|---|
| T1 当前分支 fix/735 但 Issue #735 无 contract | Edit `Packages/.../Foo.swift` | exit 0 + 软警告（首次）|
| T2 软警告达 3 次 → 第 4 次升级硬阻断 | 同 T1 重复 4 次 | 第 4 次 exit 2 |
| T3 Issue 有 Sprint Contract comment | Edit 任意文件 | exit 0 |
| T4 Issue 贴 `bug` label 豁免 | Edit 文件 | exit 0（豁免）|
| T5 Issue 贴 `appetite:small` 但 contract 缺 Touches 关键字 | Edit 文件 | exit 1（简化 contract 不合规）|
| T6 ad-hoc edit（无分支号 / 无 state / 无 commit ref）| Edit 文件 | exit 0 + ad-hoc 软警告 |

测试用 `Scripts/audit/tests/test_sprint_contract.py`。

## 5. 已知盲区（自检）

| 盲区 | 当前处理 | 重审触发条件 |
|---|---|---|
| 用户用 `SKIP_SPRINT_CONTRACT=1` 持续 override | 每次 override 写入 `.claude/session-log.txt` | 滥用率高时升级到 prompt 用户输入豁免理由 |
| 假阳性：Issue body / comment 含「Sprint Contract」字眼但非合规 contract | 检查 `## Sprint Contract` 段头或 `Sprint Contract:` 前缀；不深度校验内容字段 | 假阳性多时改为字段级校验（Touches/No-Touch/DoD 关键字必含）|
| `gh` 命令网络失败 | check-sprint-contract.py exit 1 → 软警告路径 | 离线模式 / 长时间无网络时考虑本地缓存 |
| 分支名不规范（如 `feature-xxx` 而非 `feat/123-xxx`）| derive-issue.py 走 state file / commit fallback；都没拿到走 ad-hoc 软警告 | 团队规模扩大后统一分支命名规范 |
| Issue 在 Building 但 Sprint Contract 贴在 PR body 而非 Issue comment | check-sprint-contract.py 只查 Issue。需要扩展查关联 PR | 工作流改成「PR 优先贴 contract」时扩展 |
| 同一会话内多次切换 Issue | derive-issue.py 优先 state file，需用户/skill 手动维护 current-issue.json | 自动化切换跟随 git checkout 时升级 |
| Hook 在 Antigravity / Codex 桌面端不生效（只对 Claude Code 有效）| 当前所有 Edit/Write 工作流主要走 Claude，Antigravity/Codex 受 worktree 任务定义书约束 | 工作流跨 agent 时需要等价机制 |

## 6. 与 S-D7-002 联动说明

S-D7-003 和 S-D7-002 都是「机械化拦截 F-rule 应用率漂移」类问题。本方案与 S-D7-002 协同：

- **共享 hook 框架**：`.claude/hooks/check-*.py` 文件命名约定一致（review-trace / sprint-contract / 未来其他 F-rule）
- **policy 文件命名约定**：`.claude/hooks/<check-name>-policy.yaml`
- **双 override 哲学**：与 S-D7-002 `SKIP_REVIEW_TRACE` 一致，本任务 `SKIP_SPRINT_CONTRACT` 单 override 即可（不再二次升级）—— 因 contract 缺失不是「合并前最后防线」，可单 override
- **premerge-checklist.sh 集成**：merge 前可同时检查 review trace（S-D7-002）+ Sprint Contract closeout（本任务 §3.5）
- **不冲突**：本 hook 是 PreToolUse Edit，S-D7-002 是 PreToolUse Bash（`gh pr merge`）+ pre-push hook，时机错开

## 7. 不变性声明

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D7-003-claude.md`
- ✅ 未触动 `.claude/` / `.github/` / `Scripts/` 任何文件
- ✅ 未读 codex / antigravity 在各自 worktree 的产出
- ✅ 不直接 apply 到代码——apply 由 cross-fix-consensus 阶段统一做

## 8. 关联

- [任务定义书](S-D7-003-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- `docs/memory/feedback.md` F-018
- `docs/workflow.md` §编码前契约
- `.claude/skills/sprint-contract/SKILL.md` 现有 skill（保留 + 加 Closeout 段）
- **联动**：[S-D7-002-claude.md](S-D7-002-claude.md) F-005 review 留痕机械化
