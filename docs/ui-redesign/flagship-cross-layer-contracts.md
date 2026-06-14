# 旗舰题库交互 · 跨层契约（Claude 集成线接管）

> **作者**：Claude（集成 / Core·Data·Service lane）。
> **响应**：Codex `docs/ui-redesign/REDESIGN-LOG.md` 的「2026-06-11 · Flagship interaction audit · Filtering and export flow」。Codex 在 UI 实操中发现 4 个跨层问题、明确 defer 给其他层负责人——本文是接管结论。
> **方法**：对照 develop `@ b7e04d98` 真实代码 + 4 路并行调查 + 4 路对抗验证（workflow `ww12q2e4o`），并由我独立 grep 复核承重事实。对抗验证抓到的修正已全部吸收（见各 issue 的「⚠️ 验证修正」）。
> **用途**：供 Codex 在 `feat/ui-redesign` rebase 到 develop 后对接。本文只定 **Core/Data/Service 层契约 + lane 边界**；标 **`[PO]`** 的产品行为决策须 PO 拍板后才落地。
> ⚠️ **所有 file:line 基于 develop `@ b7e04d98`**；Codex 读取时若 develop 已前移，行号以当时 HEAD 为准（凭符号名 grep，勿凭行号）。

## 摘要

| Issue | 判定 | 严重度 | 实现归属 | PO 待决 |
|---|---|---|---|---|
| I1 搜索防抖 vs 离散筛选/排序拆分 | ✅ 成立 | P2 | Claude(ViewModel 刷新时机) + Codex(行布局原子性) | 无 |
| I2 维度过滤内存筛选性能 | ⚠️ refined（Codex 描述需修正） | P3 | Claude(Data) | 2 项 |
| I3 打印 adapter 契约 | ✅ 接线中（adapter 已在 develop，Feature 入口见 2026-06-15 注） | P2 | SnapDrillUI adapter + Codex(Feature 入口) | ✅ 0（已拍板） |
| I4 导出 completion 契约 | ⚠️ refined（Phase 已接，completion seam 未接） | P3 | Codex(phase 视觉) + 后续 completion seam | 3 项 |

**跨 issue 耦合**：I1 去掉 300ms 缓冲后，I2 的内存过滤延迟会变用户可见 → **先修 I1（原子性 + 拆防抖），再 benchmark I2**。
**合并顺序**：I3 已采用「Core 仅产 PDF Data，SnapDrillUI 提供 `PrintPresenting` adapter」路线；Feature/UI 接线随 Codex 分支推进。所有触及 `ExportPreviewView`/`LibraryDetailView`/`ResolvedExportSheet` 的改动应集中 review，避免对同文件多次 rebase 冲突。

---

## I1 · 搜索防抖 vs 离散筛选/排序即时刷新拆分

**判定：成立（Codex 发现属实）。** 严重度 P2。

**根因**：`LibraryViewModel.triggerRefresh()`（`:200`）把「输入节流」与「刷新调度」焊死成单一 300ms 防抖：`searchText`(`:81`)、`selectedValueIdsByDimension`(`:84`)、`selectedDifficulties`(`:88`)、`sortOption`(`:92`) 四个 `didSet` 全调它。搜索框是逐字符连续输入、需节流；学科/难度/排序是离散单次事件、对其施加 300ms 只带纯延迟。真正可见的不是「慢」而是**两条时间轴撕裂**：`@Observable` 离散属性变更让 capsule 选中态(`LibraryListView:59`)、活跃过滤 chip(`:77`)即帧重绘，而决定行内容的 `filteredItems` 要等 300ms 后 `refreshData` 才换 —— 即 PO 真机看到的「学科标签先消失、星级左移、数学题随后才移除」。非设备性能。

