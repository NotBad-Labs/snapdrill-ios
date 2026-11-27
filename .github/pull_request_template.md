## Summary

<!-- 1–3 句：本 PR 解决什么用户/AC/架构问题 -->

## 轨道 / 范围

| 项 | 填写 |
|---|---|
| 轨道 | A · MVP / B · 阶段 0 / C · 商业化 / D · 横切 |
| 唯一 Slice | 例：Slice 2 · 2 步采集步骤 1（严格对齐 `Docs/ROADMAP.md` `Slice 1–8`） |
| **本 PR 做** | |
| **本 PR 不做** | <!-- 明确排除，防范围蔓延 --> |

## PRD / 合同

| `PRD.md`（文内当前版） | 对应 AC | 架构合同（`*Serving`） |
|---|---|---|
| § | AC- | 无 / `CapturePipelineServing` / `LibraryServing` / `CloudKitSyncEngine` / … |

## 治理、安全与 Legacy 门禁（合并必检）

- [ ] **PO UX 收权**：未把未签字演示草稿扩成正式交互；若改可见交互，已先更新 `PRD.md` 并经 PO 在 `ARCHITECTURE.md` §8 签收对应 PRD 版本与日期
- [ ] **文档边界**：未新建未批准的 `Docs/*.md`；代码 PR 未擅自修改已冻结的 `Docs/` 与 `Samples/`；未照搬 `Docs/archive/` 内已失效选型
- [ ] **Legacy 闸门**：未 merge `develop`；若参考/拣入旧仓代码，已在 `Docs/LEGACY_PARTS_INVENTORY.md` 标 `[x] 要`（仅 L10/L12）或附 PO 本 PR 书面特批，绝未混入 SM-2 / P1 掌握度
- [ ] **合同与单测**：若变动 `*Serving` 接口（含 Slice 2 `LibraryServing` 核心入库子集）或降级/合并/墓碑边界，已同步增改单元测试（`xcodebuild test` 通过）
- [ ] **隐私与机密红线**：确认 diff 中无 `Samples/stage0/raw/` 样张、密钥、个人数据及 `.xcuserdata`

## iOS 26+ 架构与工程硬红线自查（见 `PRD.md` §3.2、`Docs/ARCHITECTURE.md` §3 与 `Docs/DEVELOPMENT_PRINCIPLES.md`；本地/CI 工具链补充检查不得覆盖 L0–L4）

- [ ] **架构隔离**：`Features/` 零底层视觉/相机/CoreImage/CoreML/PDFKit/CloudKit 业务直连；`Models/` 零 UIKit/SwiftUI 且遵守自生成 UUID + 单一本地库 `CKSyncEngine`（含 `isOriginalEncoded`、`needsLocalBackfill`、`needsCloudUpload`、`pendingDeletionAt`、`backfillStateRaw`、`cleanedImageSourceRaw`、`editNonce`、独立 `AnswerImage` 含 `updatedAt` 与 `DeleteTombstone(presetKey)` / 云端 `DeletedPresetKey`、全模型统一 `.nullify`，禁 `.cascade`/`.deny`/`.unique`）；`Services/` 不夹带业务 SwiftUI View（**唯一例外**：允许 `Services/Capture/` 暴露协议隔离的轻量相机预览桥接容器，全部裁剪/交互 UI 留在 `Features/Capture/`）；`PDFExportService` 仅注入由 Feature 读取只读权益快照构造的 `ExportLayoutOptions`
- [ ] **Swift 6+ 并发**：Complete checking + Release 构建零警告；图像处理/`Services/Image/` 10 秒补压编码/去手写（懒加载，仅查 `needsLocalBackfill == true && isOriginalEncoded == true`）/PDF/`CKSyncEngine`（含冷启动先按 `stateData` 引用清孤儿暂存、提交待删再启引擎、运行中变更必调 `enqueue*`、删除错题为每个子 `AnswerImage` 逐条写墓碑、`syncedToCloud == false` 与 `needsCloudUpload` 入队、交错落地先过墓碑闸、未编码窗禁覆写题图资产、回灌重申云删、非空入站题图资产置 `isOriginalEncoded = true`、同 `UUID` `editNonce` 平局 LWW、`AnswerImage ≤ 3` 重排、`CloudKitSyncEngine` Slice 1–6 Stub 与 `ProEntitlementStore` Slice 4 恒 Free Stub 均在 Slice 7 切 Live 及 6 条 Spike 基线）显式后台异步执行（无主线程同步阻塞）
- [ ] **状态与 Glass UI**：`@Observable` + 原生三 `TabView`（无非对称假底栏、非 `tabViewBottomAccessory`）；适配固定 3 套主题 × 2 外观（全 6 组调色板过 WCAG AA）；`.pending` 零 Pro 权益授权
- [ ] **端侧图像与 AI**：大图经 ImageIO 降采样及公共 `PhotoDataSanitizing` 剥离 `{GPS}`（含题干图、`AnswerImage` 答案图及 `CaptureDrafts` 草稿）；AI/同步失败显式降级或提示（`failed` 保持 `cleanedImageData = nil`；`cleanedImageSource == manual` 时重跑与重裁均须二次确认）；`tmp/pdf-export/` 整目录按触发器清空，其余碎片仅清白名单且显式排除 `Application Support/CaptureDrafts/`、SwiftData 外部存储与 `Application Support/CKAssetUploadStaging/`
- [ ] **无障碍与本地化（P10）**：无新增硬编码 UI 文案，UI 5 语 `Localizable.xcstrings` + 完整 `25 presetKey × 6 语/地区`（区分 `zh-Hant-TW` 与 `zh-Hant-HK`）已同步；热区 ≥ 44pt + `accessibilityLabel` + Reduce Motion 支持

## 测试与真机验证记录

- [ ] `xcodebuild test` / Lint 检查全绿（写明执行目标，或 N/A 仅 docs PR）
- [ ] 实测设备 / 模拟器型号：
- [ ] 实测步骤与观察结果：

```text
1.
2.
结果：
```

## 决策记录

- [ ] 无需更新 `Docs/ARCHITECTURE.md` §8
- [ ] 已更新 `Docs/ARCHITECTURE.md` §8（仅文档 PR 或 PO 书面批准时填写一行摘要）：

---

> 本文件为全仓 **唯一 PR 模板真源**；规则遵循 [`Docs/GOVERNANCE.md`](../Docs/GOVERNANCE.md) 与 [`Docs/DEVELOPMENT_PRINCIPLES.md`](../Docs/DEVELOPMENT_PRINCIPLES.md)（参见 [`Docs/PR_TEMPLATE.md`](../Docs/PR_TEMPLATE.md)）。
