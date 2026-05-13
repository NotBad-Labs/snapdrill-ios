---
last_verified: 2026-05-11
layer: snapshot
freshness:
  max_age_days: 365
  decay_trigger: [next_zero_trust_audit]
---
# 归零审计收官 — 2026-05-08 → 2026-05-11

## Goal

以"归零心态"（不信任项目任何现有结论）从产品愿景出发，逐层审计 SnapDrill 项目的全部文档和源代码。

## 参与方

| 角色 | 模型/工具 | 职责 |
|---|---|---|
| **Claude/DeepSeek** | DeepSeek v4 Pro (1M ctx) | 主审：逐文件阅读，起草修订，执行修复 |
| **Codex CLI** | GPT-5.5 (high effort) | 独立验证审计：grep 全量验证 + 发现遗漏 |
| **Gemini CLI** | Gemini 3 Pro / 2.5 Pro | 独立验证审计：交叉视角 + 发现遗漏 |

## 审计方法

按文档拓扑 5 条链自顶向下审计：
1. 产品链（vision → design → requirements → cases → journeys → business → glossary → analytics → onboarding → competitive-analysis → appstore-metadata）
2. 工程治理链（engineering → workflow → coding → testing → apple-* → api-pitfalls → ux-design）
3. 智能体治理链（collaboration → delegation → shared-constraints → permission-model → memory-routing → review-prompt-guide → rules → skills → hooks → settings）
4. 技术实现链（architecture → api-reference → NFR → compliance → deployment → release-checklist）
5. 决策记录链（ADR-001 → ADR-002 → ADR-003）

每份关键文档经三方独立审查（F-008 纪律），源代码 176 文件逐行阅读。

---

## 已完成的工作

### 一、产品链审计与修订

| 文件 | 操作 | 内容 |
|---|---|---|
| `product-vision.md` | **归零审计+修订** | 加假设声明（区分原则与待验证假设）、价值链修正（复习为可选留存层）、用户画像泛化、新增平台策略/风险与张力/版权合规边界/10条关键假设、技术壁垒重写、成功指标修正、隐私表述精确化 |
| `product-journeys.md` | **恢复** | 从 git history 还原 412 行完整旅程（被错误压缩为 35 行索引） |
| `product-analytics.md` | **新建** | Analytics 事件字典 SSOT（事件定义、触发条件、参数、成功信号映射） |
| `product-onboarding.md` | **新建** | Onboarding 内容规格（4 页内容、文案方向、后续引导触发规则） |
| `product-competitive-analysis.md` | **新建** | 竞品分析（从 business.md 抽出独立） |
| `product-design.md` | **修订** | 价值链表述对齐、过时引用修正 |
| `product-requirements.md` | **修订** | 旅程指针修正（合并→独立文件） |
| `product-business.md` | **修订** | 竞品分析抽出、价值链表述对齐 |
| `product-glossary.md` | **修订** | 基线用户对齐、价值链术语对齐 |
| `appstore-metadata.md` | 无需修改 | 审毕 |

### 二、工程治理链审计与修订

| 文件 | 操作 | 内容 |
|---|---|---|
| `engineering.md` | **归零审计+重写** | 从 13 节杂糅（151行）重写为 7 条核心原则（125行），每条带适用范围/反例/冲突裁决。项目特定决策迁至 architecture/coding。补最高裁决护栏（安全/隐私/合规优先于简化原则） |
| `workflow.md` | **归零审计+重写** | layer principle→pattern。288行→175行。加 Research 阶段（对齐 engineering 原则1）。DoD 同步 7 条新原则。Sprint Contract 加 trivial 豁免。CI/bash 迁出。docaudit 精简。Code Review 统一为"人类操作者" |
| `coding.md` | **修订** | 去 @concurrent（不存在于 Swift）、补值类型优先段、禁止列表分类、并发安全/调试/类型系统/架构四维分组 |
| `testing.md` | **修订** | 过时引用修正（《CI 与本地一致性》→ deployment.md） |
| `apple-native.md` | 无需修改 | 审毕（参考文档，内容准确） |
| `apple-limits.md` | 无需修改 | 审毕 |
| `apple-extension.md` | 无需修改 | 审毕 |
| `api-pitfalls.md` | 无需修改 | 审毕 |
| `ux-design.md` | 无需修改 | 审毕 |