**契约（Claude，纯 ViewModel 工程，落 `LibraryViewModel.swift`）**：
1. `triggerRefresh()` → 私有 `scheduleRefresh(debounced: Bool)`：
   - `debounced=true`（搜索专用）：`cancel` 旧 task + `Task.sleep(300ms)` + `refreshData()`。
   - `debounced=false`（离散筛选/排序）：`cancel` 旧 task + 立即 `Task { await refreshData() }`（无 sleep）。
2. `didSet` 分流：`searchText` → `debounced:true`；其余三者 → `debounced:false`。
3. **⚠️ 验证修正（对抗验证抓出的真 bug，必须做）**：当前 `resetFilters()`(`:369-373`) 顺序改 3 个属性、靠 300ms sleep 窗口让后者 `cancel` 在前者真正 fetch 前落地，从而 **coalesce 成 1 次 fetch**。移除 sleep 后，`Task.cancel()` 只置标志、不抢占；而 `refreshData()` 的 `guard !Task.isCancelled` 在 **fetch（`:213`）之后**（`:223`），所以被取消的在途 task 仍会跑完整内存全量 fetch、只在 `:223` 丢结果 —— `resetFilters` 会触发多达 3 次内存全量 fetch。**修法：在 `refreshData` 的 fetch（`:213`）之前新增 `guard !Task.isCancelled`，并在即时路径 `Task` 体内 `await Task.yield()` 让出一拍，给同步连发的 setter 一个合并窗口。**（不做这条，拆分就引入性能回归。）
4. **surgical 完整性**：`searchTask` 宜更名 `refreshTask`（语义更准），须同步改 `cancelTasks()`(`:380-381`) + 注释(`:122-125`、`:375-383`)。
5. `sortOption` 仍走完整 re-fetch：分页子集（pageSize=50）下内存重排只对首页有效，full re-fetch 是当前唯一正确选择（不是糙点，是必要）。

**lane 边界**：我把离散条件的**结果集刷新做成即时**（两条时间轴间隔从 300ms 压到近 0；注意 ≠ 即时完成，大题库下 fetch 本身有耗时，见 I2）。**行布局原子性**（capsule/星级/chip 与结果集同帧、用 `withAnimation`/`transaction` 收口）属 UI lane = Codex。我即时化后若撕裂已不可见，Codex 那半可降级——故**我先行能为 Codex 提供决策依据**。我不碰 `LibraryListView`/`LibraryView` 视觉代码。

`[PO]`：无。

---

## I2 · 维度过滤的内存筛选性能

**判定：refined —— Codex「任意维度筛选需全量 fetch」的描述需修正。** 严重度 **P3**。

**事实（`ReviewRepository.fetchFilteredModels` `:250-303`）**：实现**已有 DB 廉价路径**——`searchText` + `difficulty` 推进 `#Predicate`(`:264-267`) 先收窄；`needsMemoryProcessing = !valueIdsByDimension.isEmpty || sortBySubjectName`(`:270`)，只有维度筛选/学科名排序才走内存路径，且内存过滤作用在**已收窄的子集**上、非无条件全表。维度内存过滤本身是 SwiftData many-to-many `#Predicate` SIGTRAP 限制下的**被迫正确模式**（勿动）。

**真成本三处**（非「全量 fetch」）：
1. `loadMore`(`LibraryViewModel:234-262`) 每翻一页都 `fetchFilteredModels(offset:)`，内存路径下 = 每页从 offset 0 重新 fetch + 重新 materialize 全部 `categoryValues` + 重新过滤 + 重新排序再切片(`:301-302`)。N 页 = O(N × 全集) 重复工作。
2. `categoryValues` 是 `@Relationship` to-many（`ReviewItemModel.swift:53-54`），全仓无 `relationshipKeyPathsForPrefetching`（grep 零命中），`:284` 逐条 `item.categoryValues` 触发懒加载 fault —— 5000 条 = N+1 关系访问。
3. **⚠️ 验证补**：`sortBySubjectName` 路径(`:292-298`)调 `subjectCategoryName` → `categoryValueNames`(`ReviewItemModel+Categories.swift:17-22`) 含 `.filter { $0.dimension?.systemKey == ... }`，是 `categoryValues` 之下的**二级**关系 fault；且 sort 比较器 O(N log N) 次调用**未 memoize** 的计算属性。

