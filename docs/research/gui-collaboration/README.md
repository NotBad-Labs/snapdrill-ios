# GUI 协作研究归档（认知基线的起点材料）

> **定位**：本目录留底"终端 Claude（有仓库上下文）× GUI Opus 4.8（无仓库上下文 = 无污染）"对抗式认知校准的原始研究产出。
> **它不是结论、是起点**：认知基线 = 「无污染推导」∩「代码实证」对抗后还站着的部分，随后续轮次持续构建、写入私有记忆。
> 收敛结论与裁决进度见私有记忆 `project_architecture_first_principles_gui_research`。

## 方法论（PO 设计）

GUI 看不见本地仓库 → 从客观问题域用第一性原理**独立推导**最优架构 → 对照 SnapDrill 实际 → 找"想法污染"（流行但无据 / cargo cult / 单源自我强化）。多轮：GUI 独立推导（无污染）↔ 终端实证证伪（看得见代码），谁也不污染谁。prompt 严守无污染（给客观问题域、不泄露架构决策）。

## 文件清单

### 架构第一性原理研究弧（2026-06-03，进行中）
| 文件 | 轮次 | 内容 |
|---|---|---|
| `round1-execute-prompt.md` | R1 输入 | 终端写给 GUI 的第 1 轮 prompt（无污染问题域 + 第一性原理问题序列） |
| `2026-06-03-architecture-r1-gui-derivation.md` | R1 产出 | GUI 零上下文独立推导最优架构 |
| `2026-06-03-architecture-r3-gui-adjudication.md` | R3 产出 | GUI 对 4 处分歧的污染裁决 + 元观察"对的决策被错的理由包裹" |

> R2/R4 为终端实证轮次，结论在私有记忆（非 GUI 产出，不在本目录）。

### 其他 SnapDrill 相关 GUI 研究
| 文件 | 主题 |
|---|---|
| `gui-optimal-decoupling-framework.md` | "什么是最优解耦"——资深架构师判断框架（关联 architecture.md 解耦准则） |
| `gui-snapdrill-metagovernance-assessment.md` | SnapDrill 元治理体系完备性评估 |
| `gui-snapdrill-china-data-compliance-review.md` | SnapDrill 中国数据合规专业复核 |

## 当前收敛状态（截至 R4）

- **7 强收敛（认定）**：每孩子独立 store 物理隔离 / CloudKit 预约束建模 / 并发三分 / 避免 per-view VM / SwiftData to-many tag 弱点 / protocol 克制 / 测试聚焦纯逻辑。
- **4 分歧（裁决中）**：模块化(5 SPM 包) / Repository / 复习组卷权重 / 采集可靠性。其中**分歧 4 实证确认数据丢失真 gap**（OCR 优先，B/SRP 审计盲区）。
