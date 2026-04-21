---
last_verified: 2026-04-21
layer: pattern
---
# 知识/记忆路由规则

> 决定一条新知识/记忆该写到哪里。来源：Hermes agent 研究借鉴（2026-04-18，`docs/research/hermes-agent-study-20260418.md`）。

## 路由决策表

按"内容类型 × 半衰期 × 共享范围"三维路由：

| 内容类型 | 半衰期 | 共享范围 | 目标位置 | 例子 |
|---|---|---|---|---|
| 产品定位、原则、价值链 | >2 年 | 公开 | `docs/product/product-vision.md` | "数据属于用户" |
| 商业模式、定价、竞品 | 6-24 个月 | 公开 | `docs/product/product-business.md` | Pro 订阅价格 |
| 功能规格、用户旅程 | 6-24 个月 | 公开 | `docs/product/product-requirements.md` | "PDF 导出支持去答案" |
| 技术架构、Package 边界、DI | 6-24 个月 | 团队 | `docs/tech/architecture.md` | "Core 不依赖 Data" |
| 内部 API 签名 | <6 个月 | 团队 | `docs/tech/api-reference.md` | `OCRServiceProtocol` |
| 工程哲学、纪律 | >2 年 | 团队 | `docs/principles/engineering.md` 等 | 奥卡姆剃刀 |
| 项目纪律 / 反馈教训 | 6-24 个月 | 团队 | `docs/memory/feedback.md` | F-008 |
| 工程决策（非 ADR 级） | 6-24 个月 | 团队 | `docs/memory/decisions.md` | 模块拆分理由 |
| ADR / 产品/架构决策 | >2 年 | 团队 | `docs/decisions/ADR-NNN-*.md` | ADR-001 智能组卷定价 |
| 当前接手状态、阻塞、下一步 | <1 周 | 团队 | `docs/memory/handoff.md` | "当前分支 / 待合并 PR" |
| 项目状态看板 | <1 周 | 团队 | `STATUS.md` | 测试基线 / Open PR |
| Phase checkpoint | <1 月 | 团队 | `docs/memory/checkpoints/<YYYY-MM-DD>.md` | "Phase 4 收官 19 PR" |
| 用户偏好（称呼/语言） | >2 年 | **私有** | `~/.claude/.../memory/MEMORY.md` | "称呼帅哥 / 中文回复" |
| Claude 私有反馈/教训 | 6-24 个月 | **私有** | `~/.claude/.../memory/feedback_*.md` | "Gemini 幻觉风险" |
| 一次性研究产物 | 归档 | 团队 | `docs/research/<topic>-<date>.md`（layer: archive） | Hermes 研究报告 |
| 审计原始报告 | 归档 | 团队 | `docs/archive/<topic>-<date>.md` 或 `~/.claude/plans/` | 文档审计原始报告 |
| docaudit 机械命中报告 | 一次性 | 团队 | `reports/<check>.tsv`（不入 git，CI artifact） | Scripts/audit/docaudit.py --report 输出 |
| /knowledge-health 体检 plan | <1 月 | **私有** | `~/.claude/plans/knowledge-health-<YYYY-MM-DD>.md` | docaudit 全量 + 私有空间扫描分层修复建议 |

## 决策原则

1. **公开 vs 私有** 优先：影响多智能体协作的 → docs/；只影响 Claude 个人体验的 → 私有 memory
2. **半衰期** 决定 layer：>2 年 principle / 6-24 个月 pattern / <6 个月 snapshot / 一次性 archive
3. **去重** 优先：先 grep 是否已有归属，能合并就不新建
4. **指针** 优先：跨文件引用用相对路径指针，不复制原文（参考 PR-D F-008 去重）

## 反模式

- ❌ 把"用户偏好称呼帅哥"写到 `docs/`（应在私有 memory）
- ❌ 把 ADR 决策只写到 `STATUS.md`（应建 ADR-NNN 文件）
- ❌ 把"今天遇到的 bug 修法"写到 `docs/principles/`（应在 `docs/memory/decisions.md`）
- ❌ 把临时 checkpoint 写到 `docs/memory/feedback.md`（应在 `docs/memory/checkpoints/`）

## 创建新文件前自查

- [ ] 现有 docs/ 下有没有类似归属？
- [ ] 是否真的需要新文件？还是扩展现有段落即可？
- [ ] frontmatter 三件套是否齐：`last_verified` + `layer` + 必要时 `freshness`
- [ ] 新文件是否更新到 `docs/KNOWLEDGE_MAP.md`？

## 与 KNOWLEDGE_MAP.md 的关系

`KNOWLEDGE_MAP.md` 是**索引**（已有什么文件、各属哪层）。本文档是**路由规则**（新内容该去哪个文件）。两者互补。
