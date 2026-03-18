# SnapDrill 项目状态看板

> 最后更新：2026-03-18
>
> 当前阶段：**v1.0 发布冲刺**（本地化补全 + 隐私修复 + 质量收尾）
>
> 蓝图基准线：[#287](../../issues/287) Step A→B→C 已完成（57 条能力，95% 代码已实现）

---

## 当前焦点（按严重度排序）

### S1 — 本地化补全（ACT-1 剩余）

| 状态 | Issue | 内容 |
|---|---|---|
| ⬜ | [#294](../../issues/294) | zh-Hans.strings 补齐至 100% 覆盖率 |
| ⬜ | [#295](../../issues/295) | OnboardingView 内容页 ~18 个硬编码字符串 |
| ⬜ | [#291](../../issues/291) | HelpView 30+ FAQ 硬编码中文字符串 |
| ⬜ | [#292](../../issues/292) | TermsOfServiceView + PrivacyPolicyView 法律文档 |
| ⬜ | [#296](../../issues/296) | 清理 LocalizationKeys 死键和键前缀分裂 |
| ⬜ | [#297](../../issues/297) | en.lproj/InfoPlist.strings 隐私权限字符串英文翻译缺失 |

### S2 — 隐私 + 体验修复

| 状态 | Issue | 内容 |
|---|---|---|
| ⬜ | [#288](../../issues/288) | crashReportingEnabled Dead Toggle（用户关闭但 Crashlytics 仍收集） |
| ⬜ | [#260](../../issues/260) | 无障碍支持 — VoiceOver + Dynamic Type |

### S3 — 技术债清理

| 状态 | Issue | 内容 |
|---|---|---|
| ⬜ | [#285](../../issues/285) | 清理 PREMATURE 类型 — iCloud/网络相关枚举 |
| ⬜ | [#286](../../issues/286) | 产品确认 — SHAPE_CONCERN 接口（图标/卡片/自动删除） |
| ⬜ | [#284](../../issues/284) | 评估 HelpView 帮助系统产品定位 |
| ⬜ | [#264](../../issues/264) | Share Extension URL 消毒 + EXIF GPS 验证 |

---

## 里程碑

### M1: 文档体系建设 — ✅ 完成

| 状态 | Issue | 内容 |
|---|---|---|
| ✅ | [#270](../../issues/270) | ADR 体系建立（7 个核心架构决策记录） |
| ✅ | [#272](../../issues/272) | PR 级 DoD（Definition of Done） |
| ✅ | [#274](../../issues/274) | Technical Debt Ledger |
| ✅ | [#276](../../issues/276) [#280](../../issues/280) | 文档体系补全 + SSOT 审计 |

### M2: 宏观架构审查 + 蓝图验证 — ✅ 完成

| 状态 | Issue | 内容 |
|---|---|---|
| ✅ | [#287](../../issues/287) | v1.0 用户能力清单 — Step A(57条) → B(模块映射) → C(差距分析) |
| ✅ | [#281](../../issues/281) | 文档准确性修复 + 投机性代码清理（PR #282，-1,730 行） |
| ✅ | [#283](../../issues/283) | ReviewBackground 移除（PR #290） |
| ✅ | [#262](../../issues/262) | infrastructure.md + architecture.md 准确性修复 |
| ✅ | [#277](../../issues/277) | PerformanceMonitoringExtensions fire-and-forget（已删除） |
| ✅ | [#278](../../issues/278) | SourceRepository 通知缺失 |

### M3: 本地化 — 🔄 进行中

| 状态 | Issue | 内容 |
|---|---|---|
| ✅ | PR [#293](../../pull/293) | 第二波本地化 — en.strings 全量覆盖 + OnboardingView 迁移 |
| ⬜ | [#294](../../issues/294) | zh-Hans.strings 补齐 |
| ⬜ | [#295](../../issues/295) | OnboardingView 硬编码字符串 |
| ⬜ | [#291](../../issues/291) | HelpView FAQ 本地化 |
| ⬜ | [#292](../../issues/292) | 法律文档本地化 |
| ⬜ | [#296](../../issues/296) | LocalizationKeys 清理 |
| ⬜ | [#297](../../issues/297) | InfoPlist.strings 英文翻译 |

### M4: 质量与合规

| 状态 | Issue | 内容 |
|---|---|---|
| ⬜ | [#288](../../issues/288) | crashReportingEnabled Dead Toggle |
| ⬜ | [#260](../../issues/260) | 无障碍支持 — VoiceOver + Dynamic Type |
| ⬜ | [#264](../../issues/264) | Share Extension URL 消毒 + EXIF GPS 验证 |
| ⬜ | [#285](../../issues/285) | 清理 PREMATURE 类型 |
| ⬜ | [#286](../../issues/286) | SHAPE_CONCERN 接口确认 |
| ⬜ | [#284](../../issues/284) | HelpView 产品定位确认 |

### M5: 发布准备

| 状态 | Issue | 内容 | 阻塞 |
|---|---|---|---|
| ⬜ | [#161](../../issues/161) | TestFlight Build 6 | M3-M4 完成后 |
| ⬜ | [#162](../../issues/162) | GitHub Pro Branch Protection | 4 月 1 日生效 |
| ⬜ | [#163](../../issues/163) | 公司 Apple 开发者账号注册 | DUNS 就绪后 |

---

## 近期完成

| 日期 | Issue/PR | 内容 |
|---|---|---|
| 2026-03-18 | [#293](../../pull/293) | 第二波本地化 — en.strings 全量覆盖 + OnboardingView 迁移 |
| 2026-03-18 | [#289](../../pull/289) | 全球市场策略更新 + 项目看板 + review 流程改进 |
| 2026-03-18 | — | Pre-#287 Issue 审计：关闭 #259/#263/#269，拆分 #261→#297 |
| 2026-03-17 | [#290](../../pull/290) | 第一波架构清理 — 蓝图驱动的 PREMATURE/UNJUSTIFIED 代码移除（-316 行） |
| 2026-03-17 | [#282](../../pull/282) | 宏观架构审查 — 文档修复 + 投机性代码清理（-1,730 行） |
| 2026-03-16 | [#279](../../pull/279) | 文档体系补全 + SSOT 审计 |
| 2026-03-13 | [#275](../../pull/275) | Technical Debt Ledger |
| 2026-03-13 | [#271](../../pull/271) | ADR 体系（7 个决策记录） |
| 2026-03-13 | [#266](../../pull/266) | S0 测试缺口填补 — 备份管线 + 保存防护 |
| 2026-03-13 | [#265](../../pull/265) | S1 基线修复 — PDF 导出静默失败 + PrivacyInfo.xcprivacy |

---

## 已关闭（本轮审计）

| Issue | 原因 |
|---|---|
| [#259](../../issues/259) | S3 测试补充，降级；错误弹窗纳入 #287 审计 |
| [#261](../../issues/261) | Onboarding 已被 #293 解决；隐私权限字符串拆分为 #297 |
| [#263](../../issues/263) | 分支清理不需要 issue 追踪 |
| [#269](../../issues/269) | PR #282 + #290 已完成大规模清理 |

---

## 维护说明

- **更新频率**：每个 PR 合并后更新一次
- **状态图例**：✅ 完成 | 🔄 进行中 | ⬜ 待处理 | 🚫 阻塞
- **Issue 详情**：点击编号跳转 GitHub Issue 查看完整上下文
- **严重度框架**：S0 数据丢失 > S1 流程阻断 > S2 体验受损 > S3 打磨优化（详见 `.claude/workflow.md`）
- **蓝图追溯链**：product-vision.md → product-requirements.md → #287 能力清单 → 差距分析 → 行动项
