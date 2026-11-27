# SnapDrill · 开发原则（greenfield）

> **给谁看**：PO、所有 Agent、未来协作者。  
> **目的**：少造轮子、少返工、少「文档和代码各说各话」。  
> **权威顺序**：见 [`GOVERNANCE.md`](GOVERNANCE.md) §1（[`PRD.md`](PRD.md) > [`GOVERNANCE.md`](GOVERNANCE.md) · [`ARCHITECTURE.md`](ARCHITECTURE.md) > 本文 > [`ENGINEERING.md`](ENGINEERING.md)）。全仓文档地图与 PO UX 收权见 [`GOVERNANCE.md`](GOVERNANCE.md)。

| 文档版本 | 1.6 |
|---|---|
| 对应 PRD | 见 [`PRD.md`](PRD.md) 文内当前版 |
| 最后更新 | 2026-11-27 |

---

## 1. 总纲（四条）

| # | 原则 | 一句话 |
|---|---|---|
| P1 | **产品只信 PRD** | 需求争议回到 `PRD.md`，不在代码里做「隐形产品」 |
| P2 | **先合同后实现** | 跨边界模块先定 `*Serving` protocol / 值类型与测试（Capture 与 Slice 2 Library 入库子集均强制） |
| P3 | **用系统框，不造轮子** | Apple 原生框架优先（见下表） |
| P4 | **小步可验收** | 按 `ROADMAP.md` 唯一 `Slice 1–8` 与 AC 交付，合并前能演示或单测通过 |

返工大多来自违反 P1（需求漂移）或违反 P2（界面和底层服务缠在一起）。

---

## 2. 不重复造轮子（P3 展开）

### 2.1 必须优先用的（不要自研替代）

| 能力 | 优先采用（遵守 `ARCHITECTURE.md` 分层） | 禁止 |
|---|---|---|
| 相机预览 / 文档矩形分割 | **唯一锁定**：`AVFoundation` 预览桥接容器 + Vision（`VNDetectDocumentSegmentationRequest`）封装于 `Services/Capture` | 自写 OpenCV 管线、或把 `VNDocumentCameraViewController` 强塞非 UI Service |
| 图像滤镜、编码与降采样 | Core Image（`async` 后台执行）+ ImageIO（降采样、提前异步压缩编码与 `{GPS}` 剥离） | 主线程同步跑大图像素循环 |
| 去手写 | Core ML（懒加载不入启动路径；阶段 0 结论，基于 `MistakeItem.backfillState` 队列并发 1–2 + 6s 超时降级） | 云端 API、自建服务器 |
| 本地库与图片同步 | **单一本地 SwiftData 库（`cloudKitDatabase: .none`，全实体 UUID + 独立 `AnswerImage` + 禁 `.cascade`/`.deny`/`.unique`）+ Apple 原生 `CKSyncEngine`** | 自建 SQLite 封装、手写同步轮询，或强用黑盒自动镜像导致订阅降级无法停上行 |
| 并发与隔离 | Swift 6 结构化并发 / `@concurrent` / `@ModelActor` | 跨隔离域传非 `Sendable` 的 `ModelContext` 或压制并发警告 |
| 订阅 | StoreKit 2（启动即监听、动态 `displayPrice`、加载失败占位重试、宽限期保权益、`isEligibleForIntroOffer`、`.pending` 零权益、`revocationDate`） | 自建支付或硬编码价格文案 |
| PDF | PDFKit / `UIGraphicsPDFRenderer` | 手绘 PDF 字节流 |
| 多语言与外观 | String Catalog（`.xcstrings`）+ 完整 `presetKey` + iOS 26 原生三 `TabView` / Liquid Glass | 硬编码可见文案或手写非对称假底栏 |

**例外**：合同层（如 `CapturePipelineServing`）和 `Services/Capture/` 内协议隔离的轻量相机预览容器是模块边界封装，**不是**重复造轮子。

### 2.2 可以复用、不要重写的（项目内）

