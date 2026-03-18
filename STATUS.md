# SnapDrill 项目状态看板

> 最后更新：2026-03-17
>
> 当前阶段：**v1.0 架构夯实**（文档体系 + 宏观审查 + 技术债清零）

---

## 当前焦点

| 状态 | Issue/PR | 内容 | 备注 |
|---|---|---|---|
| 🔄 进行中 | [#288](../../issues/288) | crashReportingEnabled Dead Toggle 修复 | Xcode Review 发现，S2 |

---

## 里程碑

### M1: 文档体系建设 — 完成 :white_check_mark:

| 状态 | Issue | 内容 |
|---|---|---|
| :white_check_mark: | [#270](../../issues/270) | ADR 体系建立（7 个核心架构决策记录） |
| :white_check_mark: | [#272](../../issues/272) | PR 级 DoD（Definition of Done） |
| :white_check_mark: | [#274](../../issues/274) | Technical Debt Ledger |
| :white_check_mark: | [#276](../../issues/276) [#280](../../issues/280) | 文档体系补全 + SSOT 审计 |

### M2: 宏观架构审查 — 进行中

| 状态 | Issue | 内容 | 分类 |
|---|---|---|---|
| :white_check_mark: | [#281](../../issues/281) | 文档准确性修复 + 投机性代码清理（PR #282） | 代码+文档 |
| :white_check_mark: | [#262](../../issues/262) | infrastructure.md + architecture.md 准确性修复 | 文档 |
| :white_check_mark: | [#277](../../issues/277) | PerformanceMonitoringExtensions fire-and-forget | 代码（已删除） |
| :white_check_mark: | [#278](../../issues/278) | SourceRepository 通知缺失 | 代码 |
| :black_square_button: | [#288](../../issues/288) | crashReportingEnabled Dead Toggle | 代码清理 |
| :black_square_button: | [#287](../../issues/287) | v1.0 用户能力清单（纯产品文档推导） | 产品审查 |
| :black_square_button: | [#285](../../issues/285) | 清理 PREMATURE 类型 — iCloud/网络相关枚举 | 代码清理 |
| :black_square_button: | [#286](../../issues/286) | 产品确认 — SHAPE_CONCERN 接口（图标/卡片/自动删除） | 产品决策 |
| :black_square_button: | [#283](../../issues/283) | 评估移除 ReviewBackground 动态装饰动画 | 产品决策 |
| :black_square_button: | [#284](../../issues/284) | 评估 HelpView 帮助系统产品定位 | 产品决策 |

### M3: 缺陷修复

| 状态 | Issue | 内容 | 严重度 |
|---|---|---|---|
| :black_square_button: | [#261](../../issues/261) | 英文隐私权限字符串缺失 + Onboarding 文案 | S1 |

### M4: 质量与合规

| 状态 | Issue | 内容 |
|---|---|---|
| :black_square_button: | [#259](../../issues/259) | 关键保存路径错误处理测试补充 |
| :black_square_button: | [#260](../../issues/260) | 无障碍支持 — VoiceOver + Dynamic Type |
| :black_square_button: | [#264](../../issues/264) | Share Extension URL 消毒 + EXIF GPS 验证 |

### M5: 发布准备

| 状态 | Issue | 内容 | 阻塞 |
|---|---|---|---|
| :black_square_button: | [#161](../../issues/161) | TestFlight Build 6 | M2-M4 完成后 |
| :black_square_button: | [#162](../../issues/162) | GitHub Pro Branch Protection | 4 月 1 日生效 |
| :black_square_button: | [#163](../../issues/163) | 公司 Apple 开发者账号注册 | DUNS 就绪后 |

### 持续改进

| 状态 | Issue | 内容 |
|---|---|---|
| :black_square_button: | [#263](../../issues/263) | Git 分支清理 + 流程改进 |
| :black_square_button: | [#269](../../issues/269) | Dead Code 定期审计机制 |

---

## 近期完成

| 日期 | Issue/PR | 内容 |
|---|---|---|
| 2026-03-17 | [#282](../../pull/282) | 宏观架构审查 — 文档修复 + 投机性代码清理（-1,730 行） |
| 2026-03-16 | [#279](../../pull/279) | 文档体系补全 + SSOT 审计 |
| 2026-03-13 | [#275](../../pull/275) | Technical Debt Ledger |
| 2026-03-13 | [#272](../../issues/272) | PR 级 DoD |
| 2026-03-13 | [#270](../../issues/270) | ADR 体系（7 个决策记录） |
| 2026-03-13 | [#267](../../issues/267) | 文档体系重构（principles/workflow/conventions 拆分） |
| 2026-03-13 | [#258](../../issues/258) | 备份/恢复管线测试补充 |
| 2026-03-13 | [#257](../../issues/257) | PrivacyInfo.xcprivacy 隐私清单 |
| 2026-03-13 | [#256](../../issues/256) | ExportPreviewView PDF 写入错误修复 |

---

## 维护说明

- **更新频率**：每个 PR 合并后更新一次
- **状态图例**：:white_check_mark: 完成 | 🔄 进行中 | :black_square_button: 待处理 | :no_entry_sign: 阻塞
- **Issue 详情**：点击编号跳转 GitHub Issue 查看完整上下文
- **严重度框架**：S0 数据丢失 > S1 流程阻断 > S2 体验受损 > S3 打磨优化（详见 `.claude/workflow.md`）
