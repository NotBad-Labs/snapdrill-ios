# COPPA 2025 Final Rule 适用性评估备忘录

> 状态：**已完成** | 评估日期：2026-04-10 | 截止日：2026-04-22
> 三方独立评估（Claude/Codex/Gemini）后统一结论。

---

## 1. 产品定位

SnapDrill 是面向家庭教育场景的**练习题数字化存档效率工具**，不是教育内容分发平台。

- 不提供题库、课本、试卷或课程内容
- 所有内容由用户主动录入
- 核心价值链：采集 → 管理 → 导出/打印
- App Store 分类：Productivity / Education（工具属性）
- 年龄分级：4+（Unrestricted）
- Kids Category：**不申请**

## 2. 数据收集范围

| 数据类型 | 是否收集 | 存储位置 | 用户控制 |
|---|---|---|---|
| 题目内容（文字+图片） | 是 | 纯本地 | 用户完全控制 |
| 元数据（学科/标签/难度） | 是 | 纯本地 | 用户完全控制 |
| 用户昵称/头像 | 是 | 纯本地 UserDefaults | 用户完全控制 |
| 匿名使用统计 | 用户 opt-in 后 | Firebase Analytics | 设置页开关 |
| 匿名崩溃报告 | 用户 opt-in 后 | Firebase Crashlytics | 设置页开关 |
| 手机号/邮箱/姓名 | **不收集** | — | — |
| 学校/年级/位置 | **不收集** | — | — |
| IDFA | **不收集** | — | Not Tracking |

**零直接 PII**：不收集任何可识别个人身份的信息。无注册、无账号系统。

## 3. Persistent Identifier 处理

Firebase Analytics 在 opt-in 后处理 `app_instance_id`（app-scoped identifier）。在 COPPA 语境下属于 persistent identifier / personal information。

**防御措施**：
- `GoogleService-Info.plist` 中 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED = true`、`FirebaseCrashlyticsCollectionEnabled = false`
- 首次启动默认不采集，仅在用户设置中显式开启后启用
- 用户可随时关闭，关闭后等同纯本地模式
- ATT 授权链路已移除（ADR-002），NSPrivacyTracking = false
- 不做 behavioral advertising，不接入广告 SDK

## 4. Not Child-Directed 论证

按 FTC COPPA "directed to children" 6 因素逐项对照：

| 因素 | SnapDrill 评估 |
|---|---|
| Subject matter | 题目扫描/整理/导出/复习流程，不提供儿童娱乐或教育内容 |
| Visual content | 成熟、克制、家长友好，无低龄卡通或角色化包装 |
| Language / tone | 文案面向家长与中学生，强调效率/整理/隐私 |
| Activities | 拍照/OCR/编辑/导出/复习，无儿童社交或游戏化激励 |
| Characters / child appeal | 未使用儿童角色、动画 IP 或玩具化元素 |
| Advertising | 不做 behavioral advertising，不接入广告网络 |

**App Store 营销**：避免使用 "children" "kids" "儿童教育" 等措辞，强调"效率工具""数字化归档""家长和学生"。

**结论**：SnapDrill 属于 general-audience / mixed-audience utility app，不属于 child-directed app。

## 5. 隐私政策声明

App 内隐私政策包含"儿童隐私"章节：
> "SnapDrill 适合所有年龄段的用户使用。我们不会有意收集 13 岁以下儿童的个人信息。"

## 6. 证据清单

以下证据需截图留存至 `docs/tech/evidence/coppa/`：

- [ ] App Store Connect 年龄分级设置（4+，非 Kids Category）
- [ ] Privacy Manifest（NSPrivacyTracking = false）
- [ ] GoogleService-Info.plist（DEACTIVATED = true）
- [ ] 设置页 Analytics/Crashlytics 开关截图
- [ ] App 首页截图（体现工具属性，非儿童导向）
- [ ] 隐私政策"儿童隐私"章节截图

## 7. 合规确认

基于以上评估，SnapDrill 在 FTC COPPA 2025 Final Rule（2026-04-22 生效）下：

- 不属于 child-directed service
- 不触发 verifiable parental consent (VPC) 要求
- persistent identifier 通过"默认不采集 + 用户 opt-in"机制控制
- ATT 已移除，Privacy Manifest 声明 Not Tracking

**状态**：已完成 | **最近复核**：2026-04-10

---

> 本文档属于工程/产品合规评估，不替代正式法律意见。
> 如 App Store 审核或法律咨询认为需更严格合规，再评估 Declared Age Range API 集成或 Analytics 默认关闭。
