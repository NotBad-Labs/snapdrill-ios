# SnapDrill · 文档治理与 PO 收权（greenfield）

> **给谁看**：PO、所有 Agent。  
> **目的**：控制文档数量与权威漂移；明确 **UI/UX 与产品裁决归 PO**；避免 Agent 把草稿壳当成已定产品。  
> **一页地图**：下文即全仓 Markdown 分层；细节仍读各专文，**不在此重复 PRD 正文**。

---

## 1. 权威顺序（争议时）

与 [`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md) 一致：

```text
PRD.md（做什么）
  → ARCHITECTURE.md（怎么拆、合同）
  → DEVELOPMENT_PRINCIPLES.md（怎么做事）
  → ENGINEERING.md（做到哪了）
  → 代码
```

| 类型 | 权威来源 | 禁止 |
|---|---|---|
| 产品行为、AC | **仅** [`PRD.md`](PRD.md) | 在 Feature 里「偷偷改规则」 |
| 模块边界、接口 | [`ARCHITECTURE.md`](ARCHITECTURE.md) §4.3、§8 | 跨层直连、UI 绑 Vision/相机 |
| 进度、Slice 状态 | [`ENGINEERING.md`](ENGINEERING.md) | 在 README 堆长进度叙事 |
| Legacy 能否拣代码 | [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) + PO 勾选 | 未勾选「要」前拣 develop |

**PRD 版本**：以 `PRD.md` **文内版本表**为准（当前 **v0.9 草案**）；其他文档只写「见 PRD 当前版」，不各写各的 v0.8。

---

## 2. PO 收权 · UI / UX

| 状态 | 含义 |
|---|---|
| **已定产品** | 仅 PRD §8 等 **PO 已写入 PRD** 的交互与边界 |
| **Agent 草稿** | 方案 A 演示壳、`UIDemoDataService` 假数据、未合并 PR 中的布局/文案 |
| **PO 未签 UX** | 在 PO 书面 **「UX 冻住」**（见规划中的 `UX_SHELL.md` 或 PO 会议纪要）之前，**草稿可演示，不可视为产品承诺** |

**Agent 硬规则：**

1. **不得**把草稿壳的布局、Tab 结构、主路径顺序当成 PRD 已批准而擅自扩大。  
2. 改 **可见交互默认值**（非 bugfix）：先 **PRD 或 PO 书面确认**，再代码 PR。  
3. 在 PO 未签 UX 前，补 UI 时 **优先**：PRD 条文 →（若 PO 批准拣零件）legacy 快照参考 → 新实现；**少**纯 Agent 审美即兴。  
4. 合并后的 `UX_SHELL.md`（若有）标明 **草稿**；与本文冲突时以 **PRD + 本文** 为准。

---

## 3. 文档分层地图（全仓 Markdown）

| 层级 | 文档 | 权威？ | 维护者 |
|---|---|:---:|---|
| **L0** | [`PRD.md`](PRD.md) | ✅ 产品唯一 | PO |
| **L1** | [`ARCHITECTURE.md`](ARCHITECTURE.md)、[`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md)、[`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md)、**本文** | ✅ 结构与流程 | PO + 技术负责人 |
| **L2** | [`ROADMAP.md`](ROADMAP.md)、[`STAGE0_CHARTER.md`](STAGE0_CHARTER.md)、[`STAGE0_SAMPLES.md`](STAGE0_SAMPLES.md)、[`STAGE0_COLLECTION.md`](STAGE0_COLLECTION.md) | ✅ 里程碑 / 阶段 0 | PO |
| **L3** | [`ENGINEERING.md`](ENGINEERING.md) | ✅ 工程进度 | 实现者 |
| **L4** | [`PR_TEMPLATE.md`](PR_TEMPLATE.md)、[`.github/pull_request_template.md`](../.github/pull_request_template.md) | 模板 | 实现者 |
| **L5** | [`PR_SCOPE_ESTIMATE.md`](PR_SCOPE_ESTIMATE.md) | ❌ 粗估 | 参考用，不作为拍板依据 |
| **L5** | [`archive/`](archive/) 下文件 | ❌ 历史快照 | 只读归档，**不得**当现行指令 |
| **L6** | 根目录 `CLAUDE.md`、[`.github/copilot-instructions.md`](../.github/copilot-instructions.md) | ❌ | 仅引导 Agent 读 L0–L3，**不定义产品** |
| — | `README.md` | 入口索引 | 链接 L0–L3，**不重复**长规格 |
| — | `Samples/stage0/README.md` | 样张目录说明 | 轨道 B |

**文档总数（刻意控制）**：`Docs/` 核心约 **12–14 篇** + 模板 + 归档；**禁止** Agent 未经 PO 点名新建 `Docs/*.md`（须 **docs PR** 说明必要性与层级）。

---

## 4. 维护规则（防爆炸）

| 想更新什么 | 写哪里 | 不要 |
|---|---|---|
| 产品 / AC | `PRD.md` | 第二份 PRODUCT 影稿 |
| 架构决策 | `ARCHITECTURE.md` §8 一行 | 散落 ADR 森林 |
| Slice、编译、真机须知 | `ENGINEERING.md` | README 长篇进度 |
| 里程碑灯、PO 会议项 | `ROADMAP.md` | 复制 ENGINEERING 表 |
| 拣 legacy 政策 / L0x 勾选 | `LEGACY_PARTS_INVENTORY.md` | 在聊天里口头「可以 merge develop」 |
| 收权 / 文档地图变更 | **本文** | 再开 `AGENT_RULES.md` 等并行总则 |

**过时的一次性交接**（过夜授权、当次 handoff）→ 移入 [`Docs/archive/`](archive/) 或删除，**不得**留在 `Docs/` 根目录冒充现行任务。

---

## 5. Agent 开工检查（30 秒）

- [ ] 读过 **PRD 相关节** + **ARCHITECTURE 对应 §** + **ENGINEERING 当前 Slice**  
- [ ] 读过 **本文 §2**（UX 草稿未签）  
- [ ] 任务 PR 用 [`PR_TEMPLATE.md`](PR_TEMPLATE.md)；**一 PR 一边界**
- [ ] 不新建 Docs，除非本 PR 就是 docs 且 PO 同意  
- [ ] Legacy 拣入：L0x 已勾选「要」或 PO 在本 PR 书面批准  

---

## 6. 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-18 | 首版：方案 A · 文档地图 + PO UX 收权 + 防文档爆炸规则 |