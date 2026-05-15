---
last_verified: 2026-05-11
layer: decision
---
# ADR-003: 文档 frontmatter 从 HTML 注释迁移到 YAML

> 状态：**已决策** | 日期：2026-04-17 | 决策者：PO | 落地：PR #656 (ADR) + PR #657 (文件迁移) + PR #658 (校验门)
>
> ⚠️ 注：本文档是 2026-04-17 决策时的历史记录。文中"39 个 md 文件""12 个 rules"等数字反映决策时的规模。当前实际文件数量已有变化（产品文档新增 journeys/analytics/onboarding/competitive-analysis，rules 新增 memory-routing/review-prompt-guide），不影响决策的有效性。

## 背景

SnapDrill 文档体系当前 `docs/` 下 39 个第一方 md 文件统一采用 HTML 注释 frontmatter：
```
<!-- last_verified: YYYY-MM-DD -->
<!-- layer: pattern -->
<!-- freshness: max_age_days=30, decay_trigger=[event] -->
```

而 `.claude/rules/` 下 12 个 md 文件已是 YAML frontmatter（PR #648 标准化），形成全仓双格式分裂。

文档体系三方独立审计（2026-04-17，`~/.claude/plans/doc-audit-summary.md` I2 项）共识结论：
1. HTML 注释不是机器可读标准，需要项目自定义 parser
2. Jekyll / GitHub Pages / mkdocs 等业界工具默认支持 YAML frontmatter
3. 双格式分裂导致 grep 查询、validate 校验都需要适配两套语法

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A. 保留 HTML 注释 | 维持现状 | 零改动 | 双格式分裂持续；无法用业界标准工具 |
| B. 全仓回退到 HTML 注释 | `.claude/rules/` 也回退 | 一致 | 反潮流，丢失业界工具支持 |
| **C. 全仓迁移到 YAML（39 文件）** | **`docs/` 下全部迁移，与 `.claude/rules/` 对齐** | **机器可读、业界标准、消除分裂** | 一次性大改，需 validate 脚本 + pre-commit/CI 挂接 |

## Schema 决策

```yaml
---
last_verified: YYYY-MM-DD          # ISO 8601 日期，必填
layer: principle | pattern | snapshot | archive | decision    # 5-layer 枚举，必填
freshness:                          # snapshot / archive 建议有
  max_age_days: integer            # ≥1
  decay_trigger: [event1, event2]  # 字符串数组
status: active | archived | deprecated  # 可选，默认 active
reason: string                     # 可选；status≠active 时建议
---
```

### 字段取值域

| 字段 | 类型 | 必填 | 取值域 |
|---|---|---|---|
| last_verified | date | ✓ | `YYYY-MM-DD` |
| layer | enum | ✓ | principle / pattern / snapshot / archive / decision |
| freshness.max_age_days | int | snapshot/archive 建议 | ≥1 |
| freshness.decay_trigger | array | 随 max_age_days | 字符串数组 |
| status | enum | 可选 | active / archived / deprecated |
| reason | string | 可选 | 自由文本 |

### 设计要点

- **新增 `decision` layer**：ADR 文件本质是"已决策事实"，既不属于原则/模式/快照，也不属于归档。当前 `docs/decisions/ADR-*.md` 无 frontmatter，需补齐
- **新增 `archive` layer**：archive 目录文件位置归属与 status 维护状态分离（layer=archive + status=archived 是两层语义）
- **freshness 仅 snapshot/archive 必要**：principle/pattern 半衰期长（>6 个月），无需强制 max_age_days

## 三方研究摘要

Claude Opus 4.7 / Codex GPT-5.4 / Gemini 3 三方独立产出 schema + 迁移脚本 + validate 脚本。共识：
- 5-layer schema（Claude 提议，Codex 同意）
- Python 3 + argparse + 幂等 + dry-run
- pre-commit + CI 双层挂接

分歧（含 Gemini 幻觉，已记录到私有记忆）：
- Gemini 提出额外字段（如 `tags: []`），Claude/Codex 都认为 YAGNI
- Codex 倾向脚本用 PyYAML 强依赖；Claude 提供 stdlib 回退方案（无 PyYAML 也可运行）

详细对比表见 `~/.claude/plans/phase4-p1-adversarial-summary.md`。

## 决策

**采用方案 C：全仓迁移到 YAML，5-layer schema**。

## 方案

1. **一次性迁移**：`Scripts/migrate_to_yaml_frontmatter.py --apply`，39 文件批量替换
2. **新增 validate 脚本**：`Scripts/validate_frontmatter.py --check` 做 schema 校验
3. **pre-commit hook 挂接**：`.git/hooks/pre-commit` 增量校验（只检查 staged docs/*.md）
4. **CI 全量校验**：`.github/workflows/ci.yml` 独立 step，在 swiftlint 之后
5. **`docs/decisions/ADR-*.md` 补 frontmatter**：layer=decision
6. **`docs/archive/timeline.md` 规范化**：当前 `<!-- freshness: ..., layer=snapshot -->` 嵌套格式异常，需拆分

## 回退方案

按 PR 粒度独立回退，三个 PR 解耦：

1. **校验门** (#658)：`git revert <sha>` 仅关闭 pre-commit + CI step；docs 仍是 YAML，新文档不再强制
2. **文件迁移** (#657)：`git revert <sha>` 回退 39 文件到 HTML 注释；与 #658 解耦，可单独回退
3. **ADR 自身** (#656)：通常不需要回退；保留作历史决策记录

**数据风险**：纯文档变更，无 SwiftData / 用户数据迁移。回退仅影响仓库内 frontmatter 格式与 CI 行为，无运行时影响。

**判断标准**：若仅 CI 误报频繁 → 先 revert #658；若 GitHub Pages / 第三方工具与 YAML 不兼容 → revert #657 + #658。

## 验收

- [ ] `grep -l '^<!-- last_verified' docs/` 返回 0 行
- [ ] `Scripts/validate_frontmatter.py --check` 对 39 文件退出码 0
- [ ] 故意破坏一个文件 frontmatter，`validate_frontmatter.py` exit 1
- [ ] pre-commit 拦截破坏性 commit
- [ ] CI 独立 step 生效
- [ ] GitHub 网页渲染 Markdown 无异常（YAML frontmatter 是 Jekyll 标准，原生隐藏）

## 后果

- 全仓文档 frontmatter 格式统一（YAML）
- 所有现有 grep `<!-- last_verified` 查询点需改为 `grep '^last_verified:' docs/`
- 新文档创建时必须使用 YAML 格式，由 pre-commit/CI 强制
- 后续若引入 mkdocs / Jekyll 静态站点，frontmatter 已就绪
- ADR-TEMPLATE 同步加入 layer=decision frontmatter（PR-J 暂不做，但新建 ADR 时手动加）

## 相关

- `Scripts/migrate_to_yaml_frontmatter.py`（已实现，方案见 `~/.claude/plans/adversarial-t05-06-claude.md` §2）
- `Scripts/validate_frontmatter.py`（已实现，方案见同 §4）
- `.git/hooks/pre-commit`（增量挂接）
- `.github/workflows/ci.yml`（CI step 新增）
- docs/ 下 39 md 文件（全部迁移）
- 三方对抗起草报告：`~/.claude/plans/phase4-p1-adversarial-summary.md`
