# SnapDrill · 文档治理与 PO 收权（greenfield）

> **给谁看**：PO、所有 Agent。  
> **目的**：控制文档数量与权威漂移；建立完整 L0–L5 冲突裁决矩阵；明确 **UI/UX 与产品裁决归 PO**；废除幽灵文档与未定义术语，避免 Agent 把草稿壳当成已定产品。  
> **全仓唯一索引**：下文 §3 为全仓 Markdown 唯一导航地图；各文档不再重复维护局部索引或拷贝 PRD 正文。

---

## 1. 权威顺序与冲突裁决矩阵（L0–L5）

当两份文档出现理解分歧或规则冲突时，严格按以下 **层级与域正交规则** 裁决（高权威无条件覆盖低权威；发现跨文档实质矛盾时，须按本链向上回修，不得在下游绕过）：

```text
L0 · PRD.md（产品做什么、交互、AC、边界唯一权威）
  └─▶ L1 · 技术结构与流程治理（域内正交；任何产品行为分歧退回 L0）
        ├─ GOVERNANCE.md             （文档分层地图、PO UX 签收权、防文档爆炸）
        ├─ ARCHITECTURE.md           （模块边界、Swift 6 并发、数据持久化、协议合同、§8 决策表）
        ├─ DEVELOPMENT_PRINCIPLES.md （P1–P10 工程纪律、Protocol-First 节奏、施工规约）
        └─ LEGACY_PARTS_INVENTORY.md （legacy 快照复用政策与 L01–L12 PO 勾选闸门）
           （域内优先序：GOVERNANCE（流程/收权） · ARCHITECTURE（结构/接口） > DEVELOPMENT_PRINCIPLES > LEGACY_PARTS_INVENTORY）
  └─▶ L2 · 阶段计划与验证门禁（必须服从 L0 + L1）
        ├─ ROADMAP.md                （全仓唯一 Slice 1–8 编号、里程碑灯、UX/Spike/上架前置门）
        └─ STAGE0_*.md               （阶段 0 验证章程、单题裁剪 Hold-out 标准、样张台账）
  └─▶ L3 · ENGINEERING.md            （编译环境、基线设备、当前实际实现进度）
  └─▶ L4 · .github/pull_request_template.md（PR 模板唯一真源；Docs/PR_TEMPLATE.md 为指针）
  └─▶ L5 · 非权威参考
        ├─ PR_SCOPE_ESTIMATE.md      （PR 数量级粗估，不作工期/范围拍板依据）
        └─ archive/*                 （已失效只读历史快照，严禁作现行开发、合同命名或技术选型依据）
```

