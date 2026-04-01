# SnapDrill 数据合规

> 集中记录隐私合规策略、数据处理流程、合规认证状态。
> 商业化策略和隐私差异化定位见 `../product/product-business.md`。

---

## 隐私架构

### 数据收集范围

| 数据类型 | 是否收集 | 存储位置 | 用户控制 |
|---|---|---|---|
| 题目内容（文字+图片） | 是 | 纯本地（App Sandbox） | 用户完全控制 |
| 学科/标签/难度等元数据 | 是 | 纯本地 | 用户完全控制 |
| 用户昵称/头像/座右铭 | 是 | 纯本地 UserDefaults | 用户完全控制 |
| 匿名使用统计 | 是（可关闭） | Firebase Analytics（Google 服务器） | 设置页开关 |
| 匿名崩溃报告 | 是（可关闭） | Firebase Crashlytics（Google 服务器） | 设置页开关 |
| 手机号/邮箱/姓名 | **不收集** | — | — |
| 学校/年级/位置 | **不收集** | — | — |
| 广告标识符（IDFA） | 按 ATT 授权 | — | 系统弹窗 |

### 零可识别个人信息（Zero PII）

SnapDrill 不收集任何可识别个人信息。没有注册、没有手机号、没有学校年级。
这是与竞品的核心差异化，也是合规负担极轻的根本原因。

---

## Apple 合规

### App Store 年龄分级

- **分级**：4+（Unrestricted）
- **Kids Category**：不申请（使用 Firebase SDK，技术上属于第三方 SDK）
- **Declared Age Range API**（iOS 26+）：v1.5 评估

### Apple Privacy Manifest

| 声明项 | 状态 |
|---|---|
| NSPrivacyTracking | false（默认），ATT 授权后可变更 |
| NSPrivacyTrackingDomains | Firebase 相关域名 |
| NSPrivacyCollectedDataTypes | Analytics（匿名事件计数），Crash Data（匿名堆栈） |
| NSPrivacyAccessedAPITypes | UserDefaults（AppStorage），FileTimestamp（文件管理） |

### ATT（App Tracking Transparency）

- 预询问流程：先显示自定义说明页，再触发系统 ATT 弹窗
- 用户拒绝后不影响任何功能
- Analytics 默认开启，用户可在设置中关闭

---

## COPPA 合规姿态

SnapDrill 定位为**效率工具**（utility tool），不是教育工具：
- 不提供任何教育内容（无课本/试卷/题库）
- 所有内容由用户自主拍摄录入
- 类比：Scanner Pro、备忘录——学生也用，但不是"面向儿童的 App"

FTC "directed to children" 核心标准对照：
1. **视觉设计和语气** — 成熟、家长友好，非幼稚卡通风格
2. **面向儿童的内容** — 不提供，所有数据来自用户
3. **营销对象** — 面向家长和学生，非专门面向 <13 岁儿童
4. **App Store 分类** — 未进入 Kids Category

---

## GDPR / 中国个保法

| 要求 | SnapDrill 状态 |
|---|---|
| 数据可携带权 | ✅ JSON/CSV 导出（隐私设置页） |
| 删除权 | ✅ 用户可删除任意题目，卸载即全删 |
| 知情同意 | ✅ Analytics 默认开启但可关闭，ATT 预询问 |
| 数据最小化 | ✅ 零 PII 收集 |
| 跨境传输 | ⚠️ Firebase 数据存储在 Google 服务器（匿名数据） |
| 中国区 iCloud | 云上贵州运营，数据存储在中国境内（v1.5 同步功能） |

---

## 数据生命周期

```
录入 → App Sandbox 本地存储
  ├── 题目数据：SwiftData 数据库（Documents/profiles/<id>/default.store）
  ├── 题目图片：JPEG 文件（Documents/profiles/<id>/images/）
  └── 草稿：UserDefaults + 临时文件（7 天过期自动清理）

备份 → .snapdrill ZIP 文件（用户手动触发）
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
| Firebase Remote Config | 11.0+ | 功能开关 | 无用户数据 | 低 |
| ZIPFoundation | 0.9.19+ | 备份压缩 | 纯本地，无网络 | 无 |
| Mantis | 2.23+ | 图片裁剪 | 纯本地，无网络 | 无 |

**隔离措施**：Firebase SDK 被隔离在 `SnapDrillInfrastructure` Package 中，Core 层通过 Protocol 解耦。替换 Firebase 不影响业务代码。
