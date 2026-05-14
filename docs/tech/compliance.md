---
last_verified: 2026-05-14
layer: pattern
---
# SnapDrill 数据合规

> 集中记录隐私合规策略、数据处理流程、合规认证状态。
> 产品承诺见 `../product/product-vision.md`，用户可见规格见 `../product/product-requirements.md`，商业化定位见 `../product/product-business.md`。

---

## 隐私架构

### 数据收集范围

| 数据类型 | 是否收集 | 存储位置 | 用户控制 |
|---|---|---|---|
| 题目内容（文字+图片） | 是 | 纯本地（App Sandbox） | 用户完全控制 |
| 学科/标签/难度等元数据 | 是 | 纯本地 | 用户完全控制 |
| 用户昵称/头像/座右铭 | 是 | 纯本地 UserDefaults | 用户完全控制 |
| 匿名使用统计 | 首次启动默认不采集，用户 opt-in 后启用（可随时关闭） | Firebase Analytics（Google 服务器） | 设置页开关 |
| 匿名崩溃报告 | 首次启动默认不采集，用户 opt-in 后启用（可随时关闭） | Firebase Crashlytics（Google 服务器） | 设置页开关 |
| 手机号/邮箱/姓名 | **不收集** | — | — |
| 学校/年级/位置 | **不收集** | — | — |
| 广告标识符（IDFA） | **不收集** | — | App 声明 Not Tracking |

### 默认零身份信息收集

SnapDrill 默认不收集个人信息：无需注册、不要求姓名、手机号、学校或年级。
匿名使用统计仅在用户明确授权后启用，启用后生成随机应用标识符（Firebase Installation ID），不关联真实身份。
注意：COPPA §312.2 将 persistent identifier 列为 personal information，因此不宜使用"零 PII"的绝对化表述。

---

## Apple 合规

### App Store 年龄分级

- **分级**：4+（Unrestricted）
- **Kids Category**：不申请（使用 Firebase SDK，技术上属于第三方 SDK）
- **Declared Age Range API**（iOS 26+）：后续评估（当产品进入未成年人敏感场景或引入相关流程时）

### Apple Privacy Manifest

| 声明项 | 状态 |
|---|---|
| NSPrivacyTracking | false（静态，不追踪） |
| NSPrivacyTrackingDomains | 空数组（不追踪 = 无需声明域名） |
| NSPrivacyCollectedDataTypes | Analytics（匿名事件计数）、Crash Data（匿名堆栈）、OtherDiagnosticData |
| NSPrivacyAccessedAPITypes | UserDefaults（AppStorage）、FileTimestamp（文件管理）、DiskSpace、SystemBootTime |

### Tracking 姿态

- App 在 Privacy Manifest 中声明 `NSPrivacyTracking = false`，当前产品口径为 **Not Tracking**
- ATT 授权链路已移除（ADR-002）：不弹 ATT 弹窗，NSPrivacyTracking = false
- 当前源码未检出 IDFA / `ASIdentifierManager` / `advertisingIdentifier` 的直接读取代码；题目内容不用于第三方广告画像或 behavioral advertising
- Analytics / Crashlytics 为匿名遥测，用户可在设置中关闭；数据收集开关由 `AppConfiguration.FeatureFlags.analyticsEnabled` 与 `crashReportingEnabled` 控制

---

## COPPA / GDPR-K 年龄合规分析

### 用户年龄与实际使用路径

SnapDrill 的目标场景是家庭教育中的练习题数字化存档，真实使用人群分三层：

- **小学阶段（约 7-8 岁起）**：通常不独立使用手机，实际操作者是家长
- **初中阶段（约 12-15 岁）**：学生开始独立使用，家长可能辅助
- **高中阶段（约 15-18 岁）**：学生独立使用为主

SnapDrill 不是"默认面向低龄儿童独立使用"的产品；更准确的描述是：**面向家长与中学生的原生效率工具**，并覆盖"家长替低龄孩子录题"的家庭场景。

### 产品属性判断

SnapDrill 的产品定位是 efficiency tool，而不是内容型 education service：

- 不提供教材、书籍、题库、试卷或课程内容
- 不做内容分发、推荐算法、社交互动、儿童社区或儿童广告
- 所有题目图片、OCR 文本、答案、标签与分类数据，均由用户主动录入
- 产品核心价值是"采集 → 管理 → 导出/打印"，而不是向儿童提供内容消费体验

### Firebase `app_instance_id` 与 persistent identifier 分析

