---
last_verified: 2026-05-25
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [ios_release]
audit_note: VALID_WITH_GAP — iOS 26 平台行为细节需 WWDC 2026 后全量复审
gap_type: apple_platform_release
gap_due: wwdc_2026
gap_owner: tech
gap_evidence_required: WWDC 2026 session 笔记 + iOS 26 真机验证（Vision / Foundation Models / SwiftData 更新）
---
# Apple 技术能力边界（防止 AI 错误假设）

## Vision / OCR

- Vision OCR 强项是**印刷体**，无独立中文手写识别模型
- RecognizeDocumentsRequest 适合整页文档结构识别，**不适合裁剪后的单题图片**

## Foundation Models

- 擅长文本理解（分类/摘要），**不擅长数学推理**
- contentTagging 适合自动标签，不适合解题

## SwiftData

- `#Predicate` 中 many-to-many 关系过滤**运行时崩溃**（编译通过但执行 SIGTRAP）→ 必须 fetch all + 内存过滤
- `#Unique` 与 CloudKit **不兼容**：设备上触发 fatalError（已在 PR #454 移除所有 `#Unique` 用法）
- `swift test` **不可用于 iOS-only SPM 包**：macOS 环境不匹配，会报错或 SIGTRAP → 必须通过 Xcode iOS Simulator 运行
- 具体代码级陷阱见 `api-pitfalls.md` SwiftData 段

## CloudKit

- 需要 **Apple 开发者账号**才能创建 CloudKit Container（阻塞 #485）
- SwiftData **不原生支持 CloudKit 公共数据库**，仅支持私有数据库同步
- `#Unique` 约束与 CloudKit 不兼容（见上方 SwiftData 段）
- 冲突解决策略：last-write-wins（CloudKit 默认行为）

## StoreKit

- 需要 **Apple 开发者账号** + App Store Connect 配置产品（阻塞 #479/#486）
- 沙箱测试需真机或 Xcode StoreKit Configuration 文件（Simulator 有限支持）
- Subscription 价格变更需通过 App Store Connect 审核

## 不存在的 API

- Math Notes 是 Calculator App 私有能力，**无公开 API**
- Smart Script 是屏幕手写输入，**不是照片 OCR**
- 无 Apple 原生数理化公式识别 API（LaTeX/MathML 需第三方方案）
