---
last_verified: 2026-06-11
layer: pattern
freshness:
  max_age_days: 180
  decay_trigger: [privacy_policy_change, app_review_change]
audit_note: 2026-05-19 验证 — 本文件已 skill 化为指针；权威执行在 privacy-manifests skill + app-store-rejection skill
---
# 隐私合规

> [!NOTE]
> **美国全球版 Pivot 说明 (2026-06-10)**
>
> 鉴于项目整体已 Pivot 至美国全球版（`com.snapdrill.global`，Team J58U72W335），中国大陆版构建与发布已挂起。本隐私合规说明已做对应收窄，将原“双区域/国内版 Firebase-Free”口径统一迁移并收窄至**“全球版零采集、本地优先”**的合规框架，详细分析决策见 [ADR-005](file:///Users/yiming/Developer/snapdrill-compliance/docs/decisions/ADR-005-analytics-privacy-strategy.md)。

> [!IMPORTANT]
> **通用效率工具定位与通用受众论证 (2026-06-11)**
>
> 配合 2026-06-11 PO 决策，本产品定位由“儿童教育”正式调整为**通用效率工具**。其核心用途为协助所有学习者、专业人士或考试人员扫描、归档和数字化整理其所需的各类题目与文档（包含但不限于职业证书、竞赛卷、培训讲义、发票票据等）。此定位在法律上确立了本应用的 **General-Audience (通用受众)** 属性，从而稀释了 COPPA 等儿童隐私法规的强监管风险。本产品的合规口径统一基于此通用受众与端侧零采集逻辑展开。


> 本文件为合规口径索引，**不是权威实现**：
>
> - 隐私清单（PrivacyInfo.xcprivacy）实现详见 `privacy-manifests` skill
> - App Review 拒审处理详见 `app-store-rejection` skill
> - ATT 移除决策详见 `../decisions/ADR-002-remove-att-authorization.md`

## 核心口径

- 数据最小化：仅收集功能必需的数据
- 用户控制：数据导出/删除由用户自主
- 透明：PrivacyInfo.xcprivacy 声明所有 API 使用理由
- Declared Age Range API（iOS 26+）：后续评估

## 关联文档

- `vision.md` — 产品定位与数据伦理
- `business-model.md` — 商业模式与隐私承诺
- `../decisions/ADR-002-remove-att-authorization.md` — ATT 移除决策

## 版权合规边界

> 本节于 2026-05-29 自 `vision.md` 迁移（vision 瘦身重构：vision 只留 why，本类规格归本文档）

SnapDrill 不提供题库、教材、试卷或任何第三方内容。所有题目由用户主动录入，存储在本地，App 不公开分发用户内容。

用户翻拍教材、试卷、教辅等受版权保护的材料是个人使用行为，SnapDrill 作为工具提供方：
- 不鼓励、不引导用户翻拍受版权保护的内容
- 不提供"题库分享"或"公开上传"功能
- 导出功能面向个人使用场景（打印练习、换机迁移），不面向公开传播

如果收到版权方投诉或 App Store 审核质疑，以"纯本地工具 + 用户自有内容 + 不公开分发"为边界回应。若未来引入社区或分享功能，需重新评估版权风险。
