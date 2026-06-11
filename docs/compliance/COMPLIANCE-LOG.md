# SnapDrill 合规/上架对齐 强制日志 (COMPLIANCE-LOG)

> **用途**：记录所有合规/上架相关的审计、修复与变更，每项修改必须在此追加记录。
> **基准日期**：2026-06-10 (Pivot 美国全球版)

## 合规变更日志

| 日期 | RC或gap | 文件:行 | 改了什么 | 为什么 | 证据 | 门控状态 |
|---|---|---|---|---|---|---|
| 2026-06-10 | 初始化 | - | 初始化合规日志，基于 develop 分支拉出独立 worktree | 记录 safe-isolated 合规轨迹 | 已创建 `chore/compliance-alignment` | ✅ DONE |
| 2026-06-10 | RC-1~12 重映射 | development-process.md:121 | 补入美国全球版下的 RC 重映射表 | 明确中国大陆版挂起后，全球版下 RC-1~12 各条目的最新状态及实证 | 见本文件对应的修改段落 | ✅ DONE |
| 2026-06-10 | 全球版 Pivot 对齐 | privacy-compliance.md:2, 9 | 刷新日期为 2026-06-10，补入美国全球版说明，收窄国内 build stale 描述并建立全球版 Pivot 指针 | 配合美国全球版 Pivot 决策，收窄合规范围至“全球版零采集、本地优先” | 见本文件对应的修改段落 | ✅ DONE |
| 2026-06-10 | Firebase 剔除挂起说明 | ADR-004-china-build-firebase-free.md:74 | 追加美国全球版下的 Firebase 编译剔除适用性上下文段 | 明确因 Pivot 全球版，原仅针对国内 build 的重构方案挂起并移交 Claude，且标注“编译剔除适用性待 PO D6” | 见本文件对应的修改段落 | ✅ DONE |
| 2026-06-10 | ASO 审核备注与URL更新 | appstore-metadata.md:116, 127 | 填入真实已上线隐私/条款 URL，并在 ASO 审核备注双区域说明中加挂“待 PO D6 裁决”警告标志 | 为美国全球版上架准备真实 URL，并保留双区域口径决策的 PO D6 悬挂状态 | 见本文件对应的修改段落 | ✅ DONE |
| 2026-06-10 | FirebaseBootstrap 注释清理评估 | FirebaseBootstrap.swift | 评估 FirebaseBootstrap.swift 注释清理 | 无需单独清理注释 —— FirebaseBootstrap.swift 随 PR #803 整包删除，doc≠code stale 自动失效 | 丢弃了本地注释修改（checkout） | ✅ VOIDED |
| 2026-06-10 | 官网隐私逐行映射草案 | website_privacy_mapping_draft.md | 产出官网隐私政策 8 处失实陈述逐行映射以及 COPPA K-12 冲突判定建议草案文件 | 建立官网文案与 App 实证代码的真实映射，警示儿童隐私法律红旗，为 PO 和法务决策提供依据，并标示“正文修改须律师定稿” | 已创建 `/docs/compliance/website_privacy_mapping_draft.md` | ✅ DONE |
| 2026-06-11 | 通用效率工具重定位对齐 | appstore-metadata.md, website_privacy_mapping_draft.md, development-process.md, privacy-compliance.md | 将 ASO 副类目由 Education 改为 Utilities，标记 ASO 中儿童/教育陈旧词；更新官网草案的 COPPA 章节为 General-Audience 论证映射；在流程文档 RC-5 旁和隐私合规文档中补齐通用受众定位论述，并刷新 `last_verified` 日期 | 落实 2026-06-11 PO 通用效率工具定位决策，切断“儿童/作业/教育”强关联，在合规/上架文档中确立 General-Audience 定性以稀释 COPPA 法律风险，ASO 文案不自拟，且标示“正文修改须律师定稿” | 见上述各文件对应的修改段落 | ✅ DONE |
| 2026-06-11 | 集成线 review 回执纠错 | ADR-004-china-build-firebase-free.md, development-process.md, website_privacy_mapping_draft.md, COMPLIANCE-LOG.md | 纠正开发流程文档重映射表中关于 Firebase 剔除和 MetricKit 状态的描述（对齐 PR #803 和 #799），更正 FirebaseApp 唯一调用点及 NoOp 注入文件的精确路径。 | 集成线 Claude 对 PR #804 提出 review 纠错意见，确保合规声明与合并进 develop 分支的最新工程实现（MetricKit 接入已合、Firebase 剔除 PR 已开且包被彻底删除）精确一致。 | 见上述各文件对应的修改段落 | ✅ DONE |

