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
| `rule-pointer-sync` | `.claude/rules/*.md` 与 `docs/principles/*.md` 映射完整性 |
| `rule-usage` | F-001~F-NNN 引用计数（识别 dead rule 候选） |

## 用法

```bash
# 跑单个子命令
python3 Scripts/audit/docaudit.py links

# 跑全部（按 policy.yaml 分级）
python3 Scripts/audit/docaudit.py --all

# CI 模式（有 error 级命中就 exit 1）
python3 Scripts/audit/docaudit.py --all --strict

# Report 模式（人类可读 summary + TSV 落盘到 reports/）
python3 Scripts/audit/docaudit.py --all --report

# 基线模式（policy.yaml 的 legacy_whitelist 生效，Phase C 清理前使用）
python3 Scripts/audit/docaudit.py --all --strict --baseline
```

## 退出码

- `0` — 无 error 级命中
- `1` — error 级命中（CI 会阻断）
- `2` — 配置错误（policy.yaml 坏了）

## 策略源

[`policy.yaml`](policy.yaml) 是审计规则的 SSOT。修改检查级别（error / warning / info）或白名单，只改这一个文件。

**设计原则**：策略与审计代码分离 —— 加新检查要改 docaudit.py，调整阈值只改 policy.yaml。这避免了"双重真相源"（规则散在脚本里 vs 文档里）。

## 与 `validate_frontmatter.py` 的关系

`Scripts/validate_frontmatter.py` 继续作为独立 CLI 保留（SRP）。docaudit 不重写它的逻辑，未来可能以 subprocess 调用作为编排步骤。

## 输出

**文本 summary**（stdout，人类可读）：

```
docaudit: 6 checks, 3 categories with findings

[links]              0 broken
[archived-refs]      20 references to archived docs
[orphans]            1 orphan candidate
[home-path-refs]     41 references to ~/.claude/
[rule-pointer-sync]  0 mismatches
[rule-usage]         4 rules with 0 external references (dead candidates)

Non-zero in: [archived-refs, orphans, home-path-refs, rule-usage]
Exit: 1 (error level: archived-refs)
```

**TSV 报告**（`reports/<check>.tsv`，机器可读，CI artifact）：

```
check    path    line    category    level    suggestion
archived-refs    docs/workflow.md    201    active_reference    error    migrate to docs/archive/research/
```

## Self-test

```bash
python3 -m unittest discover Scripts/audit/tests
```

测试覆盖每个子命令 ≥ 2 用例（正向 + 命中）+ policy.yaml 分级切换 + legacy_whitelist 豁免。

## 首轮基线缓冲

`policy.yaml` 的 `legacy_whitelist` 字段允许 Phase A 已发现的历史违规豁免。Phase C 每个清理 PR 应同步从白名单移除对应条目，逐步收紧。

## 信号链

本 PR-1 只提供引擎。完整信号链在 PR-2：

```
Edit docs/*.md       → PostToolUse hook     → 即时反馈
git push / PR merge  → PreToolUse hook      → 本地兜底
Pull Request         → CI docs job          → 门禁
对话调 /knowledge-health → skill            → plan 文件
```

## 设计决策来源

- Codex 主锚：组件划分 + policy.yaml SSOT + workflow 处置协议（后续 PR-3）
- Claude 子 agent：PostToolUse hook + ubuntu-latest runner + skill 只产 plan（PR-2）
- Gemini：self-test 强制进 CI

详见 `~/.claude/plans/phase-b-consensus-20260421.md`。
