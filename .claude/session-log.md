# SnapDrill 工作日志

> 每次对话结束时追加一条记录。保留最近 2-3 条，旧记录删除。
> 行为规则在 `memory/`，单个改动详情在 GitHub PR/Issue。

---

## 2026-03-26 Session

### 完成

- **技术审计** (#428)：131 文件逐个遍历（6 Phase / 25 Batch），自底向上。1 S0 + 6 S2 + 9 S3
- **产品审计** (#430)：以 6 份产品文档为锚点，3 维度交叉验证（隐私数据路径 / 用户旅程 / 设计铁律）。2 VIOLATION + 6 CONCERN + 1 PARTIAL
- **PR #429 合并**（4 commits）：
  - S0 HeaderView 同步 loadImage → 异步 loadImageAsync
  - S2 logger level / best-effort 注释 / 卸载警告 / Analytics 默认值 / 草稿 GPS 剥离
  - D-7 卡片对齐默认值 center → leading + PRD 更新
  - D-8 图标选择器 20→88 个，14 类分组，移除手动输入 + PRD 更新
- **PR #434 合并**（#431 + #432）：草稿恢复提示增加细节（学科+时间）+ 7 天过期清理
- **PR #435 合并**（#433）：题库编辑模式「全选/取消全选」按钮
- **横向研究 x3**：
  - 草稿箱模式（微博/微信/Apple Notes/Mail/Instagram/Twitter/Bear/Day One）→ 结论：不需要草稿箱
  - Apple 提醒事项图标选择器（60 预设 + emoji，无全量搜索）→ 决定扩充预设到 88 个
  - 题库导出按钮位置（Apple 照片/文件/Anki/竞品）→ 决定加"全选"而非"导出全部"

### 产品决策

- D-7：卡片对齐 → 三选项（左/中/右），默认左对齐
- D-8：图标选择器 → 88 个教育图标，14 类分组，不开放全量 SF Symbol
- 草稿箱：不需要，隐式单草稿恢复正确
- 导出路径：加"全选"按钮（Apple 文件 App 模式），不加"导出全部"

### 下次接续

- Apple 原生对标研究（用户明确要求）
- PDFPagePickerView sending 参数编译错误修复
- TestFlight Build 6

---

## 2026-03-25 Session

### 完成

- WWDC 2021-2025 技术综述文档评估
- 文档体系 Diátaxis 重构（PR #424）
- Milestone 1 关闭 + Git tag `v1.0-doc-baseline`
- 可追溯性审计 5 维度全部完成：0 S0、1 S1、1 S2、3 S3
- 三方审查完成 + S1 修复（PR #427）

### 下次接续

- PR #427 review + 合并
- PDFPagePickerView sending 参数编译错误修复
