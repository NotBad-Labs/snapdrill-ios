# SnapDrill · 工程说明（greenfield）

> 结构与并行边界见 [`ARCHITECTURE.md`](ARCHITECTURE.md)。产品规则以 [`PRD.md`](PRD.md) **文内当前版**为准。文档地图与 PO UX 收权见 [`GOVERNANCE.md`](GOVERNANCE.md)。唯一 Slice 编号以 [`ROADMAP.md`](ROADMAP.md) `Slice 1–8` 为准。

| 文档版本 | 1.6 |
|---|---|
| 对应 PRD | 见 [`PRD.md`](PRD.md) 文内当前版 |
| 最后更新 | 2026-11-27 |

---

## Info.plist、`PrivacyInfo.xcprivacy`、Capabilities 与生产标识锁定

- **自定义 `Info.plist`**：使用自定义 `SnapDrill/Info.plist` 时，相机（`NSCameraUsageDescription`）必须明确写入 plist 文件内（不要仅依赖构建变量 `INFOPLIST_KEY_*`），否则真机调用系统相机会直接崩溃；照片导入默认采用系统 `PHPicker`，无需提前声明完整相册读取权限（仅当未来明确引入 `PHPhotoLibrary` 相关读写 API 时再补写 `NSPhotoLibraryUsageDescription` 与 `NSPhotoLibraryAddUsageDescription`）。
- **出口加密合规**：在 `Info.plist` 中明确配置 **`ITSAppUsesNonExemptEncryption = NO`**（仅使用苹果系统标准 HTTPS/TLS，无自定义非豁免加密算法），避免 TestFlight 与 App Store 每次提审被出口加密合规弹窗阻塞。
- **Privacy Manifest（`SnapDrill/PrivacyInfo.xcprivacy` 必配）**：
  - `NSPrivacyTracking` = `false`（零第三方广告与追踪 SDK），`NSPrivacyTrackingDomains` = `[]`；
  - **Required Reason API 声明**：声明本 App 实际调用的三类系统受控 API——① `UserDefaults`（`NSPrivacyAccessedAPICategoryUserDefaults`：`CA92.1` 读写应用内主题/上次科目等用户偏好）、② 磁盘可用空间查询（`NSPrivacyAccessedAPICategoryDiskSpace`：`E174.1` / `85F4.1` 用于写库前 ≥ 50 MB 安全空间预检及 `F-66` 空间占用统计）、③ 文件时间戳（`NSPrivacyAccessedAPICategoryFileTimestamp`：`C617.1` 用于 `F-66` 过期碎片清理 [`tmp/thumbnails/`、`Library/Caches/SnapDrillImageCache/`]、`tmp/pdf-export/` 清空与 `Application Support/CaptureDrafts/` 草稿管理，显式排除未决草稿与 SwiftData 外部存储误删）。
- **Capabilities 清单（Release / Archive 必配）**：
  - `iCloud` → 勾选 `CloudKit` 并绑定生产专用 Container ID（供 `CKSyncEngine` 私有库 `SnapDrillPrivateZone` 同步）；
  - `Background Modes` → 勾选 `Remote notifications`（`CKSyncEngine` 接收 CloudKit 静默推送变更通知必配）；
  - `In-App Purchase`（供 StoreKit 2 订阅、试用、宽限/重试、`.pending` 零权益与恢复购买）；
  - 设置 → 关于页（`F-67`）展示 **中国大陆 ICP 备案号与查询链接**（MVP W1–W2 启动备案，见 [`ROADMAP.md`](ROADMAP.md)）。

### 生产标识锁定表与签名隔离警示

| 生产配置项 | W1–W2 锁定占位（正式值写入后严禁变更） | 绑定影响范围 |
|---|---|---|
| **生产 Bundle ID** | `【W1–W2 锁定正式值并写入 project.yml】` | App Store Connect、ICP 备案与发布证书公钥指纹、StoreKit 商品查询 |
| **CloudKit Container ID** | `iCloud.【与生产 Bundle ID 对齐】` | 私有库 `CKSyncEngine` 同步（变更将无法读取既有用户云端数据） |

