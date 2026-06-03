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
| `2026-06-03-architecture-r4-terminal-verification.md` | R4 产出 | 终端实证回答 GUI 问题 + **双向纠错**（grep 抓到 GUI 两处事实幻觉：0 个 @Query / 组卷 to-many 风险错挂） |
| `2026-06-03-architecture-r5-prompt.md` | R5 输入 | 终端把 R4 实证喂回 GUI 求最终收敛 |
| `2026-06-03-architecture-r5-gui-convergence.md` | R5 产出 | GUI 最终收敛：3 分歧终态 + **自审系统性偏差**（缺事实时用先验众数冒充观测值）+ 双向纠错全接受 |

> R2 为终端实证轮次（结论在私有记忆）。研究弧基本收敛（4 分歧全有终态）。

### 其他 SnapDrill 相关 GUI 研究
| 文件 | 主题 |
|---|---|
| `gui-optimal-decoupling-framework.md` | "什么是最优解耦"——资深架构师判断框架（关联 architecture.md 解耦准则） |
| `gui-snapdrill-metagovernance-assessment.md` | SnapDrill 元治理体系完备性评估 |
| `gui-snapdrill-china-data-compliance-review.md` | SnapDrill 中国数据合规专业复核 |

## 收敛状态（截至 R5，研究弧基本收敛）

- **7 强收敛（R2 认定）**：每孩子独立 store 物理隔离 / CloudKit 预约束建模 / 并发三分 / 避免 per-view VM / SwiftData to-many tag 弱点 / protocol 克制 / 测试聚焦纯逻辑。
- **4 分歧终态（R5 收敛）**：
  - **分歧1 模块化**：4 真编译边界（含"第三方依赖封装"这类 GUI 曾漏算的收益）= 认定非审美；第 5 包 Infrastructure = speculative 死占位（去污染：摘 link 降 git/纸面+ADR）。
  - **分歧2 Repository**：数据 actor 认定不变；@Query 支腿剔除（GUI 事实幻觉）；Repository 7→2（ReviewRepository 保留 + TaxonomyRepository 合并 4 份）。
  - **分歧3 组卷**：撤回复杂度指控（SmartPaper 已极简）；to-many 风险归因修正到 Library；价值链文档矛盾保留为产品判断。
  - **分歧4 采集**：数据丢失真 gap（OCR 优先 + 内存暂存 + Caches 半持久），GUI 称风险量级最高，待修。
- **方法论元产出**：对称双向纠错（R3 GUI 用 Apple DTS 纠终端污染 / R4 终端用 grep 纠 GUI 幻觉）+ GUI 自审系统性偏差（缺事实时用先验众数冒充观测值）。基线 = 「无污染推导」∩「代码实证」。
- **待 PO 定（商业/产品判断）**：TaxonomyRepository 同构粒度 / 海外版确定性等级 / GRDB 撤回 / 复习是否产品核心。