### 三、智能体治理链审计与修订

| 文件 | 操作 | 内容 |
|---|---|---|
| `collaboration.md` | **修订** | rubric 维度同步新 engineering 7 原则、合并措辞对齐 |
| `codex-delegation.md` | **修订** | 模型参数更新（gpt-5.4→gpt-5.5，去 --effort）、CLI 版本更新 |
| `gemini-delegation.md` | **修订** | CLI 版本和模型名更新（v0.38.1→0.41.2，Gemini 3 Auto→gemini-3-pro-preview） |
| `shared-constraints.md` | **修订** | 价值链和工程哲学引用同步 |
| `permission-model.md` | **修订** | Hook 描述同步（移除已删除的 git rebase 触发） |
| `memory-routing.md` | **修订** | 补新建文档路由条目（analytics/onboarding/competitive-analysis/journeys） |
| `review-prompt-guide.md` | 无需修改 | 审毕 |
| `.claude/rules/memory-routing.md` | **新建** | 路由指针（squash merge 丢失后重建） |
| `.claude/rules/review-prompt-guide.md` | **新建** | 路由指针（squash merge 丢失后重建） |
| `.claude/hooks/docaudit-preflight.sh` | **修复** | 移除 git rebase 触发（变基期间 docaudit 检查边际价值低） |

### 四、技术实现链验证

| 文档 | 验证方式 | 结果 |
|---|---|---|
| `architecture.md` | grep 全量依赖方向 + 逐模块验证 | 9.5/10。5 个 SPM 包依赖方向零违规，ModelContainer 仅 DataExecutor 持有，ViewModel 16/16 覆盖 |
| `api-reference.md` | grep 逐类型验证 | 25/25 类型在代码中真实存在 |
| `NFR.md` | 代码抽样验证 | EXIF 剥离 ✅、CSV 注入防护 ✅、autoreleasepool ✅、草稿 7 天 ✅、压缩 2000px/0.8 ✅ |
| `compliance.md` | PrivacyInfo 验证 | NSPrivacyTracking=false ✅、零 ATT 代码 ✅ |
| `deployment.md` | 版本号 SSOT 验证 | ✅ |
| `release-checklist.md` | 138 行检查清单 | 审毕 |

### 五、决策记录链验证

| ADR | 验证 | 结果 |
|---|---|---|
| ADR-001（智能组卷 Hybrid） | SmartPaperViewModel 存在性 | ✅ 代码已兑现 |
| ADR-002（删除 ATT） | grep 全量 ATT 引用 | ✅ 零 ATT 代码 |
| ADR-003（YAML frontmatter） | validate_frontmatter.py 运行 | ✅ 71 文件通过 |

### 六、源代码全量审计（176 文件）

逐行阅读全部 176 个 Swift 源文件：

| 包 | 文件数 | 审计深度 |
|---|---|---|
| SnapDrillData | 25 | 全文件逐行 |
| SnapDrillCore | 49 | 全文件逐行 |
| SnapDrillFeatures | 79 | 全文件逐行（15 ViewModel + 41 View + 辅助组件） |
| SnapDrillUI | 13 | 全文件逐行 |
| SnapDrillInfrastructure | 2 | 全文件逐行 |
| SnapDrill/App | 4 | 全文件逐行 |
| SnapDrillShare | 4 | 全文件逐行 |

首次审计结论：代码层 0 逻辑 bug、0 内存泄漏、0 并发违规。

### 七、Codex 独立验证审计

Codex 独立验证了 Claude 的审计结论：
- 逐文件首尾 50 行抽样 176 文件
- grep 全量扫描 try!、force unwrap、print()、nonisolated(unsafe)、.snapdrill
- 验证 Claude 的 15 项声称