- **个人调试与生产隔离**：日常真机调试时使用对应 Signing Team；若本地调试遇到占用冲突，仅可在本地临时未提交配置中覆盖 Dev 标识，**严禁把测试性 Bundle ID 改写提交至正式 Release 配置**。生产 Bundle ID 与 Container ID 一经锁定即严禁任意更改。
- **未锁定量产标识前状态**：在完成 W1–W2 生产 Bundle ID、Signing Team 与 CloudKit Container ID 正式值锁定并写入 `project.yml` 前，`M1.5 上架` 中依赖真机签名、StoreKit 沙盒配置或 iCloud 容器的验收项一律标记为 **阻塞未就绪（N/A）**。

---

## 上架法务托管与 App Privacy 交付核对表（支撑 `M-freeze` 第 5 项）

> 所有外链法务页与官网产品页均统一部署于 `notbadhq.com`（与 [`PRD.md`](PRD.md) §6.3、§7.5、§9.1 及 [`STAGE0_CHARTER.md`](STAGE0_CHARTER.md) §7 合一）；下表子路径为**规范托管规划路径**，随官网五语改版上线同步锁定并填入 App Store Connect（ASC）。

| 交付项 | 五语覆盖与核心要求 | 挂载 / 校验位置（规划规范路径） | 当前状态 |
|---|---|---|---|
| **`notbadhq.com` 产品页五语改版** | 下线“收集文字片段及其来源”旧定位，按错题本定位同步更新 `zh-Hans`、`zh-Hant`（兼顾 TW/HK 用语）、`ja`、`ko`、`en` 产品页与商店预览图 | `notbadhq.com/snapdrill`（官网上线先于 `M-freeze` #5） | ☐ 待上线 |
| **5 语隐私政策（Privacy Policy）** | 声明无账号、无自建业务服务器与零第三方追踪；披露 **Pro 开启 `CKSyncEngine` 时题干/答案图及文本元数据存于 Apple 个人私有 iCloud（中国大陆由云上贵州依法运营）**；说明 Free 版 iOS 系统整机加密备份由系统控制且草稿 `CaptureDrafts/` 设为 `isExcludedFromBackup = true`；包含 **中国 PIPL <14 岁未成年人监护人知情同意与“拍题遮挡姓名/学号”告知** | `notbadhq.com/snapdrill/privacy` → **App 内 Paywall 页 + 设置关于页（`F-67`）+ App Store Connect 商品描述区 + ASC 隐私链接** | ☐ 待托管 |
| **5 语使用条款（EULA）** | 明确连续订阅自动续费说明、**至少提前 24 小时在 Apple ID 账户设置取消路径**、试用资格条件及 Apple 标准退款说明 | `notbadhq.com/snapdrill/terms` → **App 内 Paywall 页 + 设置关于页（`F-67`）+ App Store Connect 商品描述区**（Guideline 3.1.2） | ☐ 待托管 |
| **5 语技术支持页（Support URL）** | 提供 Pro iCloud 同步与恢复购买指引、故障期原始资产自救导出说明与联系方式 | `notbadhq.com/snapdrill/support` → **App Store Connect Support URL + 设置 → 关于页（`F-67`）** | ☐ 待托管 |
| **ASC App Privacy 问卷口径** | ① **Tracking**：全否（`NSPrivacyTracking = false`，零广告/行为追踪 SDK）；② **`User ID / Apple ID`（Not Collected）**：明确不勾选收集——无应用内账号，不调用 `ASAuthorization`，Pro 仅通过 Apple 系统容器级私人 `CKSyncEngine` 同步，开发者不接收或读取用户 Apple ID 标识符；③ **User Content（Photos）**：如实披露仅当 Pro 开启 Apple 个人私有 iCloud（`CKSyncEngine`）时跨设备同步图片，Free 本地闭环不经开发者服务器上传（iOS 系统级整机备份由系统控制且 `CaptureDrafts/` 已 `isExcludedFromBackup = true`）、开发者不可读取；④ **Purchases**：按 StoreKit 2 官方问卷勾选应用内购买关联项；⑤ 与 `SnapDrill/PrivacyInfo.xcprivacy` 100% 事实一致 | App Store Connect → App Privacy & `PrivacyInfo.xcprivacy` | ☐ 待核验 |
| **年龄分级与条件商业文案** | 分级 `4+`，**不进入“儿童”分类**；若阶段 0 判为 B/C 档并触发 `F-12`，商店副标题与功能文案同步去除“极速/全部自动”误导表述，且保证 `F-12` 免费不进 Paywall | App Store Connect 元数据 & [`PRD.md`](PRD.md) §6.2、§10 唯一决策表、§15 | ☐ 待锁定 |

