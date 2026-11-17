# Legacy 零件盘点（greenfield 拣复用）

> **快照**：Git 标签 `legacy/pre-greenfield-2026-11`（`develop` 冻结 @ `f945b725`，2026-07-25）  
> **红线**：greenfield **不 merge** `develop` / 任意 legacy 分支；只按需 **拣零件** 迁入，每零件 **单独 PR**。  
> **权威**：[`ARCHITECTURE.md`](ARCHITECTURE.md) §3、§6；[`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md)；产品行为仍以 [`PRD.md`](PRD.md) 为准。

---

## 1. Legacy 复用政策

| 原则 | 说明 |
|---|---|
| **高内聚、低耦合** | 一次 PR 只迁入 **一个** 可命名「零件」（模块、Service、算法文件集、CI 工作流等），不夹带无关重构。 |
| **合同接入** | 零件必须挂到 greenfield 已有或新建的 **protocol / Service 合同**（例：`CapturePipelineServing`、`HandwritingRemovalService`），Feature **不得** 直接 `import` legacy 包名或复刻旧 DI 容器。 |
| **溯源** | PR 描述与本文盘点表须写明：**legacy 路径**、**快照 commit**（默认 `f945b725` 或标签）、**greenfield 落点目录**、**合同类型**。 |
| **禁止整支 merge** | 不得 `git merge develop`、不得 cherry-pick 合并提交、不得把旧 `Packages/*` 整包拷入而不拆边界。 |
| **考古只读** | 参考实现用 `git show legacy/pre-greenfield-2026-11:<路径>`；本地可 `git checkout develop` 浏览，**不在 develop 上开发**。 |
| **PO 勾选** | 下表「PO 决策」列由 PO 标 **要 / 不要 / 以后**；未勾选前 Agent **默认不拣**该零件。 |

### 1.1 与 greenfield 架构对齐

- **Capture**：UI 仅经 `CapturePipelineServing`；legacy 中 `SnapDrillFeatureCapture` 的 View 一般 **不整文件复用**，可拣 **算法/工具** 进 `Services/Capture` 或 `Services/Image`。
- **阶段 0**：去手写模型与指标在轨道 B；legacy 若仅有 backlog 文档而无实现，记为「无代码可拣」，按 PRD 重新做。
- **测试 / fixture**：可拣 **测试数据与断言思路**；须适配 greenfield 目录与合同，不复制旧包结构。

---

## 2. 零件盘点表（PO 勾选）

**图例**：☐ 要 · ☐ 不要 · ☐ 以后（在 PR 或本文编辑勾选）

| ID | 零件 | Legacy 参考路径（快照内） | 建议 greenfield 落点 / 合同 | 备注 | PO 决策 |
|---|---|---|---|---|---|
| **L01** | 去手写 ML（Core ML 推理、前后处理） | *快照内无独立 ML 实现*；设计见 `docs/features/backlog/` 等 | `Services/Handwriting/` · `HandwritingRemovalService` | 阶段 0 以新模型为主；legacy 多为占位 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L02** | Vision / 文档扫描（VNDocumentCamera、多页） | `Packages/.../SnapDrillFeatureCapture/DocumentScannerView.swift` | `Services/Capture/` · pipeline 内部 | UI 不复用；逻辑 Adapt 进 Live | ☐ 要 ☐ 不要 ☐ 以后 |
| **L03** | 图像增强（三档、透视、裁剪） | `docs/features/backlog/feat-image-enhance.md`；`SnapDrillUI/.../ImageCropperView.swift` | `Services/Image/` · `ImageEnhancing` | 与 PRD 三档对齐再拣 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L04** | PDF 导出（版式、分页、选项） | `Packages/.../Service/PDFExportService.swift` 等 | `Services/Export/` · `PDFExportService`（待建） | 含测试 `PDFExportServiceTests.swift` 可参考 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L05** | StoreKit / Pro 权益 | `Packages/.../Service/ProEntitlementProvider.swift` | `Services/Subscription/` · `ProEntitlementStore` | 核对 PRD §8.6 降级策略 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L06** | CloudKit / iCloud 同步 | `docs/features/backlog/feat-icloud-sync.md`；`SnapDrill.entitlements` | SwiftData + CloudKit 配置；`Services/Subscription` 或横切 | 与 Pro 门槛一致 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L07** | 列表筛选（错因、掌握度、维度） | `Packages/.../SnapDrillFeatureLibrary/LibraryFilterSheet.swift` | `Features/Home/` + `Services/Library/` | greenfield 已有壳；拣 **交互/查询** 非 UI 拷贝 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L08** | 复习（调度、SM-2、会话） | `Packages/.../Engine/ReviewScheduler.swift`、`SM2State.swift` | `Features/Review/` + `Services/` 复习合同 | UI 已壳化；优先拣 **调度引擎** | ☐ 要 ☐ 不要 ☐ 以后 |
| **L09** | 本地化（字符串、L10n 辅助） | `SnapDrill/Resources/*.lproj/Localizable.strings`；`LocalizationHelper.swift` | `*.xcstrings` / `Design` + Feature 文案 | 迁移到 String Catalog，不整文件覆盖 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L10** | CI（GitHub Actions、lint） | `.github/workflows/ci.yml`；`Scripts/ci-local.sh` | `.github/workflows/` | 按 greenfield 单 target 改写，非照搬多 Package | ☐ 要 ☐ 不要 ☐ 以后 |
| **L11** | Stage 0 样张工具（批处理、指标脚本） | `Scripts/` 下通用脚本（非 stage0 专用目录） | `Scripts/`、`Samples/`（**不**提交 `raw/`） | 与 [`STAGE0_CHARTER.md`](STAGE0_CHARTER.md) 对齐 | ☐ 要 ☐ 不要 ☐ 以后 |
| **L12** | 测试 fixture（JPEG 语法、草稿 adversarial） | `Packages/.../Tests/.../Fixtures/`、`CaptureDraftTestWireFixtures.swift` | `SnapDrillTests/` + `Fixtures/` | 仅拣与当前合同相关的用例 | ☐ 要 ☐ 不要 ☐ 以后 |

---

## 3. 单零件 PR 检查清单

复制到 legacy 拣入 PR 描述（可与 [`PR_TEMPLATE.md`](PR_TEMPLATE.md) 并列使用）。

- [ ] 盘点 ID（L0x）与 PO 决策为 **要**（或 PO 在本 PR 书面批准例外）
- [ ] PR **只做一件事**：一个零件边界清晰；无顺带大 refactor
- [ ] 已写明 legacy **路径** + commit/标签 + greenfield **目标路径**
- [ ] 通过 **合同** 接入；Capture UI 未直连 Vision/AVFoundation（若触及收录域）
- [ ] 未 merge `develop`；diff 中无整个 `Packages/SnapDrill*` 无脑迁入
- [ ] 未提交密钥、`Samples/stage0/raw/`、`.xcuserdata`
- [ ] 测试：`xcodebuild test` 或说明 docs-only / 为何跳过
- [ ] 若改变模块边界：已更新 `ARCHITECTURE.md` §4.3 或 §8

---

## 4. 只读考古示例

在仓库根目录执行（**不** checkout 到工作区覆盖文件）：

```bash
# 查看快照 commit
git rev-parse legacy/pre-greenfield-2026-11^{commit}

# 浏览 legacy 单文件内容
git show legacy/pre-greenfield-2026-11:Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportService.swift

# 列出某目录下所有路径
git ls-tree -r --name-only legacy/pre-greenfield-2026-11 -- Packages/SnapDrillCore/Sources/SnapDrillCore/Engine

# 与 greenfield 某文件对比（需先存在 greenfield 路径）
git show legacy/pre-greenfield-2026-11:Packages/.../ReviewScheduler.swift | diff -u - SnapDrill/Services/Review/ReviewScheduler.swift
```

拣入时建议在 PR 中贴 **摘录 diff 摘要**（非整文件 paste），并说明已按 PRD v0.9 / 当前合同改签名之处。

---

## 5. 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-17 | 首版：政策 + L01–L12 盘点表 + PR 清单 + `git show` 示例 |