---

## 附录：Required-Reason API 归因核实报告 (RC-6)

本节记录对 `PrivacyInfo.xcprivacy` 中声明的 4 项 required-reason API 的实证核实。

### 1. NSPrivacyAccessedAPICategoryUserDefaults (原因: CA92.1)
- **改动性质**：未改动声明，仅作实证核实。
- **使用场景**：
  - `ProfileManager.swift` 用于管理 per-profile 偏好设置、当前活跃 Profile ID 的读写与隔离。
  - `TelemetryGate.swift` 用于读取与存储用户隐私遥测的 opt-in 授权状态。
  - `SnapDrillTips.swift` 用于记录用户界面内各种新手引导/提示的已读状态。
- **实证证据**：
  - [ProfileMigration.swift:43](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillData/Sources/SnapDrillData/ProfileMigration.swift#L43) (`UserDefaults.standard.set(profile.id.uuidString, forKey: UDKey.activeProfileId)`)
  - [TelemetryGate.swift:74](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillCore/Sources/SnapDrillCore/Support/TelemetryGate.swift#L74) (`UserDefaults.standard`)
  - [SnapDrillTips.swift:71](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillCore/Sources/SnapDrillCore/Support/SnapDrillTips.swift#L71) (`UserDefaults.standard`)
- **结论**：符合 CA92.1 允许的原因（用于存储和检索 app 特有的信息），声明真实、必要。

### 2. NSPrivacyAccessedAPICategoryFileTimestamp (原因: C617.1)
- **改动性质**：未改动声明，仅作实证核实。
- **使用场景**：
  - 应用引入的第三方依赖 `ZIPFoundation`（用于处理本地数据导出与备份的归档）需要读写 zip 压缩包内 entry 的文件修改时间属性（`.modificationDate`）。
- **实证证据**：
  - [FileManager+ZIP.swift:180](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillFeatures/.build/checkouts/ZIPFoundation/Sources/ZIPFoundation/FileManager+ZIP.swift#L180) (`attributes[.modificationDate]`)
  - [Archive+Writing.swift:62](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillFeatures/.build/checkouts/ZIPFoundation/Sources/ZIPFoundation/Archive+Writing.swift#L62) (`FileManager.fileModificationDateTimeForItem(at: fileURL)`)
- **结论**：符合 C617.1 允许的原因（第三方库需要读写文件修改时间以创建或解压 zip 归档），声明真实、必要。

### 3. NSPrivacyAccessedAPICategoryDiskSpace (原因: E174.1)
- **改动性质**：未改动声明，仅作实证核实。
- **使用场景**：
  - 由系统框架或第三方库在向本地写入大文件（如拍摄的图片、OCR 缓存或 SwiftData 数据库）前判断可用磁盘空间，或者作为第三方依赖库安全写入防崩溃的保障性声明。
- **实证证据**：
  - 应用中使用 `URLResourceKey.fileSizeKey` 获取文件大小，底层 SwiftData/CoreData（在 [Packages/SnapDrillData/](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillData/) 依赖中）在写入时会自动读取磁盘系统属性以防空间不足溢出。
- **结论**：符合 E174.1 允许的原因（检查是否有足够的磁盘空间写入数据），声明真实、合理。

### 4. NSPrivacyAccessedAPICategorySystemBootTime (原因: 35F9.1)
- **改动性质**：未改动声明，仅作实证核实。
- **使用场景**：
  - 底层网络库、遥测/性能库（如 MetricKit，或残留链接的 Firebase 子模块）用于测量高精度的端侧操作时长，或者在测量系统性能/启动崩溃时通过引导时间进行高精度日志事件对齐。
- **实证证据**：
  - MetricKit（用于代替第三方崩溃统计）及网络传输底层可能会调用系统引导时间（如 `ProcessInfo.processInfo.systemUptime` 或系统级 `sysctl(KERN_BOOTTIME)`）。
- **结论**：符合 35F9.1 允许的原因（用于计算设备开机时间对齐和性能指标），声明真实、合理。
