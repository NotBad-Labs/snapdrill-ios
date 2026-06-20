---
last_verified: 2026-06-20
layer: pattern
---
# 功能范围与路线

> 本文档承载不属于单个 feature 的跨功能总览：功能边界（MoSCoW）、v2.0 功能全景、探索性功能评估框架。
> 它回答「整体做什么、不做什么、怎么决定要不要做」——而非任一具体功能的规格。
> 单个功能的规格见对应 feature spec；**逐功能现状以 [feature-status.md](feature-status.md)（SSOT）为准**，本文档只引用、不重复罗列状态。
> 待验证假设（H1-H10）见 [../explanations/assumptions.md](../explanations/assumptions.md)。

---

## 功能边界（MoSCoW 分类）

> **MoSCoW** 优先级框架：Must = 没有就不能发布；Should = 重要但可延期；Could = 锦上添花；Won't = 明确不做。
> Kano 模型映射见 [../explanations/design-principles.md](../explanations/design-principles.md) §价值链与优先级。

### Must Have（缺失 = 产品不可用）

- 多种方式采集资料 / 题目（拍照、导入、手动）
- OCR 文字识别（降低手动输入成本）
- 资料分类管理（学科、来源、年级、标签、难度；字段 taxonomy 待 PO 长期裁决）
- 搜索和过滤
- 导出（PDF / JSON / CSV）
- 本地数据存储（隐私优先）
- 多 Profile（多套独立资料库 / 工作区隔离场景）
- 草稿恢复（S0 数据丢失防护）
- 删除撤销（数据安全信任）

### Should Have（缺失 = 有摩擦但可用）

- PDF 增强（去答案、留白、页眉页码）
- 单题快速打印
- 批量打标签
- 批量删除（选择模式 + 软删除）
- 难度过滤
- App 内语言切换
- 手动备份/恢复
- iOS Share Extension
- 基础 SM-2 间隔重复复习（已实现，免费附加值定位）

### Could Have（锦上添花）