**契约（Claude，Data 层）**：
1. 保留维度内存过滤（SIGTRAP 被迫正确，**不要**尝试用 `#Predicate` 改写关系过滤）。
2. **优化点 A（低风险）**：内存路径的 `FetchDescriptor` 设 `relationshipKeyPathsForPrefetching = [\.categoryValues]`，把 N 次 fault 折叠为批量预取。**⚠️ 验证修正：单级 prefetch 只覆盖维度过滤路径；`sortBySubjectName` 的二级 `.dimension` fault 不被覆盖**——需多级预取或显式承认残留，验收时勿按「已消除 N+1」签字。
3. **优化点 B（须先实测 + 有正确性约束）`[PO]`**：`loadMore` 内存路径改「一次性 fetch 全集 + ViewModel 内存分页缓存」。⚠️ 这不只是性能权衡：`fetchFilteredModels` 文档注释(`:247-249`)已警告 DB-fetchLimit + 内存过滤导致**分页数不可控**，缓存必须等价于「内存全集切片」语义，否则引入「用户找不到已有题目」的正确性陷阱。仅在实测证明大题库下重复 fetch 是真瓶颈时才做（否则属未要求的优化，违反 Simplicity）。
4. **benchmark gate**：`SnapDrillDataTests` 加 `.disabled()`/tagged 规模测试（50/500/5000 条、多维度各 3-5 值），断言墙钟上界（阈值留宽、防回归非测绝对值、**非 CI 硬失败门**、须 self-hosted runner 实测校准）。

**⚠️ 务必先 Instruments / 真机规模实测再下「性能不达标」结论** —— 当前所有量级判断均为代码推理、未经测量。肉眼停顿首因是 300ms 防抖（见 I1）、非内存过滤；零用户阶段 5000 条是假想上界。故 **P3 后置**，排在功能闭环/发布阻塞之后。

`[PO]`：① 优化点 B 是否做（须实测 + 守正确性）；② 300ms 防抖时长是否调整（UI 手感，Codex+PO 设计权——这是肉眼停顿首因，先确认是否为 issue）。

---

## I3 · 一等打印 PrintService / UIPrintInteractionController 契约

**判定：成立 —— 原 develop 缺少一等打印能力；`PrintPresenting` adapter 已合入，Feature 入口接线见下方 2026-06-15 注。** 严重度 P2。

**历史现状（记录缺口来源）**：在该审计基线中，打印 100% 寄生在 PDF 导出 + 系统分享表：`LibraryDetailView.printSingleItem()` = `pdfExport.createPDF(itemsPerPage:1)` → 临时文件 → `UIActivityViewController`，从不调 `UIPrintInteractionController`、也从不 `activityTracker.begin(.printing)`（坐实 GAP-R4）；批量路径 `ExportPreviewView` 同靠 `ShareLink`。

**2026-06-15 Codex 接线注**：`SnapDrillUI/PrintPresenting.swift` 已在 develop 提供 adapter；`codex/library-interaction-audit` 将 `LibraryDetailView` 单题打印和 `ExportPreviewView` 批量 PDF 预览打印接到 `@Environment(\.printPresenter)`，分享与打印拆为两个入口，并在系统打印交互期间用 `.printing` activity 阻塞 Profile 切换。当前实现仍需真机 iPhone 17 dogfood 验 `completed/cancelled/failed`，因为 Simulator 对 `UIPrintInteractionController` 支持有限。

**✅ 设计已定（PO + Codex 2026-06-11，D-I3a = 改良版 B）**：**Core 仅生成 PDF Data；`UIPrintInteractionController` 的 presentation adapter 集中放 `SnapDrillUI`**，由 Feature View 调用，避免重复实现、同时保持可注入测试。**不把 UIView / present 固化进 Core**（撤销原 A 推荐——见下方「为何改良版 B 成立」）。