- `PhotoDataSanitizing` → 全入口公共脱敏（采集题干图 + `AnswerImage` 答案图必须共用同一入口剥离 `{GPS}`）
- `ImageEnhancementService`、`HandwritingRemovalService` → 经 Pipeline / `LibraryServing` 合同接入，不复制第二份增强或去手写逻辑
- `SubjectCatalog` / `AppBootstrap` → 6 地区（含新加坡 4 科）+ 全球英语预置科目及完整 `presetKey` 唯一入口
- `SnapDrillTheme` → 固定 3 套主题 × 浅/深（全 6 组 WCAG AA）只在这里定义

### 2.3 旧仓库 `develop` 的用法

| 允许 | 禁止 |
|---|---|
| 只读考古，针对 [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) 已标 `[x] 要` 的条目提取测试思路或 CI 脚本 | 整分支 merge、`git merge develop` 或带回旧 DI 容器与超范围 P1/P2 功能（如 SM-2） |

政策与 L01–L12 勾选状态见 [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md)。

---

## 3. 不重复返工

### 3.1 需求返工

- **冻结前**：先改 [`PRD.md`](PRD.md) 并经 PO 确认（冻结门见 [`STAGE0_CHARTER.md`](STAGE0_CHARTER.md) 与 [`ROADMAP.md`](ROADMAP.md)）
- **冻结后**：改 PRD 须明确影响的 **AC 编号**
- **禁止**：在代码 PR 里改交互却不碰 PRD；在聊天里口头拍板不写入 [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 决策表

### 3.2 架构返工

- **先合同后 UI**（Capture 与 `LibraryServing` Slice 2 入库子集：[`ARCHITECTURE.md`](ARCHITECTURE.md) §3.1、§4.3）
- 新领域按 §5 节奏上线前：**先加 `*Serving` protocol + Stub + 契约测试**，再加 Feature UI
- **禁止**：在 Feature View 里直接试点相机/Vision/SwiftData 写入，再事后「抽服务」——二倍工时

### 3.3 实现返工

| 做法 | 说明 |
|---|---|
| **一 PR 一边界** | 例：仅 Slice 2 步骤 1，或仅 `LibraryServing` 入库合同，不夹带 PDF 或订阅 |
| **对齐 AC 写 Done** | PR 描述贴对应的 `AC-0x` 子集 |
| **Stub 先跑通** | UI 对 `Stub` 稳定联调；Live 替换不破坏 View 合同 |
| **动合同必动测试** | 变更协议签名或边界行为时，同步更新单元测试 |

### 3.4 文档返工

- **不写第二份 PRD**（无 `PRODUCT.md` 或独立 UX 影稿）
- 进度只维护 [`ENGINEERING.md`](ENGINEERING.md) Slice 表，不在 README 堆长篇
- 架构决策只在 [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 追加一行，不另起 ADR 文档森林

---

## 4. 其他原则（与 P1–P4 并列）

### P5 · 最小可行 diff
只改任务范围内的文件；代码 PR 不触碰已冻结的 `Docs/` 与 `Samples/`；不顺手全盘重构无关模块。

### P6 · 方案 1 双轨并行
- **轨道 A（MVP）** 不阻塞于 100 题样张收齐；使用增强原图占位推进
- **轨道 B（阶段 0）** 通过 `HandwritingRemovalService` 对接，不直接大改业务 Feature
- **禁止**：未过阶段 0 趋势门与冻结门就宣称 `AC-04` 全量达标或上架主打自动去手写

### P7 · 隐私、未成年人与端侧硬约束
[`PRD.md`](PRD.md) §9 / §9.1：无自建业务服务器、零第三方行为追踪 SDK；遵守 PIPL(<14 岁)/COPPA/GDPR 知情告知与无主动账号采集原则，如实披露 Pro iCloud 私有同步；新增任何第三方依赖 **必须** PO 书面批准。

### P8 · 可测才算完成
- Service / Pipeline / 降级边界（6 秒超时、磁盘 ≥ 50 MB 预检、三态 5 秒撤销墓碑、连删科目逐题墓碑、`CKSyncEngine` 启停合并、宽限期/`.pending` 零权益/撤销）：**单元测试**（Simulator 可跑）
- Feature：**真机手测步骤与实测记录**写在 PR，关键流程配 UI Smoke Test

### P9 · 命名与目录跟 ARCHITECTURE 走
`Features/<领域>/`、`Services/<领域>/`、`Models/`、`Design/`；新文件不散落根目录。

### P10 · 国际化与无障碍随改动走
凡新增或改动用户可见文案，**必须**同步写入 UI 5 语 String Catalog（简中、繁中、日、韩、英）**与**完整 `25 个 presetKey × 6 语/地区`语义列（**显式区分 `zh-Hant-TW` 与 `zh-Hant-HK`，统一以 [`PRD.md`](PRD.md) §3.1 神谕表与 `AC-10` 为唯一验收准绳**），不得留存硬编码；控件热区 ≥ 44pt 且配 VoiceOver 标签、响应动态字体、满足全 6 组调色板 WCAG AA 与 Reduce Motion。

---

## 5. Protocol-First 推广节奏（对齐唯一 `Slice 1–8`）

| 模块 | 何时强制先 protocol（对齐 [`ROADMAP.md`](ROADMAP.md)） |
|---|---|
| **Subscription & Sync（`CloudKitSyncEngine` Stub 先行 + Live 切换）** | **Slice 1 开始前先落 `CloudKitSyncEngine` 协议 + 内存 No-Op/Stub**（含 `enqueueUpsert`/`enqueueDeletion` 与 `initialZoneFetchCompleted`/`initialZoneFetchFailed(reason)`，**Slice 1–6 零 CloudKit I/O**，供 Slice 1 `SubjectCatalog`、Slice 2 异步编码、Slice 3 去手写与 Slice 4 `LibraryServing` 编译注入）；**Slice 4 前先落只读恒 Free `ProEntitlementStore` Stub**；**Slice 7 开始前**无缝切换 Live `ProEntitlementStore` 与 Live `CloudKitSyncEngine`（不改签名；遵循 6 条 Spike 与 `CKRecord` 映射表） |
| **Capture**（2 步采集管线） | ✅ 已强制（`CapturePipelineServing`） |
| **Library（核心入库与磁盘预检子集）** | **Slice 2 开始前**（`commitSave` 含 300 ms 编码上界、`isOriginalEncoded`、≥50 MB 预检、回滚、`MistakeItem.backfillState` + 单测） |
| **Handwriting（`HandwritingRemovalService`）** | **阶段 0 结论后 / Slice 3 开始前**先落 protocol + Stub + 契约测试（懒加载、6 秒超时、`cleanedImageSource = none` 降级、代际/`editNonce` 防覆盖及与 `Services/Image/AsyncEncodingQueue` 互斥谓词，见 `ARCHITECTURE.md` §4.3） |
| **Library（完整图库 CRUD/筛选/5s 三态撤销/重裁）** | **Slice 4 开始前** 在既有 `LibraryServing` 上扩展（含提交快照——使用 Slice 4 前已落地的只读恒 Free `ProEntitlementStore` Stub、窄权限 `enqueueDeletion`/`enqueueUpsert` [使用 Slice 1 前已落地的内存 No-Op/Stub `CloudKitSyncEngine`，Slice 1–6 零 CloudKit I/O]、`AnswerImage` 逐条墓碑与 ≤ 3 重排、设置域管理及字段上限遵从 PRD §8.6） |
| **Review**（`ReviewServing`：继承筛选与卡片会话） | **Slice 5 开始前**先落 `ReviewServing` 协议与契约测试（**排除 `pendingDeletionAt != nil`、Tab 与列表双入口 0 题禁用**） |
| **PDF Export**（`PDFExportService`） | **Slice 6 开始前**（Feature/Coordinator 读取只读 `ProEntitlementStore` 快照后构造含 **`paper`、`whitespaceRatio`、`showsWatermark`、`includesAnswerAppendix`** 4 字段的 `ExportLayoutOptions` 显式注入 `PDFExportService`；服务内部不直接持有 Store 或读 `@AppStorage`，见 `ARCHITECTURE.md` §4.3） |
| 简单设置开关、静态引导空状态 | 不强制过度抽象；直接遵守 `ARCHITECTURE.md` 分层即可 |

---

## 6. Pull Request 与工作量参考

- **唯一模板**：提交 PR 时使用仓库根目录 [`.github/pull_request_template.md`](../.github/pull_request_template.md)（参见 [`PR_TEMPLATE.md`](PR_TEMPLATE.md)）。
- **合并纪律**：**一 PR 一边界**；合入后删除远端分支；每个 PR 应控制在审阅者 15 分钟内可看懂的粒度。
- **PR 数量级预期**：全周期 MVP PR 粗估统一见唯一估算表 [`PR_SCOPE_ESTIMATE.md`](PR_SCOPE_ESTIMATE.md)（本文不再重复列算矛盾数字）。

---

## 7. Agent / 人 开工检查清单（复制用）

```markdown
- [ ] 已读 PRD 相关节 + ARCHITECTURE + 本文 + GOVERNANCE §2（PO UX 收权）
- [ ] 轨道（A/B/C/D）与唯一 Slice（1–8）明确；未触碰未授权目录
- [ ] 是否涉及 UX 变更？非 bugfix 变更须先改 PRD 并经 PO 签收 ARCHITECTURE §8
- [ ] 优先使用 Apple 原生框架（如 CKSyncEngine）/ 现有公共 Service（PhotoDataSanitizing / LibraryServing），未重复造轮子
- [ ] 未新建 Docs/*.md；Legacy 仅在 LEGACY_PARTS_INVENTORY 标 [x] 要 时拣入
- [ ] 新增文案已同步 UI 5 语 String Catalog 与 25 presetKey × 6 语/地区（区分 TW/HK，P10）；未提交 Samples/stage0/raw/ 或密钥
- [ ] 动到合同已同步增改单元测试；PR 附实测设备与测试结果
```

---

## 8. 修订记录

| 版本 | 日期 | 说明 |
|---|---|---|
| 1.0 | 2026-11-16 | 首版：P1–P10，防造轮子与返工 |
| 1.1 | 2026-11-16 | 补充 PR 模板与数量级预期 |
| 1.2 | 2026-11-27 | 盲审闭环：清除过期版本引用；合并互斥 PR 估算表；对齐唯一 `Slice 1–8` |
| 1.3 | 2026-11-27 | 冻结前复审：权威链补回 `GOVERNANCE.md`；前置 `LibraryServing` 入库子集 |
| 1.4 | 2026-11-27 | 冻结前终审定案：§2.1/§5 对齐 **单一本地 SwiftData 库 + Apple 原生 `CKSyncEngine`**、统一 `MistakeItem.backfillState`、独立 `AnswerImage` 与禁 `.cascade` |
| 1.5 | 2026-11-27 | 纪律与合同粒度对齐：明确 P10 UI 5 语与 25 个 `presetKey` 6 语义列（区分 `TW`/`HK`）共同以 `PRD.md` §3.1 与 `AC-10` 为准；同步 `ReviewServing`、`isOriginalEncoded` 与 `CKSyncEngine` 6 条 Spike 前置 |
| 1.6 | 2026-11-27 | 协议节奏对齐：明确 Slice 1 开始前先落 `CloudKitSyncEngine` 协议与内存 No-Op/Stub（含 `initialZoneFetchCompleted`/`initialZoneFetchFailed`，Slice 1–6 零 CloudKit I/O）、阶段 0 后/Slice 3 前落 `HandwritingRemovalService` 合同、Slice 4 前先落只读 `ProEntitlementStore` 恒 Free Stub（Slice 7 均无改签名切 Live）；补充 `ReviewServing` 待删排除/双入口 0 题约束，并统一由 Feature 读取快照构造 4 字段 `ExportLayoutOptions` 后显式注入 `PDFExportService` |
