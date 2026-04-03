# SnapDrill 术语表

> 本文件统一产品文档中的核心术语定义，避免 design / requirements / cases / journeys / business 间语义漂移。

---

## 核心术语

### 采集（Capture）

指用户通过 Camera、Photos、Document Scan、PDF import 或 Manual edit 进入录题流程，将题目内容带入 SnapDrill 的动作与入口集合。强调"把题带进来"的过程。

### 录入

指用户在采集流程中完成裁剪、OCR、元数据填写并保存入库的完整动作。采集是入口，录入是落库完成。

### 题库（Library）

指当前 Profile 下已保存题目的集合，以及围绕这些题目进行搜索、过滤、排序、编辑、批量操作的管理界面与数据范围。

### 复习（Review）

指基于已录入题目进行翻卡、自我评估并更新复习状态的流程。在 SnapDrill 中，复习是免费附加值，不是主价值链起点。

### 导出（Export）

指将当前 Profile 下的题目或结构化数据带出 App 的能力，包含 PDF、JSON、CSV 等格式。导出强调数据可携带权和纸质练习卷产出。

### Profile

指同一设备上的本地数据隔离单元，用于区分不同孩子或不同用户。每个 Profile 拥有独立的题库、统计、复习进度、草稿和自动推断历史。

### `.snapdrill`

指 SnapDrill 的手动备份文件格式。文件为 ZIP 容器，用于打包 Profile、题目、图片、元数据和复习进度等本地数据，供导出、迁移与恢复使用。
