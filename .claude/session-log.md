# SnapDrill 工作日志

> 每次对话结束时追加一条记录。新对话读取最近 3-5 条恢复上下文。
>
> **与其他持久化机制的分工**：
> - `STATUS.md`：当前状态快照（什么在进行中、下一步是什么）
> - `session-log.md`：工作历史（每次对话做了什么、为什么、学到了什么）
> - `memory/`：行为规则（怎么协作、什么该做什么不该做）
> - PR/Issue：单个改动的具体内容

---

## 2026-03-19 Session

### 完成

**线 A 产品技术债全部清零（10/10）**：
- PR #353：Flaky tests 修复（草稿条件不同步 + waitUntil 竞态）
- PR #354：CSV Excel 公式注入防护（OWASP tab 前缀）
- PR #355：AccessibilityHelper 硬编码中文迁移到 L10n
- PR #357：4 个跨包协议补齐 DocC 行为保证
- PR #358：L10n.Common onboarding 键迁移到 L10n.Onboarding
- PR #359：移除 Markdown 导出（图片内容导出后引用断裂）
- PR #360：移除 App 内帮助系统 -511 行（改为外部网页 FAQ）
- #285/#286/#264：审查后关闭（已在之前 PR 中修复或确认保留）

**线 B 工程体系全部清零（5/5）**：
- PR #350：第 4 条元原则 + PR 全流程纪律正式化
- PR #351：测试策略原则（分层 TDD，横向研究 Beck/DHH/Fowler/Hickey/Google）
- PR #352：文档治理体系（全量审计 ~40 文件 + Last verified + ADR 实施状态）
- PR #362：Skills 体系改进（2 新 Skill + 16 个 Gotchas）
- #329：研究沉淀并入 #328，关闭

**STATUS.md 重构**：从"发布驱动"改为"双线并行"结构

### 关键决策

- **测试策略**：不全面 TDD，分层施策（纯算法 TDD / ViewModel test-after / View 不测）
- **文档治理**：活文档加 Last verified，ADR 不加（快照哲学），事件驱动审计
- **Markdown 导出移除**：SnapDrill 内容是图片密集错题，MD 导出后图片引用断裂，对家长/学生无价值
- **HelpView 移除**：8 个对标 App 中 7 个用外部网页 FAQ，Apple HIG 推荐 TipKit 不推荐集中式 FAQ
- **战略目标澄清**：木桶原则——不追求某块板特别长，确保没有明显短板。发布是质量达标后的自然结果

### 教训（已写入 memory）

- PR 合并后必须立即更新 STATUS.md（事件驱动，不问用户）
- PR 创建后自动后台轮询 review（不需要用户下命令）
- STATUS.md 不能只留在本地未提交——git checkout 会覆盖

### 横向研究

- TDD/Interface-First：Beck/DHH/Fowler/Hickey/Google + 外部专家咨询
- 文档治理：Google g3doc / GitLab SSOT / Nygard ADR / AWS ADR lifecycle
- 帮助系统：Bear/Things 3/Day One/GoodNotes/Anki/Apple HIG
- 导出格式：Bear 12 格式 / Anki / Day One / Apple Notes iOS 26 Markdown

### 下次接续

- 线 A + 线 B 全部清零，无待处理 Issue
- 下一步：审视项目整体，找短板（木桶原则），而非急着推发布
- 外部阻塞：#161 Build 6 / #162 GitHub Pro / #163 公司开发者账号

---

## 2026-03-18 Session（第三次）

### 完成

- **#304 产品终审 3 个决策落地**：Onboarding 字段选择延后（Apple HIG）、帮助中心降级为外部网页、卡片外观保留独立字号去掉对齐。`product-requirements.md` 已更新
- **#306 安全 + #309 UX 三方审计**：Claude 初审 → 贴 GitHub → 外部独立审计 → 三方汇总。发现显著盲区（Claude 遗漏 VoiceOver 零覆盖、复习加载无恢复）
- **多方独立审计铁律**沉淀到 `workflow.md` + `memory/`（横看成岭侧成峰）
- **#305 第三轮终审**（四帽并行）：#308 QA（2×S0）、#307 用户代言人（6×S2 文案）、#310 性能（2×❌ 阻断）、#311 数据分析（14 事件仅 1 调用）
- **Anthropic Skills 最佳实践研究**：发现方向性差距（9 大类 vs 我们 1 类角色检查清单）
- **TRAE 企业级手册研究**：确认我们已覆盖五大支柱，多维度超越
- **PR #336 合并**（S0 修复）：编辑保存反馈 + 草稿条件放宽 + 双击防护。外部 review 发现运算符优先级真实 bug 并修复
- **新建 19 个 Issue**（#317-#335）

### 关键决策

- **方案 C**：全部终审完 → 统一修复（发现问题和修复分阶段）
- **多方审计铁律**：安全/UX 审计必须三方独立（Claude + Antigravity + Xcode Intelligence）
- **Skills 改进方向**：保留角色 Skills，新增工程实用 Skills

### 下次接续