虽然 SnapDrill 不收集 name / email / phone 等直接身份信息，但启用 Firebase Analytics 时，SDK 会处理 `app_instance_id` 一类的 app-scoped identifier：

- 它不直接识别真实姓名，但可在一段时间内识别同一 app instance
- 在 COPPA 语境下，persistent identifier 属于 personal information 范畴
- 在 GDPR 语境下，这类 identifier 更接近 pseudonymous personal data

因此不能简单写成"零 PII = 与儿童隐私规则无关"。更准确的表述：核心离线功能接近"无 personal data 外发"的本地工具路径；启用 Firebase 的遥测路径仍需按 persistent identifier 风险管理。

### COPPA `directed to children` 标准逐项对照

| 因素 | SnapDrill 评估 |
|---|---|
| Subject matter | 题目扫描/整理/导出/复习流程，不提供儿童娱乐或教育内容 |
| Visual content | 成熟、克制、家长友好，不采用低龄卡通或角色化包装 |
| Language / tone | 文案面向家长与中学生，强调效率/整理/隐私 |
| Activities | 拍照/OCR/编辑/导出/复习，不含儿童社交或游戏化激励 |
| Characters / child appeal | 未使用儿童角色、动画 IP 或玩具化元素 |
| Advertising | 不做 behavioral advertising，不接入广告网络 |
| Empirical audience | 小学阶段家长是操作者，中学生可独立使用（mixed household use） |
| App Store classification | 不申请 Kids Category，4+ 年龄分级 |

结论：SnapDrill 更接近 general-audience / mixed-audience utility app，不宜自我表述为 child-directed app。

### FTC 2025 Final Rule 的影响

FTC 于 2025-04-22 发布 COPPA Final Rule amendments，合规落地截止日为 **2026-04-22**。对 SnapDrill 的影响：

- 影响存在但有限（不做广告、不开儿童社交、不收集账号身份信息）
- 需关注第三方 persistent identifier 与产品定位表述的一致性
- 若未来进入 COPPA 适用区间，新规带来的额外压力主要在：third-party disclosure 说明、persistent identifier 约束、信息安全与数据保留要求
- 合规状态：**已完成** | 最近复核：2026-04-10
- 截止日：2026-04-22
- ATT 代码已移除（ADR-002，PR #577）

### COPPA 合规确认

基于以上评估，SnapDrill 在 FTC COPPA 2025 Final Rule（2026-04-22 生效）下：
- 不属于 child-directed service
- 不触发 verifiable parental consent (VPC) 要求
- persistent identifier 通过"默认不采集 + 用户 opt-in"机制控制
- ATT 已移除，Privacy Manifest 声明 Not Tracking

### 证据清单

以下证据需截图留存至 `docs/tech/evidence/coppa/`：
- [ ] App Store Connect 年龄分级设置（4+，非 Kids Category）
- [ ] Privacy Manifest（NSPrivacyTracking = false）
- [ ] GoogleService-Info.plist（DEACTIVATED = true）
- [ ] 设置页 Analytics/Crashlytics 开关截图
- [ ] App 首页截图（体现工具属性，非儿童导向）
- [ ] 隐私政策"儿童隐私"章节截图

> 本节属于 engineering / product compliance assessment，不替代正式 legal opinion。

### 现阶段防御性措施

- Analytics / Crashlytics 可由用户关闭
- 不收集 name / email / phone / school / location 等直接身份信息
- 不建立账号体系，不要求注册登录
- 不做 behavioral advertising，不接入广告 SDK
- 题目数据默认保存在本地，由用户主动录入、导出、删除

### 重新评估触发条件

出现以下任一变化时，需重新评估 COPPA / GDPR-K 结论：

- 进入 Kids Category
- App Store 元数据开始明显面向 children / kids under 13 营销
- 新增账号体系、云端用户身份或家长-孩子关联账号
- 新增广告 SDK、cross-app tracking 或 behavioral advertising
- 新增开放社区、聊天、UGC 分享或排行榜
- 新增需要直接识别儿童身份的信息字段

> 本节属于 engineering / product compliance assessment，不替代正式 legal opinion。

---

## GDPR / 中国个保法