**契约**：
- **Core：无新增**。`PDFExportService.createPDF(...)`（`PDFExportService.swift:37-41`）已产 `Data`，打印复用它、**不重写 PDF 引擎、不引入吃 UIView 的 Core 服务**。Core 保持「对 UI 一无所知」。
- **SnapDrillUI（新增 adapter）**：`Packages/SnapDrillUI/Sources/SnapDrillUI/PrintPresenting.swift`
  ```
  public protocol PrintPresenting: Sendable {
      @MainActor func present(pdfData: Data, jobName: String, anchor: PrintPresentationAnchor) async throws -> PrintOutcome
  }
  public enum PrintOutcome: Sendable { case completed; case cancelled }   // failed 走 throws
  public enum PrintPresentationAnchor { case view(UIView); case rect(CGRect, UIView); case barButton(UIBarButtonItem) } // iPad 必需 anchor
  public enum PrintError: Error { case noContent; case presentationFailed }
  ```
  - `LivePrintPresenter`：`UIPrintInteractionController` + `UIPrintInfo(.general)` 包装传入的 PDF `Data`；`withCheckedThrowingContinuation` 把 `completionHandler(_, completed, error)` 桥成 async（completed→`.completed` / !completed&&无 error→`.cancelled` / 有 error→throw）。
  - `MockPrintPresenter`：可配 outcome/error，供 Feature View 逻辑（含 UC5「无打印机/取消→不记打印」）单测。
  - **注入**：SwiftUI `@Environment(\.printPresenter)`（SnapDrillUI 定义 environment key，默认 `LivePrintPresenter`，测试注 Mock）——adapter 在 UI 层、吃 UIView，不走 Core 的 ServiceContainer。
- **Feature View（Codex）**：`let data = try await pdfExport.createPDF(...)` → `let outcome = try await printPresenter.present(pdfData: data, jobName:, anchor:)`；提供 anchor；`PDFExportOptions` 配置 UI；消费 outcome 做错误反馈；present 前后 `activityTracker.begin/end(.printing)` 补 GAP-R4（`.printing` 枚举已在 `AppActivityTracker:21`）。注意：`AppActivityTracker` 是「正在打印」阻塞态，不是已完成打印次数统计；是否记录 completed-only 指标需另有统计契约。
- **1/2/4 题/页第一版用 `PDFExportOptions.itemsPerPage`（已支持 `:66` chunked、`:204` itemHeight）走 PDF Data 直印即达成**（D-I3b 已定降级，`UIPrintPageRenderer` 留后续优化）。
- **打印与分享拆两个一等入口**（D-I3c 已定）：不再把打印藏在分享活动里；UI 提供独立「打印」与「分享」入口。

**为何改良版 B 成立（化解我原 A 的顾虑）**：我原推 A 的理由是「present 留 UI 会让 UC5 correctness 难单测」。改良版 B 用**可注入的 adapter（protocol + MockPrintPresenter）**化解了它——UC5「取消/无打印机→不记打印」的判定逻辑在 Feature View、但靠注 Mock outcome 即可单测，无需真打印机。于是 B 同时拿到「Core 纯净（不吃 UIView）+ adapter 集中不重复 + UC5 可测」三者。Codex 这个设计判断成立，我采纳。

其它实施注意（验证补）：① `withCheckedThrowingContinuation` 防双 resume/泄漏（`UIPrintInteractionController` completionHandler 理论只回一次，仍应防御）；② `ExportPreviewView` 已 `begin(.exporting)`，批量打印路径该用 `.exporting` 还是 `.printing`、并存时 ProfileManager 文案如何呈现，接线时定。