| 争议类型 | 唯一权威来源 | 禁止事项 |
|---|---|---|
| 产品功能、交互流转、边界、AC | **仅** [`PRD.md`](PRD.md) | 在 Feature、Service 或下游文档里「偷偷改规则」 |
| 文档层级、UX 冻结状态、建档权限 | **本文** [`GOVERNANCE.md`](GOVERNANCE.md) | 自建并行总则或绕过 PO 签收直接扩交互 |
| 模块分层、Swift 6 隔离、接口合同 | [`ARCHITECTURE.md`](ARCHITECTURE.md) §3、§4、§8 | 跨层直连（如 UI 直连 PDFKit/Vision/相机） |
| 开发纪律、Protocol-First 阶段 | [`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md) | 跳过合同与单元测试先堆 UI |
| 能否从 `develop` 拣入旧代码 | [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) | 未标 `[x] 要` 前迁入 legacy 代码 |
| 里程碑与全仓唯一 Slice 编号 | [`ROADMAP.md`](ROADMAP.md) | 另立第二套 Slice 编号 |
| 进度实态、构建与设备配置 | [`ENGINEERING.md`](ENGINEERING.md) | 在 README 堆进度叙事或反向推翻 PRD 决议 |

**PRD 版本引用铁律**：仅 [`PRD.md`](PRD.md) 文内维护当前版本号；**全仓其余所有文档只写“见 [`PRD.md`](PRD.md) 文内当前版”**，严禁各写各的硬编码版本号，防止跨文档版本漂移。

---

## 2. PO 收权 · UI / UX 冻结机制

| 状态 | 含义 | 唯一载体 |
|---|---|---|
| **已定产品** | 已写入 [`PRD.md`](PRD.md) §8 等交互/边界并经 PO 确认的内容 | [`PRD.md`](PRD.md) |
| **Agent 演示草稿** | 本地占位界面、`UIDemoDataService` 假数据、未签字 PR 中的临时布局/文案 | 仅演示用，**不构成产品承诺** |
| **UX 冻结（PO 签收）** | 在 [`ROADMAP.md`](ROADMAP.md)「Slice 2 合并前」完成核心主路径评审，并将签收结果写入 [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 决策表 | [`PRD.md`](PRD.md) §8 + [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 |

> 已正式废除原规划中的独立 UX 占位影稿与未定义术语，**不新建任何独立 UX 影稿文件**；[`PRD.md`](PRD.md) §8 与 [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 为产品与 UX 签收的唯一共同载体。

**Agent 硬规则：**

1. **不得**把演示草稿的临时布局、控件位置、未写入 PRD 的状态当成已批准规格而擅自扩大。
2. 改 **可见交互默认值或页面流转**（非 bugfix）：**必须先更新 [`PRD.md`](PRD.md)**；[`ARCHITECTURE.md`](ARCHITECTURE.md) §8 仅记录 PO 已签收的 `PRD.md` 版本与日期，不得在 §8 单独写入与 [`PRD.md`](PRD.md) 不同的交互行为。
3. 在 PO 签字 UX 冻结前补 UI，优先级严格为：`PRD.md` 条文 → 原生 iOS 26 HIG 控件 → 最小必要实现；**禁止**无据即兴发挥。

---

## 3. 全仓文档分层地图（唯一索引）

| 层级 | 文档 | 权威？ | 维护者 | 一句话职责 |
|---|---|:---:|---|---|
| **L0** | [`PRD.md`](PRD.md) | ✅ 产品唯一 | PO | 做什么、交互与边界、MVP 10 条 AC |
| **L1** | [`GOVERNANCE.md`](GOVERNANCE.md)（本文） | ✅ 治理唯一 | PO | 文档地图、L0–L5 裁决链、PO UX 收权 |
| **L1** | [`ARCHITECTURE.md`](ARCHITECTURE.md) | ✅ 架构与合同 | PO + 技术负责人 | 分层、Swift 6 并发、单一本地库+`CKSyncEngine` 与协议合同、§8 决策表 |
| **L1** | [`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md) | ✅ 工程纪律 | PO + 技术负责人 | P1–P10 原则、Protocol-First 节奏 |
| **L1** | [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) | ✅ 复用闸门 | PO + 实现者 | 旧仓快照只读考古政策与 L01–L12 勾选 |
| **L2** | [`ROADMAP.md`](ROADMAP.md) | ✅ 里程碑 | PO | M0–M2 路线图、唯一 `Slice 1–8`、Spike/UX/上架门 |
| **L2** | [`STAGE0_CHARTER.md`](STAGE0_CHARTER.md) | ✅ 阶段 0 | PO + 轨道 B | 单题 Hold-out 验证标准与 A/B/C 裁决 |
| **L2** | [`STAGE0_SAMPLES.md`](STAGE0_SAMPLES.md) | ✅ 样张台账 | PO + 轨道 B | 样张缺口看板与单题裁剪计数 |
| **L2** | [`STAGE0_COLLECTION.md`](STAGE0_COLLECTION.md) | ✅ 收集规范 | PO | 拍卷指南、EXIF 剥离与未成年人合规 |
| **L3** | [`ENGINEERING.md`](ENGINEERING.md) | ✅ 进度实态 | 实现者 | 构建说明、`PrivacyInfo.xcprivacy`、基线设备、当前进度 |
| **L4** | [`.github/pull_request_template.md`](../.github/pull_request_template.md) | 模板真源 | 实现者 | 合并门禁 Checklist（唯一真源） |
| **L4** | [`PR_TEMPLATE.md`](PR_TEMPLATE.md) | 指引指针 | 实现者 | 指向 `.github/pull_request_template.md` 的说明 |
| **L5** | [`PR_SCOPE_ESTIMATE.md`](PR_SCOPE_ESTIMATE.md) | ❌ 粗估 | PO | PR 数量级参考，不作强约束 |
| **L5** | [`archive/`](archive/) 下文件 | ❌ 只读归档 | — | 已失效历史快照，严禁当现行合同或技术选型依据 |
| **L6** | [`.agents/rules/snapdrill-ios26-standards.md`](../.agents/rules/snapdrill-ios26-standards.md) 等环境规范 | ❌ 工具链补充 | 实现者 | **仅 CI / 本地工具链补充，不定义产品；文档盲审与合规审计以 L0–L5 为完整封闭真源**（变更须同步 L1） |
| — | [`../README.md`](../README.md)、[`Samples/stage0/README.md`](../Samples/stage0/README.md) | 入口说明 | — | 仓库与样张目录导航，不重复规格 |

**文档总数红线**：`Docs/` 现行核心文档维持当前 **12 篇 + `archive/` 2 篇**；**禁止** Agent 未经 PO 点名新建 `Docs/*.md`（如确需新增须走专门 docs PR 说明必要性与层级）。

### 3.1 文档分级依赖盲审协议（4-Tier DAG Audit）

按高内聚、低耦合原则与 §1 权威依赖链，全仓文档的冻结前独立评审拆分为 **4 个职责正交的分级域**，由上游向下游分波执行，并辅以自动化跨层脚本校验引用与算术闭环：

