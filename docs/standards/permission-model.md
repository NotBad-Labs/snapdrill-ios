---
last_verified: 2026-05-18
layer: pattern
---
# SnapDrill 权限模型

> Agent tool 使用 / Bash 命令白名单 / 治理类 Skill allowed-tools 的统一 SSOT。
> 修改任一位置时必须同步本文档，否则审计视图与实际运行状态会脱节。

本文档覆盖三层权限配置：
1. **Tool 分级**：Claude Code 可调用的所有工具按风险等级分层
2. **Bash 命令硬拦截**：`.claude/hooks/block-dangerous-bash.sh` 的受限模式
3. **Hook 生命周期门禁**：`.claude/settings.json` 事件绑定
4. **治理类 Skill 权限**：会影响流程、审计、合并门禁的项目 skill

---

## 1. Tool 分级（三档）

| Tier | 风险 | Tool | 特点 |
|---|---|---|---|
| **T1 只读** | 无副作用 | `Read` · `Glob` · `Grep` · `WebSearch` · `WebFetch` · `TaskList` · `TaskGet` · `TaskOutput` | 不改变仓库/外部系统状态 |
| **T2 工作区写** | 本地可逆 | `Edit` · `Write` · `MultiEdit` · `NotebookEdit` · `Bash`（非受限命令）· `TaskCreate` / `TaskUpdate` / `TaskStop` · `Agent` · `ScheduleWakeup` | 改本地文件 / 状态，git 可回滚 |
| **T3 外部副作用** | 不可逆或跨系统 | `Bash`（受限命令子集，见 §2）· MCP 外部调用（Gmail / Calendar / Drive 等）· `mcp__openclaw__*` 委派 | 修改远程 / 第三方系统 / 破坏性 git 操作 |

**原则**：
- T1 所有 skill 默认开放
- T2 仅需实际改动文件 / 运行命令的 skill 开放
- T3 必须经 hook 二次校验（§2）或用户显式授权

---

## 2. Bash 受限命令（T3 硬拦截）

`.claude/hooks/block-dangerous-bash.sh` 通过单条 ERE 正则拦截已知不可逆操作，`exit 2` 阻塞：

```
rm -rf /[^/]        # 根目录递归删除（放过 rm -rf ./... 这类相对路径）
rm -rf ~            # 用户主目录递归删除
rm -rf $HOME        # $HOME 变量展开递归删除
git push --force    # 强推（可能覆盖远端他人工作）
git push -f<space>  # 强推简写
git reset --hard    # 硬重置（覆盖未提交修改）
git clean -[fdx]+   # 清理未跟踪 / 忽略文件
git branch -D       # 强制删除分支
sudo rm             # 提权删除
```

**绕过**：用户显式授权时可设 `CLAUDE_HOOK_ALLOW_DANGEROUS=1` 环境变量（见 `block-dangerous-bash.sh:13-15`）。

**新增 / 修改拦截规则时**：必须同步：
1. `.claude/hooks/block-dangerous-bash.sh` 的 `DANGEROUS_RE` 变量
2. 本文档 §2 表格
3. `docs/memory/feedback.md` 如有因事故新增规则，补对应 F-NNN

---

## 3. Hook 生命周期门禁

`.claude/settings.json` 事件绑定（11 个活跃 hook）：

| 事件 | Matcher | Hook | 职责 | Tier 相关 |
|---|---|---|---|---|
| `SessionStart` | `compact` | `cat .claude/compact-reminder.md` | 压缩后重载上下文提示 | T1 |
| `PostToolUse` | `Edit\|Write\|MultiEdit` | `log-file-change.sh` | 记录改动文件到 session-log.txt | T1 观察 |
| `PostToolUse` | `Edit\|Write\|MultiEdit` | `swift-autolint.sh` | 改 `.swift` 后即时 swiftlint（行级） | T2 校验 |
| `PostToolUse` | `Edit\|Write\|MultiEdit` | `docaudit-on-doc-edit.sh` | 改 docs 区 `.md` 或入口文档后跑 `docaudit links`（broken link 即时反馈，Phase B PR-2） | T2 校验 |
| `PostToolUse` | `Bash` | `post-merge-checkpoint.sh` | `gh pr merge` 后提示 checkpoint + 反模式启发式扫描 | T2 观察 |
| `PostToolUse` | `.*` | `session-metrics.sh` | 记录所有 tool call 时间戳到 session-metrics.tsv | T1 观察 |
| `PreToolUse` | `Bash` | `block-dangerous-bash.sh` | 见 §2，硬拦截 T3 受限命令 | **T3 守门** |
| `PreToolUse` | `Bash` | `premerge-checklist.sh` | `gh pr merge` 前检查 STATUS.md 近 24h 更新 | T2 合并门禁 |
| `PreToolUse` | `Bash` | `prepush-lint.sh` | `git push` 前全仓 swiftlint | T2 合并门禁 |
| `PreToolUse` | `Bash` | `long-session-guard.sh` | 会话 > 60 min 提示 compact / phase-closeout | T1 观察 |
| `PreToolUse` | `Bash` | `docaudit-preflight.sh` | `git push` / `gh pr merge` / `git commit --amend` 前跑 `docaudit all --strict --baseline`（Phase B PR-2） | T2 合并门禁 |