**lane 边界**：Claude 拥 `SnapDrillUI/PrintPresenting.swift` 全部（协议 / `LivePrintPresenter`（UIPrintInteractionController + continuation 桥接）/ `MockPrintPresenter` / `@Environment` key / 单测 completed·cancelled·throw 三分支）；Codex 改 `LibraryDetailView`/`ExportPreviewView`：两个一等入口（打印/分享）、提供 anchor、`PDFExportOptions` 配置 UI、消费 outcome、`.printing` tracker。**adapter 是 SnapDrillUI 层的 testable 工程件（非视觉设计）= 我；入口 IA/视觉 = Codex。**

`[PO]`：✅ 全部已定（D-I3a 改良版 B / D-I3b 降级 / D-I3c 拆两入口）。

**⚠️ 合并 DoD 硬前置**：`UIPrintInteractionController` 在 Simulator 打印支持有限（同 StoreKit 沙箱边界），**真机 iPhone 17 dogfood 验 completed/cancelled/failed 三分支**——UC5 误记会污染未来打印统计，这是数据正确性，非「建议验一次」。

**sequencing**：① `SnapDrillUI/PrintPresenting.swift` 已合入 develop（协议 + LivePrintPresenter + MockPrintPresenter + `@Environment` key + 单测；SnapDrillUI 层、对 Feature 零依赖）→ ② `codex/library-interaction-audit` 正在 Feature View 对接（两入口 + anchor + outcome）→ ③ `.printing` tracker 随 ② 补。**不要先占位空壳再延后——adapter 就是 UI lane 的解锁前提。**

---

## I4 · 导出完成后的 completion / 选择状态契约

**判定：refined。** 严重度 P3。

**事实**：`LibraryView`(`:206-222`) 导出 entry 仅置 `isExportSheetPresented=true`、sheet=`ResolvedExportSheet(ids:)`，**无 onComplete/onDismiss 回调**、不接受 selection 的 Binding，关闭后父层既不清 `selectedItemIDs` 也不退 editMode。对照 `deleteSelectedItems()`(`:298-305`) 就地 `selectedItemIDs.removeAll()` —— 父层**有**清选择能力，只是从未与子 sheet 完成事件接线。兄弟流 `BatchTagSheet`(`:67-74`) 同样只 dismiss —— 是 Library 批量操作的**系统性缺口**。`ResolvedExportSheet.resolvedItems` 初值 `[]`(`:19`)、`.task` 才 resolve(`:37-39`)，首帧必以「0 项」渲染导出表。**⚠️ Codex 称「异步解析」不准**：`fetchModels(by:)`(`ReviewRepository:229-236`) 是**同步 throws 标量主键查询**（`targetIds.contains(item.id)`、无 SIGTRAP），0 项中间态来自 `.task` 触发前的单次预渲染帧、非 async race。

**契约（Claude，Features/UI seam）**：
- **(A) Completion seam**：`ResolvedExportSheet`/`ExportOptionsSheet` 顶层加 `onComplete` 回调，回传 `nonisolated enum ExportOutcome { case exported(ExportArtifact); case shared; case cancelled; case failed(Error) }`（定义在 FeatureLibrary）。父层 `LibraryView` 持 `selectedItemIDs`/editMode、是唯一该执行清/留的层；契约只回传「发生了什么」、由父层裁决。
  - **诚实边界**：SwiftUI `ShareLink` 拿不到「用户是否真完成分享」的回执，PDF/CSV 路径只能保证「发起」。**⚠️ 验证补：ZIP 路径走 `UIActivityViewController`（`ExportOptionsSheet:226-235`）有 `completionWithItemsHandler`、可拿真回执**——ZIP 不必和 ShareLink 一样悲观，可接线为「可确认完成」。`cancelled`（点 Close）可靠。