| 分级域 | 波次 | 只读上游真源 | 本域主审文档 | 评审聚焦 |
|---|---|---|---|---|
| **Tier 1（产品与治理）** | Wave 1 | — | [`PRD.md`](PRD.md)、[`GOVERNANCE.md`](GOVERNANCE.md) | 交互状态机、边界异常、AC-01~10、合规与治理权威链 |
| **Tier 2（架构与纪律）** | Wave 1 | `PRD.md`、`GOVERNANCE.md` | [`ARCHITECTURE.md`](ARCHITECTURE.md)、[`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md)、[`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) | Schema/`CKSyncEngine` 可行性、`*Serving` 合同边界、Swift 6 并发与 Legacy 闸门 |
| **Tier 3（门禁与路线）** | Wave 2 | `PRD.md`、`ARCHITECTURE.md` | [`STAGE0_CHARTER.md`](STAGE0_CHARTER.md)、[`ROADMAP.md`](ROADMAP.md)、[`STAGE0_COLLECTION.md`](STAGE0_COLLECTION.md)、[`STAGE0_SAMPLES.md`](STAGE0_SAMPLES.md) | 阶段 0 Q1/Q2/Q3 数学无落空、Hold-out 样本纪律、`Slice 1–8` 与 `M-freeze` 合一表 |
| **Tier 4（工程与模板）** | Wave 2 | `PRD.md`、`GOVERNANCE.md`、`ARCHITECTURE.md`、`ROADMAP.md` | [`ENGINEERING.md`](ENGINEERING.md)、[`PR_TEMPLATE.md`](PR_TEMPLATE.md)、[`.github/pull_request_template.md`](../.github/pull_request_template.md)、[`PR_SCOPE_ESTIMATE.md`](PR_SCOPE_ESTIMATE.md)、[`archive/*`](archive/) | Privacy Manifest/法务清单、PR 检查红线自包含、PR 算术、归档只读隔离 |

---

## 4. 维护规则（防文档爆炸与跨文档漂移）

| 想更新什么 | 写哪里 | 禁止 |
|---|---|---|
| 产品行为 / 交互 / AC | [`PRD.md`](PRD.md) | 第二份 PRODUCT 或独立 UX 影稿 |
| 架构决策 / UX 冻结签收 / Spike 结论 | [`ARCHITECTURE.md`](ARCHITECTURE.md) §8 一行 | 散落 ADR 森林或另建独立 UX 文件 |
| Slice 完成态、编译、设备实态 | [`ENGINEERING.md`](ENGINEERING.md) | README 长篇进度或反向覆盖 PRD |
| 里程碑灯、Slice 顺序、PO 会议项 | [`ROADMAP.md`](ROADMAP.md) | 复制 ENGINEERING 状态表 |
| 拣 legacy 政策 / L01–L12 勾选 | [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) | 口头同意 merge `develop` |
| PR 检查项更新 | [`.github/pull_request_template.md`](../.github/pull_request_template.md) | 两份模板各自修改造成漂移 |
| 治理地图、裁决顺序或 L6 同步 | **本文** [`GOVERNANCE.md`](GOVERNANCE.md) | 另开 `AGENT_RULES.md` 并行总则 |

**归档隔离说明**：过时的一次性交接（过夜授权、当次 handoff）已移入 [`Docs/archive/`](archive/)。`archive/` 中记录的早期过渡命名与选型（如旧 `LibrarySaveService`、`MistakeImageStore`、`UIImagePicker`/系统扫描器等）均已由现行 `ARCHITECTURE.md`（`LibraryServing`、`@Attribute(.externalStorage)`、`AVFoundation` 预览桥接）取代，**严禁作为开工或重构依据**。

---

## 5. Agent 开工检查（30 秒）

- [ ] 已读 [`PRD.md`](PRD.md) 相关节 + [`ARCHITECTURE.md`](ARCHITECTURE.md) 对应 § + [`ENGINEERING.md`](ENGINEERING.md) 当前 Slice
- [ ] 已核对本文 §2：不把演示草稿擅自扩成正式产品；改交互先改 PRD/经 PO 签收
- [ ] 使用仓库唯一 PR 模板 [`.github/pull_request_template.md`](../.github/pull_request_template.md)；**一 PR 一边界**
- [ ] 不新建 `Docs/*.md`；代码 PR 不擅自涂改冻结文档与 `Samples/`；严禁参考 `Docs/archive/` 内已失效技术方案开工
- [ ] Legacy 代码仅允许拣 [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) 已标 `[x] 要` 的 L0x（或 PO 在本 PR 书面批准例外）
- [ ] 不新增硬编码 UI 文案（P10）；动到合同同步改单元测试；不提交 `Samples/stage0/raw/` 或密钥

---

## 6. 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-18 | 首版：文档地图 + PO UX 收权 + 防文档爆炸规则 |
| 2026-11-27 | 盲审闭环：补全 L0–L5 完整裁决矩阵与领域优先序；废除原规划占位 UX 影稿与未定义术语，确立唯一 UX 签收载体；统一 PRD 版本指针铁律与 PR 模板单一真源规则 |
| 2026-11-27 | 冻结前复审闭环：明确 L6 `.agents/rules/snapdrill-ios26-standards.md` 同步机制；显式标定 `Docs/archive/` 内旧命名/技术选型已失效，严禁作开工依据 |
| 2026-11-27 | 固化 §3.1「4-Tier DAG 分级依赖盲审协议」，按高内聚低耦合职责链分波审阅文档体系 |
| 2026-11-27 | 收口 §1 树形图排版与 §2 规则 #2，取消双重交互授权歧义（所有可见交互改动必须先改 `PRD.md`） |
