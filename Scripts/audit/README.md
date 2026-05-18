# Scripts/audit — 知识体系审计引擎

> Phase B PR-1 交付物。把 Phase A 三方人肉审计转成每次 PR 都会跑的机械检查。

## 用途

检测项目知识体系（`docs/` + `.claude/` + `Scripts/`）的结构性漂移：

| 子命令 | 检查项 |
|---|---|
| `links` | Markdown 内部引用链接 broken |
| `archived-refs` | 对 `docs/research/*` (status: archived) 的活跃硬引用 |
| `orphans` | `docs/**/*.md` 在全仓零引用 |
| `home-path-refs` | 仓库内对 `~/.claude/` 私有路径的硬编码 |
| `rule-usage` | F-001~F-NNN 引用计数（识别 dead rule 候选） |
| `all` | 以上 5 项 + `frontmatter`（subprocess 调用 `Scripts/validate_frontmatter.py`），共 6 个检查 |

## 用法

```bash
# 跑单个子命令（每个子命令 --help 独立说明）
python3 Scripts/audit/docaudit.py links --help
python3 Scripts/audit/docaudit.py links

# 跑全部（含 frontmatter orchestrator）
python3 Scripts/audit/docaudit.py all

# CI 模式（warning 升 error，有任何命中就 exit 1）
python3 Scripts/audit/docaudit.py all --strict

# Report 模式（人类可读 summary + TSV 落盘到 reports/）
python3 Scripts/audit/docaudit.py all --report

# 基线模式（policy.yaml 的 legacy_whitelist finding 级豁免生效）
python3 Scripts/audit/docaudit.py all --baseline

# Verbose（详细显示每条 finding）
python3 Scripts/audit/docaudit.py all --verbose
```

**注意**：`--all` 已改为 `all` 子命令（argparse subparsers）。原 `--all` flag 已移除。

## 退出码

- `0` — 无 error 级命中（warning 仅提示）
- `1` — error 级命中（CI 会阻断）或 `--strict` 下 warning 升级
- `2` — 配置错误（policy.yaml 损坏、legacy_whitelist 规则无效、日期解析失败等）

## 策略源

[`policy.yaml`](policy.yaml) 是审计规则的 SSOT。修改检查级别（error / warning / info）或白名单只改这一个文件。

**设计原则**：策略与审计代码分离 —— 加新检查要改 docaudit.py，调整阈值只改 policy.yaml。这避免了"双重真相源"（规则散在脚本里 vs 文档里）。

## `legacy_whitelist`（finding 级 post-filter）

Phase C 清理前的过渡机制。**不是整类跳过**（那样会放过新增违规），而是按 finding 匹配豁免：

```yaml
legacy_whitelist:
  - check: archived-refs         # 必填
    reason: "Phase A 基线..."    # 必填（非空）
    expires_on: "2026-05-31"     # 必填（YYYY-MM-DD，无效日期 exit 2）
    paths:                       # 可选：glob 列表；空 = 匹配该 check 所有 findings
      - docs/workflow.md
      - docs/memory/**
    categories:                  # 可选：finding category 列表
      - active_reference
```

**关键性质**：
- 规则只在 `--baseline` flag 启用时生效
- 匹配命中 → finding 标记 `suppressed`，不参与 exit code，但仍在报告里可见
- **新增违规（不匹配任何白名单）仍按原级别阻断**，防止回归
- `expires_on` 硬截止：过期规则不生效（fail-closed），自动转严格
- 字段缺失 / 日期无效 → exit 2 + stderr 告警（**不 fail-open**）

Phase C 每个清理 PR 应从 `legacy_whitelist` 移除对应条目，直到全空。

## 与 `validate_frontmatter.py` 的关系

`Scripts/validate_frontmatter.py` 保留为独立 CLI（SRP）。`docaudit.py all` 以 subprocess 调用它作为 orchestrator step（而不合并源码）。这样：
- 单独跑 `python3 Scripts/validate_frontmatter.py --check` 接口不破坏
- `docaudit all` 可以一次跑完全部检查

## 输出

### 文本 summary（stdout，人类可读）

```
docaudit: 6 checks, 4 categories with findings

[frontmatter]          clean
[links]                clean
[archived-refs]        2 error
[orphans]              1 warning
[home-path-refs]       1 warning
[rule-usage]           3 info

Exit: 1 (error level in: ['archived-refs'])
```

**stderr 镜像**：有 warning/error 的 check 摘要会同时写 stderr（便于 CI 日志分离）。非零退出会追加 `docaudit exit N` 到 stderr。

### TSV 报告（`reports/<check>.tsv`，机器可读，CI artifact）

```
check    path    line    category    level    status    suggestion    suppressed_reason    matched
archived-refs    docs/workflow.md    201    active_reference    error    active    migrate reference to docs/archive/ or change to historical note: docs/research/harness-engineering-study-20260418.md        ...
archived-refs    docs/memory/handoff.md    118    active_reference    error    suppressed        Phase A 基线... (expires_on: 2026-05-31)    ...
```

`status` 列区分 active / suppressed；`suppressed_reason` 记录豁免规则理由与过期日期。

## Self-test

```bash
python3 -m unittest discover Scripts/audit/tests
```

覆盖每个活跃子命令 ≥ 2 用例（正向 + 命中）+ `legacy_whitelist` schema 边界（无效日期 / 缺 reason / 未知 check → exit 2）+ `--strict` 摘要一致性 + stderr 镜像 + frontmatter subprocess 降级路径。

## 首轮基线缓冲

`policy.yaml` 的 `legacy_whitelist` 当前仅保留 Phase A 孤儿候选 1 类过渡豁免。Phase C 每个清理 PR 同步从白名单移除对应条目，逐步收紧到全空。

## 信号链

本 PR-1 只提供引擎。完整信号链在 PR-2：

```
Edit docs/*.md          → PostToolUse hook      → 即时反馈（Claude session）
git push / PR merge     → PreToolUse hook        → 本地兜底（人类 + agent）
Pull Request            → CI docs job            → 门禁（ubuntu-latest）
对话调 /knowledge-health → skill                 → plan 文件（覆盖私有空间）
```

## 设计决策来源

- **Codex 主锚（Review Critical 1）**：`legacy_whitelist` 从"整类跳过"改为 finding 级 post-filter
- **Codex 主锚（Review Critical 2）**：`expires_on` 解析失败从 fail-open 改为 fail-closed
- **Codex 主锚（Review High）**：argparse subparsers / `--strict` 摘要一致性 / warning 镜像 stderr / validate_frontmatter subprocess 编排
- **Claude 子 agent（起草阶段）**：ubuntu-latest runner + skill 只产 plan（PR-2 落地）
- **Gemini（起草阶段）**：self-test 强制进 CI
- **Gemini Flash（Review 阶段）**：3 个 Markdown 正则鲁棒性 High（title / PATH_REF / basename），已开 follow-up Issue 于 Phase D 加固

详见 `~/.claude/plans/phase-b-consensus-20260421.md`。