- **(B) Phase 契约**：`ResolvedExportSheet` 引入 `enum ResolvePhase { case loading; case loaded([ReviewExportSnapshot]); case error(String) }`，初值 `.loading`，消除「首帧 0 项」与「真 0 项」混淆。
  - **2026-06-15 Codex 接线注**：`codex/library-interaction-audit` 已把 `ResolvedExportSheet` 改为 `.loading/.loaded/.failed` phase，首帧显示 `ProgressView`，不再把尚未 resolve 的选择集渲染成 0 项导出表。
  - **⚠️ 验证修正——勿过度工程化**：调查里「改 off-main async resolve」**不成立**——develop 无任何 models 的 async/off-main fetch 路径，`DataExecutor`(`:19-21`) **刻意**用 sync mainContext，`ReviewItemModel` 非 Sendable 不能跨 actor。而 `fetchModels` 是标量主键查询、导出选择集通常不大。**一个 `.loading` phase flag（首帧 `ProgressView`、`.task` 内同步 resolve 完成后转 `.loaded`）即足够，无需新建背景上下文。**
  - **⚠️ 范围比想象小**：`ExportPreviewView` 下游已有完整三态（`:33-43` isLoading/pdfData/error）；`ResolvedExportSheet` 的 `loadError`(`:24-32`) 已是显式态。所以 (B) 只需补 `ResolvedExportSheet` 一处、error case 是把现状收编进 enum——改动面比读起来小、外科手术化。

**lane 边界**：Claude 定 `ExportOutcome`/`ResolvePhase` enum（**冻结形状**）+ `ResolvedExportSheet` 三态重构 + `ExportOptionsSheet` `onComplete` 透传；Codex 填 `onComplete` 闭包内的具体选择态行为（清/留/退 editMode 的动画反馈）+ phase 视觉。**测试**：现无任何 sheet 测试（grep 零命中）；enum 接口变更须补单测（CLAUDE.md「改接口签名后同步测试」铁律）。

`[PO]`：
- ① **导出成功后选择态（三选一）**：**A) 默认清空 selectedItemIDs + 退 editMode**（我推荐——与现有 Done 按钮(`:123-128`)已 `editMode=.inactive`+`removeAll` 的心智一致，等于「自动化 Done 语义」）/ B) 保留选择不退（支持连续多格式导出，但需手动 Done）/ C) 保留选择但退 editMode（折中）。
- ② `cancelled`（点 Close 没真导出）是否也清选择（建议**否**）。
- ③ 「发起导出即视为完成」能否作清选择触发——PDF/CSV 拿不到真回执、ZIP 可精确；涉及「用户以为导出了，其实取消了分享但选择已清空」的体验风险。

---

## 给 PO 的待决清单（汇总，按建议优先级）

| # | 决策 | 我的建议 | 阻塞谁 |
|---|---|---|---|
| ~~D-I3a~~ | PrintService 设计 | ✅ **已定 = 改良版 B**（Core 仅产 PDF Data；adapter 放 SnapDrillUI、可注入测试） | — |
| ~~D-I3b~~ | 第一版 PDF Data 直印、`UIPrintPageRenderer` 降级 | ✅ **已定 = 降级** | — |
| ~~D-I3c~~ | 打印 vs 分享拆两个一等入口 | ✅ **已定 = 拆** | — |
| D-I4a | 导出后选择态 A/B/C | **A**（自动化 Done） | Codex 闭包行为 |
| D-I4b | cancelled 是否清选择 | 否 | Codex 闭包行为 |
| D-I4c | 「发起即完成」作清选择触发是否可接受 | ZIP 精确接线、PDF/CSV 保守 | Codex 闭包行为 |
| D-I2a | loadMore 内存分页缓存是否做 | 先实测再定（守正确性） | 仅性能、可后置 |
| D-I2b | 300ms 防抖时长 | 先做 I1 拆分再看是否仍需调 | UI 手感 |

**无需 PO、我可直接推进的工程契约**：I1 拆分（含取消 bug 修正）、I2 prefetch + benchmark gate、I3 PrintService 协议/DI/Mock 骨架、I4 enum seam + ResolvedExportSheet 三态。这些在 PO 拍板上述产品决策前即可落 Core/Data/Service 层 seam，Codex rebase 后接线。