- 图片处理增强：去手写/去批改痕迹/试卷还原（Pro 付费，免费限次体验）[需 PoC: 端上方案可用且 SDK < 50MB]
- 智能组卷 / Smart Paper（Hybrid：免费限次体验 + Pro 无限精准选题，ADR-001）
- iCloud 同步（Pro 付费）[阻塞: #485（前置 #479）]
- Word 导出（Pro 付费）[阻塞: #486（前置 #479）]
- 高级统计（Hybrid：基础统计免费 + 趋势图/薄弱排行 Pro，ADR-001）
- 资料分享（单项生成卡片分享）
- 批量导出原图（ZIP）
- iPad 大屏优化
- 批量导入增强（AI 辅助拆题，探索性）
- 手写体识别增强（探索性）
- 角色预设套件（为不同使用场景提供预配置的字段/标签方案，如"考试备考"/"证书培训"/"竞赛题"）—— **边界**：仅作为设置页的可选模板入口（按一下就改字段开关），**不进入 Onboarding**，不增加首次配置摩擦（vision §1 录入体验 + §2 简洁）

### Won't Have（明确不做）

- 提供题库内容（我们是工具，不是内容平台）
- 社交功能（不是社区）
- 排行榜 / 竞争机制（不是游戏）
- 限制免费录入数量（核心差异化，永不限制）
- 去水印（产品本身不应该有水印）
- 注册/登录（零注册是核心差异化）

### 待评估（需技术可行性确认）

- 公式识别与渲染（LaTeX/MathML，无 Apple 原生 API）
- iPad + Apple Pencil 深度集成（依赖第三方 App 支持）
- 多科目模板（不同学科结构化字段）—— **边界**：仅作为高级字段配置模板（用户选「数学/英语/物理」自动应用预设字段子集），不扩展核心字段系统的层级（vision §2 简洁，不增加 [../explanations/design-principles.md](../explanations/design-principles.md) §字段可配置系统 复杂度）
- AI 解题提示（**初步评估为蚕食 vision §不是内容平台禁令 + 推翻 H3「核心需求是存档/打印，不是解题」假设；不进入近期路线**。若未来 H3 数据推翻，需先在 [../explanations/vision.md](../explanations/vision.md) 加新假设/原则承接才能纳入）

---

## v2.0 功能全景

> 所有功能统一为 v2.0。已实现功能无特殊标注；未实现功能标注阻塞原因或 PoC 条件。
> 本节只描述产品能力与实现状态，不记录 PR 编号和 Review 状态。研发流转见 git log + GitHub issues/PRs。
> 逐功能权威状态见 [feature-status.md](feature-status.md)（SSOT）；本节内联的 `[阻塞: #N]` / `[需 PoC: 条件]` 标签与之对齐。

**录入**
- 智能相机拍照（实时文字区域检测 + 稳定性指示器 + 自动框选）
- 相册导入
- 文档扫描（含多页选择）
- PDF 导入（文件选择器 + 逐页预览 + 页面选择 + 裁剪）
- 手动编辑
- 剪贴板导入（从系统剪贴板粘贴文本内容）
- 一图一题手动裁剪（自动框选 + 手动调整）
- 一图连续裁剪（同一张图上连续裁剪多题）
- OCR 印刷体中英文识别（Apple Vision 高精度模式），用户可手动修正
- OCR 手动重试 + 稳定性提示（失败后提供重试选项，引导调整拍摄）
- OCR 结果复制到剪贴板
- 字段可配置系统（学科默认开启，其余按需）
- 字段自动推断（沿用上次选值）
- 端上 AI 自动标注（Apple Foundation Models：从题干自动推断学科/难度，离线、零上传）
- 连续录入（保存后自动回到摄像头）
- 草稿恢复（意外退出后可恢复，含纯文本草稿）
- 相机权限缺失处理（权限拒绝/受限时引导用户到系统设置开启）
- iOS Share Extension
- 手写体识别增强 [需 PoC: 识别率 >= 70% (20 张真实试卷) 则纳入]
- AI 辅助拆题 [需 PoC: 边界准确率 >= 80% (10 份真实试卷) 则纳入]

**管理**
- 资料库管理：搜索 + 多维过滤（学科/标签/难度）+ 编辑
- 系统字段选项增删改（学科/来源/年级，含颜色和预设图标）
- 题库排序（时间/学科/难度/复习状态）
- 批量打标签（选择模式 + 多题操作）
- 删除撤销（软删除 + 5 秒 Toast 撤销，超时永久删除）
- 批量删除（选择模式 + 软删除）

**复习**
- SM-2 间隔重复复习（翻卡 + 滑动评估）
- Dashboard 统计 + 待复习入口

**导出与备份**
- PDF 导出（含预览、去答案打印、留白答题区、页眉页码）
- 单题快速打印（详情页固定 1 题/页）
- JSON / CSV 结构化数据导出（以实际导出字段清单为准）
- 手动备份/恢复（`.zip` 文件）
- 资料分享卡片（ImageRenderer 生成分享图片）
- 批量导出原图 ZIP
- CSV 数据导入（RFC 4180 合规）
- 图片处理增强（Pro 付费，免费限次体验）：去手写/去批改痕迹/试卷还原 [需 PoC: 端上方案可用且 SDK < 50MB]
- Word 导出（Pro 付费）[阻塞: #486（前置 #479）]
- 智能组卷 / Smart Paper（Hybrid：免费限次 + Pro 无限；SM-2 驱动选题 → 自动排版 → PDF/打印，ADR-001）

**同步与存储**
- iCloud CloudKit 同步（Pro 付费，**付费核心引擎**）：同步范围为全部 Profile（与备份策略对齐），基于 Apple CloudKit，利用设备已有 Apple ID。设计决策见 [../features/backlog/feat-icloud-sync.md](../features/backlog/feat-icloud-sync.md) [阻塞: #485（前置 #479）— 需 CloudKit Container]

**多 Profile**
- 多 Profile / 多题库隔离（本地切换，参考 Obsidian Vault 切换，覆盖多套独立资料库 / 工作区场景）

**设置与个性化**
- 用户资料（昵称/座右铭/头像/每日目标，纯本地）
- 复习卡片外观（字号正反面独立设置，对齐三选项默认左对齐）
- 通知设置（提醒时间/声音；不使用角标，仅本地通知提醒）
- 外观模式（跟随系统/浅色/深色）
- 匿名遥测开关（仅保存本地 `TelemetryGate` 同意状态；全球生产服务为 NoOp，当前不启用网络采集）
- App 内语言切换（中文/英文直选）
- 媒体缓存清理 + 存储管理

**引导与帮助**
- 多页 Onboarding（功能介绍，不含字段选择）
- 首次录入后字段配置引导
- Feature Tooltips（首次使用提示；TipKit 按 Profile 隔离）
- 帮助中心（外部网页 FAQ 链接）

**隐私与合规**
- 零注册，纯本地存储
- 隐私政策 / 服务条款
- 卸载数据丢失提醒
- 开源许可展示（第三方库 Mantis / ZIPFoundation 等；Firebase SDK 已由 #803 从工程删除，许可页不再列出 Firebase）

**无障碍**
- 全模块 VoiceOver 辅助标签、提示和公告（Dashboard / Capture / Library / Settings / Review）

**平台优化**
- iPad 分屏/大屏优化（sidebarAdaptable + 动态 grid 列数）
- iPad + Apple Pencil 深度集成 [需 PoC]

---

## 探索性功能评估框架

| 功能 | 评估维度 | Go 条件 | No-Go 条件 | 评估窗口 |
|---|---|---|---|---|
| 手写体识别增强 | Apple Vision 中文手写识别率 | PoC 识别率 >= 70%（20 张真实试卷） | 识别率 < 50% 且无 Apple 改进路线 | 正式纳入前 |
| AI 辅助拆题 | 文档结构识别的题目边界检测精度 | 边界准确率 >= 80%（10 份真实试卷） | 准确率 < 60% 或误拆严重 | 正式纳入前 |
| 图片处理增强（去手写/去批改痕迹/试卷还原） | 第三方端上方案（离线、无数据上传、Pro 付费） | 端上方案可用，SDK < 50MB，去手写准确率 >= 80% | 所有方案均需云端或准确率 < 60% | 正式纳入前 |
| 数理化公式识别 | 第三方端上方案（离线、无数据上传） | 端上方案可用，SDK < 50MB | 所有方案均需云端 | 待排期 |

**评估流程**：PoC → 对照 Go/No-Go 条件决策 → Go 创建 Issue；No-Go 标注原因，下次 iOS 大版本重新评估。

**待评估（需技术可行性确认）**
- 数理化公式识别与渲染（LaTeX，无 Apple 原生 API，需第三方端上方案）

---

## 相关文档

| 文档 | 关系 | 说明 |
|---|---|---|
| [feature-status.md](feature-status.md) | SSOT | 逐功能权威状态（已实现/阻塞/PoC/Backlog） |
| [../explanations/vision.md](../explanations/vision.md) | 上游 | 产品定位、原则、用户画像 |
| [../explanations/design-principles.md](../explanations/design-principles.md) | 上游 | 设计决策、交互铁律、价值链与优先级 |
| [../explanations/assumptions.md](../explanations/assumptions.md) | 相关 | 待验证假设 H1-H10 |
| [../explanations/business-model.md](../explanations/business-model.md) | 相关 | 商业化分层、Pro/Free 划分 |
| [../decisions/ADR-001-smart-paper-analytics-pricing.md](../decisions/ADR-001-smart-paper-analytics-pricing.md) | 相关 | Smart Paper / 高级统计 Hybrid 定价决策 |