---

## 打开与编译

```bash
cd /path/to/snapdrill-ios
xcodegen generate    # 修改 project.yml 后重跑
open SnapDrill.xcodeproj
```

- **最低系统**：`iOS 26+`（见 [`PRD.md`](PRD.md) §3.2），启用 Swift 6 Complete Concurrency Checking，Release 须零编译/并发警告。
- **纯编译烟测（无签名）**：`xcodebuild` 可加 `CODE_SIGNING_ALLOWED=NO`（仅模拟器/CI，**不能装真机**）。

---

## 基线设备（PO 统一口径）

| 角色 | 设备 | 用途 |
|---|---|---|
| **日常 Dogfood / 主体验机** | **iPhone 17 标准版**（真机） | 默认开发与手感验证 |
| **AC-04 性能验收基准** | **iPhone 17 标准版** | 统一验收口径（PO 2026-11-17 决议 B） |
| **CI / Agent 自动测试** | **iPhone 17 Simulator**（Xcode 27.2） | `xcodebuild test`、UI Smoke Test、静态守门 |

> **关于非基准机型的实事求是声明**：**未在非基准 iOS 26 机型上强制开展性能抽测**，本工程文档**不承诺**未实测旧机型的绝对不崩溃指标；仅保障架构内建的 **6 秒单题去手写硬超时自动降级**、**ImageIO 大图降采样限流** 及 **后台队列并发 1–2 控制** 降级保护逻辑存在并通过单元测试验证。

真机离线时 Xcode 会显示「Devices Offline」；插上 USB 或同局域网 Wi‑Fi 调试即可。

---

## 方案 1 · `Slice 1–8` 进度边界（仅在此维护实时状态）

| 唯一 Slice | 模块与范围 | 当前状态 | 对应 AC |
|---|---|---|---|
| **Slice 1** | 原生三 Tab + 独立拍摄入口 + 设置关于页（`F-67`）+ **25 `presetKey` × 6 语/地区神谕表**（全 6 预置错因播种）+ 单一本地 SwiftData UUID 模型（含 `isOriginalEncoded`、`needsLocalBackfill`、`needsCloudUpload`、`pendingDeletionAt`、`backfillStateRaw`、`cleanedImageSourceRaw`、`editNonce`、`AnswerImage.updatedAt` 与 `DeleteTombstone(presetKey)` / 云端 `DeletedPresetKey`） | **壳/UI 进行中；正式建库 Schema 落盘待 `CKSyncEngine` 6 条 Spike 签收** | `AC-01` |
| **Slice 2** | **LibraryServing 核心入库/预检子集（先建合同）** + 唯一 `AVFoundation`+Vision 2 步采集（含 30 题/0 页闭集）+ ≤300 ms 编码等待 1 秒提交（写 `isOriginalEncoded`/`needsLocalBackfill`/`needsCloudUpload` + 补压缩重试）+ `Application Support` 草稿 + UX 冻结 | 进行中 | `AC-02`, `AC-03`, `AC-09`(部分) |
| **Slice 3** | 端侧 Core ML 去手写（懒加载不入启动路径 + `needsLocalBackfill` 驱动队列 + `beginBackgroundTask` + 6s 超时降级置 `cleanedImageData = nil`） | 占位降级（待阶段 0 趋势门） | `AC-04` / `AC-04-B` |
| **Slice 4** | `LibraryServing` 完整扩展 + 列表筛选（排除 `pendingDeletionAt != nil`）+ 详情「重跑去手写」（按 `cleanedImageSource == manual` 确认，重裁一并确认重编码）+ **5 秒撤销删除（`pendingDeletionAt` 暂隐藏、快照写 `DeleteTombstone(presetKey)` 事务再经 Stub/Live 窄接口投递，禁 `.cascade`）** | 待推进 | `AC-05` |
| **Slice 5** | **`ReviewServing`（开始前先落协议与契约测试）** + 复习闭环（继承筛选/缩放/空答案补录） | 待推进 | `AC-06` |
| **Slice 6** | `PDFExportService`（注入 `ProEntitlementStore` 快照 / `ExportLayoutOptions`、B5 默认/公式留白 18%/25%/35%/双超页等比缩放/多页答案附页/`#8E8E93` 35% 水印与打印一致/`tmp/pdf-export/` 四触发器整清） | 待推进 | `AC-07` |
| **Slice 7** | `ProEntitlementStore` + Live `CloudKitSyncEngine`（启动监听/加载重试/宽限期/`.pending` 零权益/`F-64a` 额外 2 套主题/`CKSyncEngine` 启停、冷启动冲墓碑与 `needsCloudUpload`、回灌重申云删、`DeletedPresetKey` 防复活、同 `UUID` `editNonce` 平局 LWW、`AnswerImage ≤ 3` 重排与 `needsLocalBackfill` 隔离远端 `pending`） | 待推进 | `AC-08` |
| **Slice 8** | 库损坏自救导出/`F-66` 清理（整清 `tmp/pdf-export/`，仅按 7 天无 `UUID` 清 `thumbnails` 与 `SnapDrillImageCache`，显式排除 `CaptureDrafts/` 与外部存储）+ `F-67` 关于页 + 5 语动态切换 + 5 界面 a11y / 6 组调色板 WCAG AA | 待推进 | `AC-09`, `AC-10` |