| 要求 | SnapDrill 状态 |
|---|---|
| 数据可携带权 | ✅ JSON/CSV 导出（隐私设置页） |
| 删除权 | ✅ 用户可删除任意题目，卸载即全删 |
| 知情同意 | ✅ Analytics/Crashlytics 首次启动默认不采集（plist 预禁用），用户可在设置中 opt-in/opt-out |
| 数据最小化 | ✅ 默认不收集，opt-in 后仅匿名标识符 |
| 跨境传输 | ✅ 已缓解。Firebase Analytics/Crashlytics 数据传输至 Google 美国服务器。缓解措施：(1) plist 预设 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED=YES` + `FirebaseCrashlyticsCollectionEnabled=NO`，用户未 opt-in 时零数据外传；(2) 用户可在设置中完全关闭，关闭后等同纯本地模式；(3) 欧盟用户：Google 已签署 EU-US Data Privacy Framework；(4) 中国用户：传输数据仅为匿名设备事件计数，不含个人信息，用户可关闭实现零外传 |
| 中国区 iCloud | 云上贵州运营，数据存储在中国境内（iCloud 同步实现时评估，当前未实现） |

---

## 数据生命周期

```
录入 → App Sandbox 本地存储
  ├── 题目数据：SwiftData 数据库（Documents/profiles/<id>/default.store）
  ├── 题目图片：JPEG 文件（Documents/profiles/<id>/images/）
  └── 草稿：UserDefaults + 临时文件（7 天过期自动清理）

备份 → .zip 文件（用户手动触发）
  └── 用户通过 ShareSheet 保存到任意位置

卸载 → 全部数据永久删除（App Sandbox 随 App 移除）
  └── 设置页有卸载数据丢失提醒
```

---

## 第三方 SDK 安全

| SDK | 版本 | 用途 | 数据 | 风险等级 |
|---|---|---|---|---|
| Firebase Analytics | 11.0+ | 匿名使用统计 | 事件计数，无 PII | 低 |
| Firebase Crashlytics | 11.0+ | 崩溃报告 | 匿名堆栈 | 低 |
| ~~Firebase Remote Config~~ | ~~11.0+~~ | ~~功能开关~~ | **已移除**（PR #590） | — |
| ZIPFoundation | 0.9.19+ | 备份压缩 | 纯本地，无网络 | 无 |
| Mantis | 2.23+ | 图片裁剪 | 纯本地，无网络 | 无 |

**隔离措施**：Firebase SDK 被隔离在 `SnapDrillInfrastructure` Package 中，Core 层通过 Protocol 解耦。替换 Firebase 不影响业务代码。

---

## 八方合规审计结论（2026-04-14）

> 参与方：终端 Claude / 桌面 Claude Opus / Gemini CLI / Gemini Web / GPT-5.4 / Coze / Kimi 2.5 / Codex

### 决策 1: 移除 Firebase Remote Config

**问题**：`DependencyContainer` 在 App 启动时无条件调用 `fetchAndActivate()`，Remote Config 依赖 Firebase Installation ID (FID)，导致启动即与 Google 服务器通信——违反"用户未 opt-in 时零数据外传"承诺。

**决策**：移除 Firebase Remote Config（7/7 一致）。当前仅用于 1 个 `isEmergencyKillSwitchActive` 布尔值，不值得破坏核心隐私承诺。

**替代方案**：如未来需要远程紧急控制，可用无标识符的静态 JSON（CDN 托管）替代。App Store "remove from sale" 作为辅助手段。

### 决策 2: Privacy Manifest 不声明 DeviceID

**问题**：Firebase Installation ID (FID) 是否需要在 `PrivacyInfo.xcprivacy` 中声明为 `NSPrivacyCollectedDataTypeDeviceID`？

**决策**：不需要（6/8 一致，2 个反对方的引用来源经验证为 AI 幻觉）。

**论证**：
- FID 是 app-installation-scoped，不是 device-scoped（同设备不同 App 的 FID 不同，卸载重装后改变）
- Apple 文档定义 DeviceID 为 "device's advertising identifier, or other device-level ID"，举例仅 IDFA/IDFV/设备序列号
- Firebase 官方 PrivacyInfo.xcprivacy（Remote Config / Core / Crashlytics）均不声明 DeviceID
- Apple 从未在官方文档中将 FID 列为 Device ID 示例

### 决策 3: 隐私文案修正

**问题**：COPPA §312.2 将 persistent identifier 列为 personal information，"不收集任何可识别个人信息"在 opt-in 后不成立。

**决策**：修正为"默认不收集个人信息"（8/8 一致）。区分默认状态和 opt-in 后状态，避免全称命题。

### 待观察: age gate

**当前决策**：不加 age gate。理由：SnapDrill 定位 general audience utility tool；零注册 = 无 actual knowledge；加 age gate 反而创造 actual knowledge 证据。

**触发条件**：App Store 审核拒绝涉及 children / FTC inquiry / empirical audience <13 占比显著。