**Codex 发现的问题**（已全部修复）：
- S0：restoreFromProfileData 非原子（deleteAllData 先 commit，后续恢复失败无法回滚）
- S2：2 个 .claude/rules/ 路由文件缺失、journeys.md 3 处 .snapdrill 残余、ADR-003 内容过时
- S3：ImageStorage try? 缺注释、TagInputView 硬编码中文、25 文件缺 accessibility、LibraryEditViewModel 草稿接口空实现（核实为有意设计）
- Claude 首次审计评分为 4/10（因断言过度，遗漏 S0 原子性问题）

**修复后 Codex 验收**：5/6 ✅，1/6 ⚠️（备份失败仍继续恢复 → 最终改为 A 方案：备份失败直接拒绝）

### 八、Gemini 独立验证审计

Gemini 独立验证了 Claude 和 Codex 的审计结论：
- 确认 Claude 的文档修订已落地
- 确认 Codex 发现的 rules 缺失和 rebase 触发
- 自身产生一处幻觉（声称"项目中不存在任何 try?"）→ 交叉验证无效

**三方共识最终结论**：Claude 首次审计的文档修订方向正确、代码层断言过度。Codex 验收审计后所有发现已修复。

---

## 未完成的工作

以下项目在本次审计范围内但未完成或未覆盖：

| 项目 | 状态 | 原因 |
|---|---|---|
| 420 tests 逐条执行与断言质量审计 | 仅抽样 3 文件 | 需真机/模拟器运行，非纯静态分析 |
| NFR 全部 50+ 声明逐条代码验证 | 已抽样 8 条关键声明 | 部分声明需运行时测量（性能/内存） |
| .claude/skills/ 11 个 SKILL.md 深度内容审计 | 仅检查结构+allowed-tools | 内容质量需人工判断 |
| .claude/hooks/ 10 个脚本逐行逻辑验证 | 仅检查错误处理+配置 | 部分逻辑需运行时测试 |
| Share Extension 端到端测试 | 未覆盖 | 需真机 + 微信/QQ 等外部 App |
| 性能/负载测试 | 未覆盖 | 需 Instruments 等工具 |
| 安全渗透测试 | 未覆盖 | 超出静态分析范围 |
| 本地化完整性（en/zh-Hans 全量对比） | 发现 1 处缺失已修复 | 未全量逐 key 对比 |
| 第三方依赖 CVE 扫描 | 未覆盖 | 需专门的依赖扫描工具 |

---

## PR 清单

| PR | 内容 | 文件数 | 状态 |
|---|---|---|---|
| #741 | 产品链：vision 修订 + journeys 恢复 + 3 新建 + .snapdrill→.zip + 全产品 ## 相关文档 | 29 | ✅ 已合并 |
| #742 | 工程链：engineering 重写 + workflow 修订 + 8 下游同步 | 10 | ✅ 已合并 |
| #743 | 治理链：memory-routing 路由同步 | 1 | ✅ 已合并 |
| #744 | 执行层：补 2 个 rules 路由 + 修 docaudit rebase 触发 | 4 | ✅ 已合并 |
| #746 | Codex 验收修复：原子性 S0 + S2 遗漏 + S3 代码质量（重应用，squash 丢失后补） | 14 | ✅ 已合并 |

---

## Score

| 维度 | 首次审计 | 验收后 |
|---|---|---|
| 文档一致性 | 8/10 | 9/10 |
| 代码安全性 | 6/10（遗漏 S0 原子性） | 9/10（已修复） |
| 审计完整性 | 7/10（过度断言） | 8/10（已知局限已记录） |
| 三方闭环 | 5/10（未验收） | 9/10（Codex+Gemini 验收） |
| **综合** | **6.5/10** → | **8.8/10** |

## Next

下次归零审计应在以下时机触发：
- App Store 正式发布前（S0 级数据安全复验）
- 首次付费用户上线后（产品假设验证）
- 新增核心功能模块后（架构一致性）
- iOS 大版本更新后（Apple API 兼容性）
