# SnapDrill · 开发原则（greenfield）

> **给谁看**：PO、所有 Agent、未来协作者。  
> **目的**：少造轮子、少返工、少「文档和代码各说各话」。  
> **权威顺序**：[`PRD.md`](PRD.md)（做什么）> [`ARCHITECTURE.md`](ARCHITECTURE.md)（怎么拆）> 本文（怎么做事）> [`ENGINEERING.md`](ENGINEERING.md)（做到哪了）。

---

## 1. 总纲（四条）

| # | 原则 | 一句话 |
|---|---|---|
| P1 | **产品只信 PRD** | 需求争议不改代码里的「隐形产品」 |
| P2 | **先合同后实现** | 有边界的模块先 protocol / 类型合同（Capture 已强制） |
| P3 | **用系统框，不造轮子** | Apple 有的先用 PRD §10 栈 |
| P4 | **小步可验收** | 按 Slice + AC 交付，合并前能演示或测过 |

返工大多来自违反 P1（需求漂）或违反 P2（界面和实现缠在一起）。

---

## 2. 不重复造轮子（P3 展开）

### 2.1 必须优先用的（不要自研替代）

| 能力 | 用 | 不要 |
|---|---|---|
| 文档扫描 / 矩形 | VisionKit、Vision | 自写 OpenCV 管线 |
| 图像滤镜 | Core Image | 自写像素循环 |
| 去手写 | Core ML（阶段 0 结论） | 云端 API、自建服务器 |
| 本地库 | SwiftData | 自建 SQLite 封装层 |
| 订阅 | StoreKit 2 | 自建支付 |
| PDF | PDFKit / `UIGraphicsPDFRenderer` | 手绘 PDF 字节流 |
| 多语言 | String Catalog / `LocalizedStringResource` | 硬编码中文 |

**例外**：合同层（`CapturePipelineServing`）是我们自己的「编排」，不是重复造轮子，而是 **把 Apple API 藏在 Service 里**。

### 2.2 可以复用、不要重写的（项目内）

- `ImageEnhancementService`、`HandwritingRemovalService` → 经 **Pipeline 子协议** 接入，不 second 份增强逻辑
- `SubjectCatalog` / `AppBootstrap` → 科目种子唯一入口
- `SnapDrillTheme` → 颜色只在这里定义

### 2.3 旧仓库 `develop` 的用法

| 允许 | 禁止 |
|---|---|
| **定点**阅读某 PR / 文件，cherry-pick 算法思路 | 整分支 merge |
| PO 书面列出「移植清单」后小范围抄写 | 带回旧架构、裁决编号、ADRepo |

移植清单与拣入流程见 [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md)（L01–L12；未勾选「要」前默认不拣）。

---

## 3. 不重复返工

### 3.1 需求返工

- **冻结前**：改 `PRD.md` + PO 确认（v0.8 → v1.0 见 `STAGE0_CHARTER`）
- **冻结后**：改 PRD 须说明影响的 **AC 编号**
- **禁止**：在 PR 里改交互却不碰 PRD；在聊天里拍板不写进 `ARCHITECTURE` §8 决策表

### 3.2 架构返工

- **先合同后 UI**（Capture：[`ARCHITECTURE.md` §3.1](ARCHITECTURE.md)）
- 新领域（Library / PDF / 订阅）上线前：**先加 `*Serving` protocol + Stub + 测试**，再加 Feature
- **禁止**：Feature 里试点相机，再事后「抽服务」——二倍工时

### 3.3 实现返工

| 做法 | 说明 |
|---|---|
| **一 PR 一边界** | 例：仅 Slice 2 步骤 1，不夹带 PDF |
| **对齐 AC 写 Done** | PR 描述贴 AC-02 子集 |
| **Stub 先跑通** | UI 永远对 `Stub` 开发；Live 替换不改 View |
| **动合同必动测试** | `CapturePipelineContractTests` 为模板 |

### 3.4 文档返工

