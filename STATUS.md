---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-20（**文档体系深度清洁 Phase 0-9 收官**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）

## 当前状态（2026-05-20）

**文档体系深度清洁 Phase 0-9 结构层收官**（2026-05-20，共识基线 commit `4883d6b6`，Gemini 全周期 FULL PASS）。方法论沉淀在 `docs/decisions/ADR-004-doc-system-deep-clean.md`。

⚠️ **本轮仅覆盖结构层**（frontmatter/链接/计数/算术/docaudit 全绿）。**语义层审计**（跨文档语义链条、反向溯源、standards 约束力、skill description↔body、F-rule 实际遵守度）作为 **Phase 10** 独立立项，详见 ADR-004 backlog 段，预计新建 ADR-005。

- **Phase 0-2**：52-doc 审计接管 + SSOT 自洽 + 三方 verdict 裁决 + NEEDS_REVISION 修订
- **Phase 3**：跨文档 contradiction / ghost ref / orphan 横向扫描 + Codex 二意见
- **Phase 4**：治理升级 — docaudit 扩展到 11 check + ADR-004
- **Phase 5/7**：剩余 132+ 文件全量补审 + 10 处修复
- **Phase 8**：73 文件真全文 Read 补审 4 latent finding
- **Phase 9**：snapshot-testing 拆出嵌入第二 frontmatter 为独立 `snapshot-diff-review` skill

audit-ledger 现状（`docs/audits/audit-ledger-2026-05.tsv`，元信息见 `docs/audits/README.md`）：**224 行**（Round 9 全集覆盖补审 + Codex 反馈矫正后，含 14 governance + 11 构建/CI/meta + 7 Codex 盲区补审 + 2 真 bug 修复 + 2 dead duplicate 标 stale）；Final_Decision: VALID 184 / VALID_WITH_GAP 29 / STALE_OR_INVALID 11；Confidence 全部 RESOLVED；Codex 已 Round 1-9 独立验证（Round 9 矫正 4 verdict + 补 7 盲区）；Gemini 全周期最终复核待用户触发。

**Skill 体系**：52 个 distinct 一层 skill（15 项目治理、21 Claude-only 领域 skill、16 共享 skill）。SSOT：`docs/standards/skill-architecture.md`。

| 外部阻塞项 | 说明 | 状态 |
|---|---|---|
| Apple 开发者账号 (#163 链) | $99 年费待缴 | 用户控制 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 待真机验证 |

### Apple 账号阻塞链

| Issue | 内容 |
|---|---|
| #163 | 公司 Apple 开发者账号 |
| #479 | StoreKit 付费墙 |
| #485 | iCloud CloudKit 同步 |
| #161 | TestFlight Build 6 |

## 产品决策索引

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | ADR-002 |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | ADR-001 |
