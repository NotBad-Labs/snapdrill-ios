# SnapDrill iOS 26 / 27 开发与发版规范手册（融合定稿版）

> **目标基线**：最低部署 `iOS 26.0` · 主流运行 `iOS 27` · `Xcode 27 / Swift 6.4` · `SWIFT_STRICT_CONCURRENCY = complete`
> **核心定位**：端侧隐私优先、含实时文档相机 / 分块 Core ML / SwiftData + CloudKit / StoreKit 2 的工具型 App。

- **判断法则一（代码感）**：新成员无需询问即可答出「文件在哪、为何存在、删掉会坏什么」。
- **判断法则二（产品感）**：用户不查文档就知道「点这里会发生什么、数据存在哪、失败由什么兜底」。

---

## 上卷 · 代码与架构硬红线（随每次提交 / PR 必查）

### A. 架构与治理边界
- **【阻塞】受保护资产只读**：`Docs/` 与 `Samples/` 必须与 `origin/greenfield/rebuild-from-zero` 保持 zero diff；`SnapDrill/Resources/SnapDrill.storekit` 严禁进入生产 `SnapDrill.app` Bundle。
- **【阻塞】系统框架隔离**：`SnapDrill/Features/` 目录（尤其是 `Features/Capture/`）严禁导入 `AVFoundation`、`Vision`、`VisionKit`、`CoreImage`、`ImageIO`、`CoreML`；界面只依赖 `*Serving` 协议与 `Sendable` 值类型契约。
- **【阻塞】纯洁领域模型**：`SnapDrill/Models/` 仅依赖 `Foundation` / `SwiftData`，禁止导入 `SwiftUI` / `UIKit` / `AVFoundation`。
- **【阻塞】合理单一组合根**：全局依赖在 `App` / `AppEnvironment` 组装注入；仅进程级不可变/锁保护缓存或系统入口桥接允许受控 `.shared` 并写明不变量。
- **【阻塞】拒绝空封装**：仅有单一实现且无测试替身的需求不许制造 `protocol + Default + Live + Mock` 四件套；长流程使用阶段 `enum`（如 `CaptureFlowStep`）拆分子视图，单文件控制可读尺度。

### B. Swift 6+ 严格并发与内存
- **【阻塞】零并发警告**：Debug / Release 编译警告一律按失败处理，禁止用 `SWIFT_STRICT_CONCURRENCY = targeted` 或无注释 `nonisolated(unsafe)` 掩盖诊断。
- **【阻塞】后台卸载显式化**：牢记 Swift 6.2+ 中普通 `nonisolated async` 函数默认延续调用方 actor，**不会自动离主线程**；图像解码、压缩、Core ML 推理必须显式标注 `@concurrent` 或在 `Task.detached` / 专用串行队列执行。
- **【阻塞】线程归属清晰**：UI 与主 `ModelContext` 走 `@MainActor`，业务层零 `DispatchQueue.main`；`DispatchQueue` 仅限 `AVCaptureSession` 与实时视觉帧节流队列，跨隔离域仅传 `Sendable` 值，禁止传递 `@Model`、`ModelContext`、`MLModel`、`AVCaptureSession`、`CVPixelBuffer`。
- **【阻塞】锁定 `iOS 26.0` 部署兼容性**：禁止裸调 `iOS 27.0+` 独占 API（如 `withTaskCancellationShield` 会触发 `-target arm64-apple-ios26.0` 编译失败）；关键异步清理采用 epoch 门闩或 `if #available(iOS 27.0, *)` 保护。
- **【阻塞】大图与缩略图预算**：48MP HEIC/JPEG 禁止在主线程或处理入口调用 `UIImage(data:)` 全图解码；统一经由 `PhotoDataSanitizer` 使用 ImageIO `CGImageSourceCreateThumbnailAtIndex` 解码期直出缩略图（~160 px）与工作图（长边 ≤ 2200 px）。

### C. SwiftUI 状态与 iOS 26 / 27 Liquid Glass
- **【阻塞】现代 Observation 状态**：统一使用 `@Observable` + `@State` / `@Environment(Type.self)` / `@Bindable`；禁止新增 `ObservableObject`、`@StateObject`、`@ObservedObject`；互斥状态用 `enum` 建模。
- **【阻塞】原生导航与主入口规范**：根导航采用系统 `TabView` + `Tab`（`tabBarMinimizeBehavior(.onScrollDown)`）；常规创建操作（如拍照收录）置于导航栏右上角 `.glassProminent` 或空状态卡片，**严禁将拍照等静态主操作塞入 `tabViewBottomAccessory`**（该槽位仅限播放条/计时器等持续会话状态，避免恢复双胶囊堆叠）。
- **【阻塞】Liquid Glass 与可调透明度兼容**：只给浮在内容之上的控制层/悬浮工具栏使用系统 `.glassEffect` / `.glassProminent`，底层固定操作条（如 `BottomActionBarContainer`）使用清晰的材质与主题表面底色，禁止手叠多层 `ultraThinMaterial`；文字与前景必须用 `SnapDrillTheme` 自适应语义色（iOS 27 用户可调清透度，禁止在玻璃上写死纯白/纯黑文字）。
- **【阻塞】列表稳定性与无障碍**：`ForEach` 禁止使用 `id: \.offset`（图片列表使用 `IndexedPhotoData` 等内容/UUID 稳定 ID）；所有可交互控件热区 `≥ 44×44 pt`，图标按钮必配 `accessibilityLabel`，装饰插画标 `accessibilityHidden(true)`，关键页面适配 Dynamic Type（到 AX5 不截断、不重叠）。

