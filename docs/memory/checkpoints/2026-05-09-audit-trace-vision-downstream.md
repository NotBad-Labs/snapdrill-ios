---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [product_change]
---
# 归零审计：product-vision → 下游全链追溯

## Goal

从 product-vision.md 出发，逐层验证其声称的每一个事实在下游文档和代码中是否被正确承接。

## Scope

vision → design → requirements → architecture → 源代码（抽样关键声明）

## 追溯矩阵

### 1. 定位三词："简洁、私有、原生"

| Vision 声明 | Design 承接 | Requirements 承接 | 代码验证 |
|---|---|---|---|
| 简洁 | "任何功能如果损害了录入和管理的简洁性就不该做" (design L36) | 过滤维度仅 3 个(学科/标签/难度)，design 明确排除来源/年级过滤 | Tab bar 5 项无冗余；录入路径 Camera→crop→save 最短路径 |
| 私有 | "数据属于用户不是口号" (design L269) | JSON/CSV/PDF/.snapdrill 6 种导出格式 (req L94-105) | `PDFExportService` + `DataExporter` + `PrivacySettingsViewModel` 实现全部导出路径 |
| 原生 | "深度依赖 Apple 平台原生能力" (design L126) | Vision OCR, CloudKit iCloud, TipKit, Share Extension | 零跨平台 import；纯 Apple 技术栈 |

### 2. 六条产品原则（按优先级）

| # | 原则 | Design [PX] | Requirements | 代码 |
|---|---|---|---|---|
| P1 | 录入体验是生命线 | [P1] OCR、连续录入、字段配置、Share Extension | P0 5 种采集方式全部 ✅ | `CaptureView` 作为独立 Tab，`switchToCaptureTab` 通知支持深度跳转 |
| P2 | 简洁即正义 | [P2] Dashboard 不做操作、过滤维度克制、批量操作最小化 | 仅 3 个过滤维度 | Features 层 5 个独立 feature，无功能蔓延 |
| P3 | 免费即门槛 | design 未显式标记 [P3]，但导出设计中基础导出免费、增强 Pro | 采集/管理/基础导出全免费，Pro 仅增值 | `isProUser` 门控仅在 settings 和 smart-paper 路径（`#479` 阻塞） |
| P4 | 数据属于用户 | [P4] 导出打印、备份恢复、删除撤销、图片存储 | 6 种导出格式 + `.snapdrill` 备份 | `PDFExportService` / `DataExporter` / `BackupService` / `ZIPArchiver` / `DeletionScheduler`（5 秒撤销窗口） |
| P5 | 家长友好 | [P5] 多 Profile、复习克制、字段默认最少化、引导延后 | Multi-Profile 需求 | `Profile` model + `ProfileManager` + `ProfileMigration` + BackupDTO 含 `ProfileBackupData` |
| P6 | 原生优先 | [P6] Vision OCR、CloudKit iCloud、Apple HIG 模式映射 | Vision OCR 能力列表 | `apple-native.md` 映射 Apple HIG → 具体组件选择 |

**发现**: P3（免费即门槛）在 design 中没有显式 [P3] 标注。design 在导出/组卷/统计章节提到了免费 vs Pro 分层，但未用 [P3] 标签追溯。这是 design 的标注遗漏。

### 3. "不是什么" 四个否定

| Vision 否定 | Design | 代码验证 |
|---|---|---|
| 不是 Anki 记忆工具 | "复习是锦上添花，不能喧宾夺主" (design L377) | Review 是 5 个 feature 之一，11 个文件，架构权重合理 |
| 不是内容平台 | "不做推荐算法" | 无推荐/feed/timeline 代码 |
| 不是社交产品 | "不做分享社区" | 唯一的"分享"是系统 ShareLink（`share_card_title`），无社交功能 |
| 不是学习打卡 | "不做打卡机制、不搞连续天数、不弹成就弹窗" | 无 streak/checkin/achievement 代码 |

### 4. 用户画像

