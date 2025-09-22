# ---

title: 文档风格与元数据规范
version: v6.0
lastUpdated: 2025-09-21
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---

## 文档风格与元数据规范

本规范用于统一本仓库所有 Markdown 文档的结构、头部元数据和跨引用方式，减少歧义并便于自动化校验。

## 必须的 YAML Front Matter

每个关键文档必须在开头包含 YAML Front Matter（`---` 包裹的区块），示例：

```yaml
---
title: NotBad 文档中心 v6.0
version: v6.0
lastUpdated: 2025-09-19
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---
```

- `title`：文档标题（与主标题一致或其正式版本）
- `version`：文档版本，如 `v6.0`
- `lastUpdated`：最后更新时间，格式 `YYYY-MM-DD` 或 `YYYY年M月D日`
- `baseline`：平台基线信息
  - `ios`：最低 iOS 版本（数字）
  - `xcode`：最低 Xcode 版本（数字）
  - `swift`：Swift 大版本（数字或 x.y）
  - `device`：推荐设备（字符串）

建议但非强制字段：

- `status`：`current` | `archived` | `draft`
- `owners`：负责小组或个人，如 `Product Team`

## 标题与结构

- 文档应以一个 `#` 级标题作为主标题
- 使用有序层级：`##`、`###`...
- 表格允许长行（仓库已在 `.markdownlint.jsonc` 中关闭 MD013）

## 链接与引用

- 统一使用相对路径链接仓库内文档
- 对于含空格或中文字符的路径，使用 URL 编码
- 外部链接在 CI 中会被 lychee 校验；如不可公开访问，请加入 `.lycheeignore`

## 术语与版本一致性

- 统一使用：Swift 6.2、iOS 26、Xcode 26、iPhone 17
- 若文档内容中需变更基线版本，必须同步更新 Front Matter 中的 baseline 字段

## 校验工具

- `Scripts/docs_consistency_check.py` 会校验：
  - 关键文档是否存在
  - 链接目标是否存在
  - 基线关键字覆盖情况
  - 禁用后缀样式
  - Front Matter 元数据是否存在且字段完整（新增）
