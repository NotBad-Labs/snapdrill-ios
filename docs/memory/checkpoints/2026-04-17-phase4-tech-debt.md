---
last_verified: 2026-05-13
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-17 Phase 4 Tech-Debt 清理

## Goal

Phase 4 三方审计 + P2/P3 sprint 收尾后，清理遗留 tech-debt Issue：ProfileListView 测试缺口（#638）、EditProfileView UX 反馈（#637）、swift-autolint hook bug（#666）。

## Done

| PR | 主题 | 关键改动 |
|---|---|---|
| #664 | `refactor: ProfileListView 抽 ViewModel + deleteProfile 错误路径单测 (Closes #638)` | 视图逻辑抽 `ProfileListViewModel`；新增 8 个单测覆盖删除错误路径 |
| #667 | `fix(hooks): swift-autolint 过滤文件级违规 (Closes #666)` | `.claude/hooks/swift-autolint.sh` 过滤 file_length / type_body_length 等文件级规则，避免单文件 lint 与全仓结果不一致 |

## Open

| PR | 主题 | 阻塞 |
|---|---|---|
| #665 | `fix: EditProfileView PhotosPicker 失败 UX 反馈 + 同图重选 (Closes #637)` | CI 绿 · 等 Xcode Review（UI 改动必经 F-017） |

## Decisions

- #638 测试补齐优先抽 ViewModel 而不是直接给 View 加测试：
  - **Why**：View 测试成本高（需 UITesting），ViewModel 纯逻辑更经济
  - **How**：deleteProfile 错误路径是核心漏洞点，VM 单测直接覆盖
- #666 swift-autolint 修复选方案 A（过滤文件级规则）而非方案 B（拆 LocalizationKeys）：
  - **Why**：方案 A 立即修复 hook 假阳性，方案 B 1503 行大文件拆分需独立规划
  - **How**：hook 只拦截行级违规，文件级规则由 CI 全仓跑统一验证
- #637 走 Xcode Review：PhotosPicker 失败反馈 + 同图重选属 UI 改动（F-017），不自审自批

## Risks

- #665 Xcode Review 反馈未知，可能需要二次修改
- LocalizationKeys.swift 1503 行（SwiftLint file_length 500 限）存量违规遗留，后续单 PR 拆分时可能引入合并冲突
- swift-autolint hook 在文件级规则上静默放行，依赖 CI 全仓校验兜底（不是本地拦截）

## Next

- #665 合并后 close #637
- LocalizationKeys 拆分（Issue #666 方案 B）独立 PR 排期
- Phase 4 整体收官：`docs/memory/handoff.md` + `STATUS.md` 同步（已随 PR #669 完成）
- Hermes 借鉴工作（#670 研究归档 + #671 规则 + skill + #672 script + hooks）