### D. 端侧 AI、相机与多媒体
- **【阻塞】Core ML `.mlprogram` 契约**：导出最低目标固定 `ct.target.iOS26`；模型首次加载/编译预热必须在独立推理超时（2 秒）预算之外执行；`MLModel` 留在进程缓存不跨 `Task` 传递；未通过真实试卷 Stage 0 盲评（≥ 80 张，达到章程标准）前，模型产物不得打入生产 `SnapDrill.app`。
- **【阻塞】算法前后一致性**：Python `MLPipeline/postprocess.py` 与 Swift `TiledInkSegmentationEngine` 必须保持居中补边、85 分位局部纸色采样、`(x + 0.5)/cell - 0.5` 双线性插值、0.55 阈值与 1.15× 印刷体保护逐公式对齐。
- **【阻塞】响亮降级，零静默吞错**：Core ML 失败或超时后必须链式回落 `HeuristicInkRemover` 清理彩笔/铅笔，并保持返回 `succeeded = false` 与用户可见橡皮擦提示；严禁 `try?` 或空 `catch` 假装清理成功。
- **【阻塞】相机会话生命周期**：会话配置/启停固定在串行 `sessionQueue`；`configure()` 失败须拆除已加 input/output 并进入明确降级页；必须监听 `wasInterrupted` / `interruptionEnded` / `runtimeError` 实现中断提示与恢复；拍后立即后台降采样并剥离 GPS；`FoundationModels` 若后续引入，仅作先判 `availability` 的可选文本辅助，不得阻塞主路径。

### E. 持久化、隐私与本地化
- **【阻塞】CloudKit 容器切换安全**：切换与重建必须互斥于「采集流进行中」与「待撤销删除倒计时窗口」；Pro 过期只停止云同步与付费能力，本地题库/图片/复习/基础导出保持可读可写。
- **【阻塞】EXIF/GPS 零泄露**：所有落盘图片、缩略图及 PDF 导出前通过 ImageIO 写入干净属性字典剥离 `{GPS}` 与位置标签；选图使用系统 `PhotosPicker`，按需申请最小权限。
- **【阻塞】五语种同步与调试隔离**：所有用户可见字符串纳入 `Localizable.xcstrings` 同步维护 `en / zh-Hans / zh-Hant / ja / ko`，首页及产品文案不得超前承诺未进包能力；调试深链、演示数据与内购覆盖全部包裹在 `#if DEBUG` 内。

### F. 自动化防腐与 AI 协同三条铁律
- **【阻塞】SwiftLint 与测试**：接入远端 CI 工作流前，每次提交前必须在本地执行 `.swiftlint.yml` 校验（`swiftlint lint`，`force_cast / force_try / force_unwrapping` 为 `error`，放行图形/像素短变量名及教育术语 `mastery`）；核心逻辑与降级路径必带单元测试，新增单测优先采用 Swift Testing（`@Test` / `#expect`）。
- **AI 协同纪律**：1）没有第二使用者或测试桩，不抽空协议；2）任何降级必须同时具备「判别返回值 + UI 文案 + 测试断言」；3）编译报错必须正面修复隔离域或选用系统原生组件，严禁用 `@StateObject`、`DispatchQueue.main` 或 `#available(iOS 17)` 兼容补丁敷衍通过编译。

---

## 下卷 · 提审、合规与可观测性总检（随 TestFlight / App Store 发版必查）

- **G1 Stage 0 真卷裁决**：在 iPhone 17 上完成 ≥ 80 张真实试卷盲评，记录运行时后处理掩码的印刷体保留率、黑笔 F1 与 P50/P95 耗时；在 PO 正式解冻并授权写入 `Docs/STAGE0_CHARTER.md` §6 前，评测结果先行留存于 PR 描述与外部评测记录（保持 `Docs/` 与 `origin/greenfield/rebuild-from-zero` zero diff），达标并经 PO 签核后方可将 `HandwritingRemover.mlmodelc` 纳入打包资源并解锁商店相关宣称。
- **G2 Liquid Glass 四外观图标**：上线前使用 Icon Composer 核验 App Icon 的 Default / Dark / Clear / Tinted 四种桌面外观无破损与泛白。
- **G3 极端可访问性走查**：在真机开启 **AX5 最大字号 + 温暖深色模式 + 降低透明度 + 减弱动态效果 + VoiceOver**，完整走通「首页 → 连拍框选 → 擦除保存 → 复习 → 订阅页」5 屏零截断、零遮挡。
- **G4 iPhone 17 真机性能基线**：通过 Xcode Instruments（Time Profiler + Allocations）留存冷启动、10 页连拍峰值内存与分块 Core ML 单页耗时基线，确认主线程无整图解码与存储写入阻塞。
- **G5 隐私、AI 明示与区域合规**：复核 `PrivacyInfo.xcprivacy` 理由码与 App Store Connect 隐私标签完全一致（零追踪），明确说明图像处理与识别 100% 端侧完成（未来若接入任何外部 AI 须明确告知并给出开关）；面向中国大陆区上架前独立完成 App 备案与双语隐私政策核验。
- **G6 StoreKit 2 联调**：在真实沙盒账号完成订阅购买、恢复购买、家人共享及离线缓存权益校验，确认构建产物无 `.storekit` 调试配置残留。