- **不写第二份 PRD**（无 `PRODUCT.md` 影子稿）
- 进度只维护 **`ENGINEERING.md` Slice 表**，不在 README 堆长篇
- 架构决策：**`ARCHITECTURE.md` §8 一行**；不必每事 10 页 ADR

---

## 4. 其他原则（与 P1–P4 并列）

### P5 · 最小可行 diff

只改任务范围内的文件；不顺手「整理全项目」、不升级无关依赖。

### P6 · 方案 1 双线

- **轨道 A（MVP）** 不等待 100 张样张
- **轨道 B（去手写）** 不阻塞 Tab/列表；经 `InkRemoving` / Pipeline 接入
- **禁止**：未过阶段 0 趋势门就宣称 AC-04 全过

### P7 · 隐私与端侧硬约束

PRD Non-Goals：无上传、无行为追踪 SDK。新依赖 **必须** PO 知情。

### P8 · 可测才算完成

- Service / Pipeline：**单元测试**（Simulator 可跑）
- Feature：**手动 Dogfood 步骤** 写在 PR；关键路径后续可加 UI Test

### P9 · 命名与目录跟 ARCHITECTURE 走

`Features/<领域>/`、`Services/<领域>/`；新文件不入散装根目录。

### P10 · 国际化随改动走

动到用户可见文案 → 用可本地化 API，不新增硬编码（AC-10）。

---

## 5. Protocol-First 推广节奏（避免过度）

| 模块 | 何时强制先 protocol |
|---|---|
| **Capture** | ✅ 已强制 |
| **Library**（错题 CRUD） | Slice 3 开始前 |
| **PDF Export** | Slice 6 开始前 |
| **Subscription** | Slice 7 开始前 |
| 简单设置页、空状态插画 | 不强制；跟 `ARCHITECTURE` 即可 |

**小模块**（单个 Toggle）不必 protocol；**跨文件、跨 Agent、会换实现**的才强制。

---

## 6. Pull Request

- 使用仓库模板：[`.github/pull_request_template.md`](../.github/pull_request_template.md)
- **一 PR 一边界**；合并后删远端分支（见 `ARCHITECTURE.md`）
- 典型 MVP 全周期：**约 25–50 个** 有 Scope 的 PR（见下节），不是数百个

### 6.1 PR 数量级（PO 预期）

| 范围 | 粗算 PR 数 | 说明 |
|---|---|---|
| Slice 1–2 Capture + Library | 8–15 | 含合同、三步 UI、入库 |
| 复习 / 列表 / PDF | 8–12 | |
| 订阅 + 同步 + 边界 | 6–10 | |
| 阶段 0 / ML 接入 | 3–8 | |
| 五语 + a11y + 合规文案 | 5–10 | |
| docs / fix / chore | 5–15 | |
| **合计（MVP）** | **~35–70** | 文档约束 + 小 PR → **远少于几百** |
| v1.1 P1、上架打磨 | +15–30 | |

**几百个 PR** 通常意味着：范围过大、重复返工、或 chore 未 squash——与本文原则相反。目标应是 **每个 PR 15 分钟内能看懂**。

---

## 7. Agent / 人 开工检查清单（复制用）

```markdown
- [ ] 读过 PRD 相关节 + ARCHITECTURE + 本文
- [ ] 轨道 A/B/C 明确；不碰「少碰」列
- [ ] 若改 Capture：先 `CaptureContracts.swift` 还是仅 UI？
- [ ] 是否可用 Apple 框架代替自研？
- [ ] 是否复用现有 Service 而非复制粘贴？
- [ ] PR 范围 = 一个 Slice 子项 + 对应 AC
- [ ] 测试：`xcodebuild test` 或写明手测步骤
- [ ] 是否需要 ARCHITECTURE §8 决策行？
```

---

## 8. 修订记录

| 版本 | 日期 | 说明 |
|---|---|---|
| 1.0 | 2026-11-16 | PO 定稿：P1–P10，防造轮子与返工 |
| 1.1 | 2026-11-16 | PR 模板 + MVP PR 数量级预期 |