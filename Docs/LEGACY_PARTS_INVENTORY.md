# Legacy 零件盘点（greenfield 拣复用）

> **快照**：Git 标签 `legacy/pre-greenfield-2026-11`（`develop` 冻结 @ `f945b725`，2026-07-25）  
> **红线**：greenfield 以全新实现为主，**不 merge** `develop` / 任意 legacy 分支；仅对下表已标 **`[x] 要`** 的项目按需拣入，每零件 **单独 PR**。  
> **权威**：[`GOVERNANCE.md`](GOVERNANCE.md) §1、[`ARCHITECTURE.md`](ARCHITECTURE.md) §3/§6、[`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md)；产品行为以 [`PRD.md`](PRD.md) 文内当前版为准。

| 文档版本 | 1.3 |
|---|---|
| 对应 PRD | 见 [`PRD.md`](PRD.md) 文内当前版 |
| 最后更新 | 2026-11-27 |

---

## 1. Legacy 复用政策

| 原则 | 说明 |
|---|---|
| **高内聚、低耦合** | 一次 PR 只迁入 **一个** 已批准的零件（CI 工作流或单合同测试 fixture 集），不夹带无关重构。 |
| **合同接入** | 若参考旧代码思路重写或迁入测试，必须严格挂到 greenfield 新接口合同与目录结构，**严禁**将旧 `Packages/*` 整包或旧 `UI` 文件直接拷入 `Services/`。 |
| **精确溯源** | PR 描述与本文盘点表须写明：**精确 legacy 文件路径**（禁止使用省略号）、快照标签/commit、greenfield 落点目录。 |
| **禁止整支 merge** | 严禁 `git merge develop`、严禁 cherry-pick 合并提交、严禁带回旧 DI 容器与未授权模块。 |
| **考古只读** | 使用 `git show legacy/pre-greenfield-2026-11:<路径>` 查看历史参考；不在 `develop` 分支开发。 |
| **PO 勾选闸门** | 仅下表 PO 决策标为 **`[x] 要`** 的条目可执行拣入；标 **`[x] 不要`** 的仅限只读参考思路（代码在 greenfield 全新重写）；标 **`[x] 以后`** 的属 P1/P2 范围，MVP 严禁拣入。若需例外，必须在 PR 中获得 PO 针对该 PR 的书面特批。 |

### 1.1 与 greenfield 架构对齐校验

- **Capture（L02）**：因 greenfield 已废除把 `VNDocumentCameraViewController` 强塞进非 UI Service 的矛盾方案，P0 唯一锁定 `AVFoundation` 预览桥接 + Vision（见 [`ARCHITECTURE.md`](ARCHITECTURE.md) §3.1），旧扫描 View 不复用。
- **Image（L03）**：`ImageCropperView.swift` 属于 SwiftUI 界面组件，**严禁落入 `Services/Image/`**（遵守 `ARCHITECTURE.md` §3 禁止 Service 塞业务 View 的红线）。
- **Library / Review（L07b / L08）**：旧仓库包含 **P1 掌握度** 与 **P2 Pro 的 SM-2 间隔重复**（`F-26`/`F-32`/`F-42`），MVP 阶段严禁拣入，避免复杂度提前污染首版数据库 Schema。

---

## 2. 零件盘点表（PO 2026-11-27 拍板定稿）

**图例**：`[x] 要`（可按新架构改写迁入） · `[x] 不要`（greenfield 全新重写，legacy 仅作只读思路参考） · `[x] 以后`（P1/P2 阶段再议，MVP 禁入）

| ID | 零件 | Legacy 精确路径（`legacy/pre-greenfield-2026-11` 快照内） | Greenfield 口径 / 落点 | 范围校验与备注 | PO 决策 |
|---|---|---|---|---|---|
| **L01** | 去手写 ML | *快照内无独立实现*；见 `docs/features/backlog/` | 轨道 B 全新验证 → `Services/Handwriting/` | 阶段 0 全新落地 `HandwritingRemovalService`（6s 超时降级） | `[x] 不要`（全新） |
| **L02** | 文档扫描 View | `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/DocumentScannerView.swift` | `Services/Capture/`（全新实现） | 唯一锁定 `AVFoundation` 预览桥接 + Vision，不复用系统扫描封装 | `[x] 不要` |
| **L03** | 图像增强与裁剪 | `docs/features/backlog/feat-image-enhance.md`<br>`Packages/SnapDrillUI/Sources/SnapDrillUI/ImageCropperView.swift` | `Services/Image/`（仅纯 `async` 滤波算法参考） | 严禁把 SwiftUI `ImageCropperView` 放入 `Services/Image/`；增强已改 `async` 后台执行 | `[x] 不要` |
| **L04** | PDF 导出 | `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportService.swift` | `Services/Export/PDFExportService`（全新实现） | 按 `PRD §8.5` 全新实现（B5 默认、统一留白公式、双超页缩放、打印共用水印；测试参考 L12） | `[x] 不要` |
| **L05** | StoreKit 权益 | `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/ProEntitlementProvider.swift` | `Services/Subscription/ProEntitlementStore`（全新） | 按 iOS 26 StoreKit 2 + `isEligibleForIntroOffer` + 宽限/重试 + `.pending` 零权益 + `revocationDate` 重写 | `[x] 不要` |
| **L06** | CloudKit 同步 | `docs/features/backlog/feat-icloud-sync.md`<br>`SnapDrill/SnapDrill.entitlements` | `Models/`（UUID/墓碑）+ `Services/Sync/CloudKitSyncEngine` | 改用单一本地 SwiftData 库 + **Apple 原生 `CKSyncEngine`** 实现真启停控制面 | `[x] 不要` |
| **L07a** | P0 常规列表筛选 | `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryFilterSheet.swift` | `Features/Home/` + `Services/Library/`（全新） | P0 仅按科目/错因/标签/`createdAt` 日期筛选，全新实现 | `[x] 不要` |
| **L07b** | P1 掌握度筛选部分 | `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryFilterSheet.swift` | P1 `F-26` / `F-32`（v1.1） | **P1 掌握度能力，MVP 严禁提前拣入** | `[x] 以后` |
| **L08** | 复习调度 / SM-2 | `Packages/SnapDrillCore/Sources/SnapDrillCore/Engine/ReviewScheduler.swift`<br>`Packages/SnapDrillCore/Sources/SnapDrillCore/Engine/SM2State.swift` | P2 Pro `F-42`（v1.x） | **SM-2 为 P2 能力，MVP 严禁拣入**；P0 复习按 `PRD §8.4` 顺序/乱序全新实现 | `[x] 以后`（P2 阶段再审） |
| **L09** | 本地化辅助 | `SnapDrill/Resources/*.lproj/Localizable.strings`<br>`Packages/SnapDrillCore/Sources/SnapDrillCore/Support/LocalizationHelper.swift` | `*.xcstrings` + 完整 `presetKey` | iOS 26 直接使用 String Catalog 与 `presetKey` 动态翻译，不迁旧 `.strings` | `[x] 不要` |
| **L10** | CI 工作流与本地校验 | `.github/workflows/ci.yml`<br>`Scripts/ci-local.sh` | `.github/workflows/`、`Scripts/` | 按 greenfield 单 target 改写，落地自动静态守门（禁跨层/禁硬编码/单测/lint） | **`[x] 要`** |
| **L11** | Stage 0 工具脚本 | *快照内无 stage0 专用目录*（通用在 `Scripts/`） | `Scripts/`、`MLPipeline/` | 按新版单题 Hold-out 评估规程独立实现 | `[x] 不要` |
| **L12** | 测试与 Wire Fixtures | `Packages/SnapDrillCore/Tests/SnapDrillCoreTests/CaptureDraftTestWireFixtures.swift`<br>`Packages/SnapDrillCore/Tests/SnapDrillCoreTests/PDFExportServiceTests.swift`<br>`Packages/SnapDrillCore/Tests/SnapDrillCoreTests/ReviewSchedulerTests.swift` | `SnapDrillTests/` | 仅挑选适配当前新合同的极端 JPEG / 草稿 / PDF 分页断言思路与测试样例（**剔除 SM-2 用例**） | **`[x] 要`**（仅测试思路/样例） |

---

## 3. 单零件 PR 检查清单

拣入 `[x] 要` 条目（L10 / L12）时，在 PR 描述中同步核对（并配合 [`.github/pull_request_template.md`](../.github/pull_request_template.md)）：

- [ ] 盘点 ID（L10 / L12）已标 **`[x] 要`**（其他条目若需参考代码须有 PO 在本 PR 书面特批）
- [ ] PR **只做一件事**：边界清晰，不夹带旧包架构或超范围功能（如 SM-2、掌握度）
- [ ] 已写明上方精确 legacy 路径 + 标签 `legacy/pre-greenfield-2026-11` + greenfield 落点路径
- [ ] 未 merge `develop`；diff 中无旧 `Packages/SnapDrill*` 模块或旧 UI 混入 `Services/`
- [ ] 未提交密钥、`Samples/stage0/raw/`、`.xcuserdata`
- [ ] `xcodebuild test` / CI 脚本在目标环境跑绿

---

## 4. 只读考古示例

在仓库根目录执行（**不** checkout 到工作区覆盖文件）：

```bash
# 查看快照 commit
git rev-parse legacy/pre-greenfield-2026-11^{commit}

# 浏览已标 [x] 要 的测试 fixture 思路
git show legacy/pre-greenfield-2026-11:Packages/SnapDrillCore/Tests/SnapDrillCoreTests/PDFExportServiceTests.swift

# 浏览已标 [x] 要 的 CI 工作流参考
git show legacy/pre-greenfield-2026-11:.github/workflows/ci.yml

# 仅只读对比旧算法思路（注意禁止将旧 SM-2 引入 MVP）
git show legacy/pre-greenfield-2026-11:Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportService.swift
```

拣入 `[x] 要` 条目时，须在 PR 中附摘要并注明已按 [`PRD.md`](PRD.md) 文内当前版与 [`ARCHITECTURE.md`](ARCHITECTURE.md) 合同完成改写适配。

---

## 5. 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-17 | 首版：政策 + L01–L12 盘点表 + PR 清单 + `git show` 示例 |
| 2026-11-17 | 澄清 cherry-pick 合并提交 vs 单文件迁入；审阅小修 |
| 2026-11-27 | 盲审闭环（D8）：PO 完成全表勾选（仅 L10/L12 `[x] 要`，L08 SM-2 标 `[x] 以后`，其余 `[x] 不要`）；补齐全部精确 legacy 路径；消除硬编码 PRD 版本号 |
| 2026-11-27 | 冻结前终审定案：将 L07 拆为 `L07a`/`L07b` 消除双勾歧义；L06 落点更新为单一本地 SwiftData 库 + Apple 原生 `CKSyncEngine` |
