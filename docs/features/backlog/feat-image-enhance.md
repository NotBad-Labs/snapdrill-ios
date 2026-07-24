---
id: feat-image-enhance
title: 图片处理增强（去手写 / 去批改痕迹 / 试卷还原）
status: backlog
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
intent_refs:
  - vision:P3
  - vision:P4
release_refs:
  - release-1:C2-Optional
---

# Feature: 图片处理增强（去手写 / 去批改痕迹 / 试卷还原）

> 人读摘要：🧪 待实现 / 需 PoC，产品范围与商业分层未定。派生自上方 frontmatter；frontmatter 仅是本功能候选实现状态的单一来源，不构成产品批准或发布承诺。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business 聚合（docs 重组 B）。
> `mode: lightweight`：尚未实现且需第三方端上方案 PoC，How / Verify 待 PoC 落地后补，**不为未实现功能编造假设计**。
>
> **商业规范偏差（2026-07-12）**：Product Vision & Principles B6-A 已取代旧“免费限次 + Pro 无限”分层，frontmatter 已改为 `tier: undecided`。技术 PoC 也不能替代外部价值证据、商业裁决与 Release PRD。

## 1. 候选价值假设 (Why)

- 去除试卷或资料图片上的手写 / 批改痕迹，可能让部分用户更方便地重新打印干净副本。
- 当前没有外部使用或付费证据，也没有达到门槛的端上 PoC；它不是核心闭环、Release 1 或 Pro 承诺。
- 若未来回归，必须端上处理、不得上传用户图片，并与布局层“隐藏答案字段”明确分离。

## 2. 候选范围与重入条件 (What)

- 候选能力是对资料图片做去手写、去批改痕迹或试卷还原；具体模型、准确率、交互和输出质量等待 PoC 与 shaping。
- 当前不存在限次体验、Pro 无限、配额或 upsell 产品规则；Release 1 不显示门后“敬请期待”或升级入口。
- **边界 / 不做**：
  - **不做云端图片处理**（违反 P4 隐私，图片不得上传服务端）。
  - 与"去答案打印"（隐藏答案字段、布局层面操作）是不同层面，不合并、不混淆。
- **前置依赖**：
  - **第三方端上方案 PoC**：Go 条件 = 端上方案可用、SDK < 50MB、去手写准确率 ≥ 80%；No-Go = 所有方案均需云端或准确率 < 60%。
  - **产品重入**：外部价值证据、PO 新裁决、Release PRD 与隐私 / 第三方依赖复核缺一不可；StoreKit issue 不能自行授权实现。
- **商业政策**：B6-A 下当前无有效 Pro 层；未来商业化未裁决。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
> 待实现 / PoC 阶段填。

- **当前已确定的技术约束**：
  - **端上离线处理**：必须使用离线方案，图片不得上传服务端（P4 隐私铁律）。
  - **SDK 体积约束**：第三方方案 SDK < 50MB，避免 App 体积膨胀。
  - **第三方库合规**：纳入后需在开源许可页展示对应第三方库。
- **模块归属 / 关键机制 / State & Concurrency / 设计裁决**：待 PoC 选型确定第三方端上方案后补。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
> 待实现 / PoC 阶段填。

- 当前唯一可断言的行为约束：Release 1 不显示该候选能力或升级提示；基础导出不受其影响。
- 完整 Success path / 边界异常 / 数据保证 / NFR 待 PoC 落地后补。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../product/vision.md`（P3 免费层完成核心闭环 / P4 用户拥有数据·隐私） | 增值能力不锁基础；端上处理、图片不上传服务端 |
| Release 1 PRD | `../../product/release-1-prd.md` C2-Optional | §3.2 将图片增强列为 hidden / out of scope；不得伪引 §7，也不表示当前候选获准纳入 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 当前无有效 Pro、配额或 upsell；与布局层去答案保持独立 |
| 待验证假设 | `../../explanations/business-model.md` H8 | 先以 PoC + 外部使用证据验证价值，不预设转化 |
| 验收证据 | 等待端上 PoC、外部价值证据与新 contract（backlog lightweight） | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../product/vision.md`（P3 免费层完成核心闭环 / P4 数据属于用户·隐私）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 历史决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（已被 B6-A 取代）
- 相关 feature：`feat-smartpaper.md`（独立候选）、`../active/feat-export.md`（"去答案打印"为不同层面的基础导出能力）