路线里程碑与前置门禁见 [`ROADMAP.md`](ROADMAP.md)。

**冷启动口径**：系统 Launch Screen 使用 `PaperBackground` 纸色；工程内部使用轻量纸色过渡视图（`StartupView`）覆盖首次建库短时初始化，避免白屏；**去手写 Core ML 模型严格懒加载，严禁放入冷启动路径**。性能验收目标为 **非首装冷启动至首页可交互 ≤ 1.0 秒，点击拍摄入口至相机首帧取景 ≤ 0.5 秒（累计 ≤ 1.5 秒）**。

---

## 目录

```text
SnapDrill/           SwiftUI 应用源码（Features / Navigation / Services / Models / Design / PrivacyInfo.xcprivacy）
SnapDrillTests/      单元测试与合同测试
SnapDrillUITests/    关键路径 UI Smoke 测试
project.yml          XcodeGen 定义
```

---

## 修订记录

| 版本 | 日期 | 说明 |
|---|---|---|
| 1.0 | 2026-11-16 | 首版工程说明 |
| 1.1 | 2026-11-27 | 删除过时旧机型抽测；补充加密合规、Capabilities 及 Bundle ID 锁定警示；同步 `Slice 1–8` |
| 1.2 | 2026-11-27 | 新增 `PrivacyInfo.xcprivacy` Required Reason API 清单与非基准机实事求是声明 |
| 1.3 | 2026-11-27 | Capabilities 增加 `Background Modes: Remote notifications` 支撑 `CKSyncEngine`；明确 Slice 1「壳/UI 可进行、正式建库待 Spike 签收」；修正简体错字「用户」 |
| 1.4 | 2026-11-27 | 合规与交付细化：拆分 `NSCameraUsageDescription` 必配与 `PHPicker` 免全库权限说明；增补未锁定量产标识前 `M1.5` 上架相关项 `N/A` 口径；新增支撑 `M-freeze` 第 5 项的「上架法务托管与 App Privacy 交付核对表」；同步 `Slice 1/4/7/8` 字段及 `F-66` 白名单边界 |
| 1.5 | 2026-11-27 | 隐私问卷与阶段列表对齐：App Privacy 核对表增补 `User ID / Apple ID` 不收集（Not Collected）及 Free 整机系统备份口径；`Slice 1–8` 同步 `isOriginalEncoded`、`DeletedPresetKey`、`6 条 Spike`、`ReviewServing` 前置与 `AnswerImage ≤ 3` 重排 |
| 1.6 | 2026-11-27 | 同步核心状态位、关于页与导出契约：`Slice 1–8` 及 `PrivacyInfo` 声明同步 `needsLocalBackfill`、`needsCloudUpload`、`cleanedImageSource`、`editNonce`、全 6 预置错因播种、`ExportLayoutOptions` 注入、Slice 1–6 Stub 同步、`F-67` 关于页以及 `tmp/pdf-export/` 整目录清理边界 |