**修改 `.claude/settings.json` 绑定时**：同步更新 §3 表格。新增 hook 须在 `.claude/hooks/` 建 `.sh` + 本表登记 + 注释风险等级。

---

## 4. 治理类 Skill `allowed-tools` 矩阵

本表只覆盖会影响流程、审计、合并门禁的项目治理 skill（与 §1 Tier 交叉），不覆盖全部 `.claude/skills/` 社区/领域 skill。Skill 目录所有权、计数口径和迁移规则见 `skill-architecture.md`；社区/领域 skill 的权限以各自 `SKILL.md` frontmatter 为准。如果某个 skill 被提升为门禁、审计或流程权威源，必须纳入本表。

**当前 skill 计数口径（2026-05-18）**：
- Distinct 一层 skill 名称：54 个（`.claude/skills` 54 个 discovery entries，含 3 个 symlink entries；`.agents/skills/*/SKILL.md` 8 个；重复共享入口 8 个）
- 项目治理 skill：14 个（下表列出）
- 社区/领域 skill：40 个（32 个仍为 Claude-only，8 个已共享）
- `.agents/skills/*/skills/*/SKILL.md` 是插件包 payload，不计入一层可触发 skill；`skills-lock.json` 只追踪 `.agents/skills/` 下 3 个受管跨 agent skill，不追踪 `.claude/skills/` 的 Claude adapter / symlink discovery entries。详见 `skill-architecture.md`。

| Skill | Read | Grep | Glob | Edit | Write | Bash | WebSearch | WebFetch | Agent | Tier 覆盖 |
|---|---|---|---|---|---|---|---|---|---|---|
| `cross-audit` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | ✅ | T1+T2+Agent 委派 |
| `cross-audit-consensus` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2 |
| `phase-closeout` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2 |
| `resume-from-handoff` | ✅ | ✅ | ✅ | — | — | ✅ | — | — | — | T1+T2 读取 |
| `post-merge` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | T1+T2 |
| `sprint-contract` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2 |
| `api-research` | ✅ | — | — | — | — | ✅ | ✅ | ✅ | — | T1+T2（研究只读） |
| `verify-audit-report` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | T1+T2 |
| `dependency-propagation` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | T1+T2 |
| `knowledge-health` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2（只产 plan，不改 workspace 文件） |
| `harness-recall` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2（只 propose，不自动改规则） |
| `dod-checklist` | ✅ | ✅ | ✅ | — | — | ✅ | — | — | — | T1+T2（只读+检查，不改文件） |
| `decision-closeout` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | T1+T2 |
| `xcode-review` | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | — | — | T1+T2 |

**原则**：
- 研究类 skill（cross-audit / consensus / phase-closeout）允许 Write 但落地到 `~/.claude/plans/` 或 `docs/archive/research/`
- 执行类 skill（post-merge / sprint-contract / dependency-propagation 等）开放 T2 完整集

**新增治理类 skill 或修改治理类 skill 的 `allowed-tools` 时**：必须同步本表并注明 Tier 覆盖。不遵守的治理类 skill 视为违反 §0 SSOT 纪律。

---

## 5. 审计方法

**本文档是 SSOT**。审计权限配置是否漂移：

```bash
# 对照 .claude/settings.json 与本文档 §3
jq '.hooks' .claude/settings.json

# 对照 block-dangerous-bash.sh 与本文档 §2
grep '^DANGEROUS_RE=' .claude/hooks/block-dangerous-bash.sh

# 对照治理类 skill allowed-tools 与本文档 §4
for skill in cross-audit cross-audit-consensus phase-closeout resume-from-handoff post-merge sprint-contract api-research verify-audit-report dependency-propagation knowledge-health harness-recall dod-checklist decision-closeout xcode-review; do
  sed -n '1,12p' ".claude/skills/$skill/SKILL.md"
done
```

若任一位置与本文档不符，**以本文档为裁决基准**（属工程纪律事实来源），但必须同 PR 内双向同步（或开 follow-up issue 补漂移）。

---

## 6. 未来扩展（不在本文档范围）

- 运行时 token 成本记录（PR-5 落一个最小 metrics hook）
- MCP 外部工具权限矩阵（待 Gmail / Calendar / Drive / openclaw 实际启用场景出现时补）
- Per-file 写权限控制（Claude Code 目前不支持细粒度；若未来支持，在此扩展）