| Vision 画像 | Design 承接 | 代码 |
|---|---|---|
| 家长（35岁妈妈）是基线 | "界面语气成熟、不幼稚" "零学习曲线" (design L40-42) | L10n 文案语气中性 |
| 多孩家庭 Multi-Profile 刚需 | 完整多 Profile 设计章 (design L203-233) | `Profile` + `ProfileManager` + `ProfileMigration` |
| 初高中学生自主使用 | 复习功能面向自主复习场景 | `ReviewViewModel` + `SM2State` |

### 5. 价值链

| Vision | Design | Requirements | 代码 |
|---|---|---|---|
| 采集 → 管理 → 导出/打印 | Kano 模型映射 (design L22-32) | 采集 P0 ×5, 管理(排序/过滤/搜索), 导出 6 格式 | `CaptureView` → `LibraryView` → `ExportOptionsSheet` + `PDFExportService` |
| 复习是独立附加值 | "复习不在价值链内" (design L36) | 复习在独立章节，非核心路径 | Review feature 独立模块 |

### 6. 文档使用规则（vision L153-158）

| Vision 规则 | 验证 |
|---|---|
| "所有功能需求必须能追溯到产品原则" | ✅ design 全章使用 [PX] 标注，requirements 显式引用 design |
| "架构决策与产品定位冲突时以产品定位为准" | ⚠️ 未找到显式验证机制（ADR 中有讨论但无自动化检查） |
| "测试优先级：录入 > 管理 > 导出 > 复习" | ⚠️ testing.md 未体现此优先级排序 |

### 7. 成功信号（vision L136-148）

| 信号 | 代码验证 |
|---|---|
| 首次录入 ≤ 30s | `AnalyticsServiceProtocol` 定义了 `capture_start` / `item_saved` 事件，但埋点实现在 Firebase 适配器中（Infrastructure 层），未被测试覆盖 |
| D7 留存题库 >10 题 | 同上，`library_count` 事件已定义 |
| Multi-Profile 数据泄漏 = 0 | Profile 数据隔离通过独立 SwiftData store 实现，但无自动化跨 Profile 数据泄漏检测测试 |

## Findings

### Warning (2)

**W1: P3（免费即门槛）在 product-design.md 中无 [P3] 标注**
- design 的导出/组卷/统计章节描述了免费 vs Pro 分层，但未用 `[P3]` 标签追溯
- 其他 5 条原则（P1/P2/P4/P5/P6）均有显式标注
- 影响：当下游文档需要追溯"这条设计服务于哪条原则"时，P3 找不到锚点

**W2: vision 的测试优先级规则在 testing.md 中未落地**
- vision L157: "测试优先级按模块重要性排序：录入 > 管理 > 导出 > 复习"
- `docs/principles/testing.md` 未提及此优先级
- 影响：测试策略缺乏与产品优先级的显式对齐

### Info (2)

**I1: vision 的"成功信号"6 个指标有 Analytics 事件定义，但无自动化验证**
- 事件名已在 `AnalyticsServiceProtocol` 中定义（`capture_start`、`item_saved`、`library_count` 等）
- 但 Analytics 埋点逻辑在 Infrastructure 层的 `FirebaseAnalyticsService` 中，该层零测试
- 成功信号的数据采集链路未被测试覆盖

**I2: "架构决策与产品定位冲突时以产品定位为准" 无可自动化检查**
- 这是人工裁决规则，当前靠人工遵守
- 无 CI 检查或 lint 规则验证

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 追溯完整性 | 9/10 | 6 条原则中 5 条有完整 [PX] 标注链，vision 的否定全部在代码中成立 |
| 设计一致性 | 9/10 | design 忠实承接 vision，无矛盾 |
| 需求完整性 | 9/10 | requirements 覆盖 design 的全部功能决策 |
| 代码兑现 | 9/10 | 核心声明（零注册、导出、Profile、图片存储、Apple 原生）全部有代码实现 |
| **综合** | **9.0/10** | |

## Conclusion

从 product-vision 到代码的意图链完整且一致。vision 的定位、原则、否定、价值链在 design → requirements → 代码三层中逐层落地。两个 Warning 都是标注/文档对齐问题，非代码缺陷。零信任验证通过。