- **S1 修复**：#317 EXIF GPS → #321 复习加载 → #332 图片同步+PDF OOM
- S1 完成后进入 S2（13 个）
- Skills 改进（#328）排在修复之后

---

## 2026-03-18 Session（第一次）

### 完成

- **Pre-#287 Issue 审计**：关闭 #259/#263/#269，拆分 #261→#297，更新 #260，保留 #264
- **PR #289 合并**：全球市场策略 + STATUS.md 看板首次入库
- **PR #299 合并**（S1 本地化清零）：6 个 issue 一次性解决，533 键 100% 中英对称，HelpView/OnboardingView/法律文档全部迁移到 L10n，修正 iCloud/Freemium 措辞
- **PR #303 合并**（S2 隐私修复）：crashReportingEnabled dead toggle，经三轮 review 迭代——首启默认值修复、运行时同步、优先级反转（用户 > 远程 > 默认）、Analytics 同步补全
- **#305 伞 issue 建立**：v1.0 发布前全链路终审，7 个子 issue（#304 产品经理 / #306 安全 / #307 用户代言人 / #308 QA / #309 UX / #310 性能 / #311 数据分析）
- **STATUS.md 三次重构**：从扁平列表升级为伞形结构，明确为项目记忆备份职能

### 关键决策

- **Analytics + Crashlytics 默认开启 + 单一开关**（用户确认，行业标准做法）
- **隐私优先级设计**：用户本地设置 > 远程配置 > 产品默认值。隐私选择是用户绝对权利，远程配置不得覆盖
- **不返工 #287**：技术审计（#287 纵向）和产品审计（#305 横向）是并行的两条线，不是上下游依赖
- **全链路终审执行顺序**：第一轮 #304 产品经理（先稳定需求）→ 第二轮 #306 安全 + #309 UX（并行）→ 第三轮 #308 QA + #307 用户代言人 + #310 性能 + #311 数据（并行）

### 教训（已写入 memory）

- **PR 创建后必须走完 review 再推进下一任务**——曾试图跳过 review 直接推进 #288
- **持续关注 STATUS.md**——每次对话开头读、每个 PR 合并后更新
- **PR #289 滞留导致失忆**——看板未入库 = 每次新对话都丢失项目状态

### 新建 Issue

| Issue | 内容 |
|---|---|
| #297 | InfoPlist.strings 英文隐私权限（从 #261 拆分） |
| #300 | L10n.Common onboarding 键迁移（review 发现） |
| #301 | export_markdown 无产品支撑的键清理（review 发现） |
| #304 | v1.0 产品经理终审 |
| #305 | v1.0 全链路终审伞 issue |
| #306 | 安全工程师终审 |
| #307 | 用户代言人终审 |
| #308 | QA 工程师终审 |
| #309 | UX 设计师终审 |
| #310 | 性能工程师终审 |
| #311 | 数据分析师终审 |

### 下次接续

- **#305 第一轮**：#304 产品经理终审（逐条审视 product-requirements.md）
- **#260** 无障碍 VoiceOver + Dynamic Type（S2，待做）
- **PR #303 re-review 的 🟡**：didChangeNotification 精细化（S3，不急）

---

## 2026-03-18 Session（续）

### 完成

- **PR #303 三轮 review 完成并合并**：crashReportingEnabled dead toggle 修复，隐私优先级设计（用户 > 远程 > 默认）
- **#305 伞 issue 建立**：7 个子 issue（#304-#311），三轮执行顺序确定
- **STATUS.md 伞形重构**：从扁平列表升级为层级化项目全貌
- **持久化体系升级**：
  - session-log.md 建立（工作日志机制）
  - CLAUDE.md 强制加载指令（每次对话必须先读 STATUS + session-log）
  - 深度研究确认持久化机制超越行业最佳实践（Cline Memory Bank）
- **#304 产品经理终审报告发布**：17 条需求逐条审议，9 条确认 + 8 条改进建议

### 关键决策

- **隐私优先级**：用户本地 > 远程配置 > 产品默认值（三轮 review 迭代确认）
- **全链路终审执行顺序**：#304 产品经理 → #306 安全 + #309 UX → #308 QA + #307 用户代言人 + #310 性能 + #311 数据
- **不返工 #287**：技术审计和产品审计是并行两条线

### 教训（已写入 memory）

- PR 创建后必须走完 review 再推进下一任务
- 持续关注 STATUS.md，每次对话开头读取
- 工作日志 session-log.md 推送到 GitHub（换电脑不丢）

### #304 产品终审待用户决策（3 个问题）

1. **Onboarding 字段选择**：是否延后到首次录入后？（Apple HIG 反对首次启动要求配置）
2. **帮助中心**：是否降级为外部网页链接？（Bear/Things 3/Notion 全用外部网站）
3. **卡片外观**：是否简化为单一字号？（去掉正反面独立对齐方式）

### 下次接续

- 等待用户对 #304 三个问题的决策
- 决策后更新 product-requirements.md
- 进入 #305 第二轮：#306 安全工程师 + #309 UX 设计师（可并行）
- #260 无障碍 VoiceOver（S2，待做）
