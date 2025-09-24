# Testing Utilities

本目录提供测试与预览可复用的轻量工具与夹具（fixtures）。

• 位置：`NotBad/Testing/`

• 资源：`NotBad/Resources/MockData/`

## Mock 数据

- 新增 JSON：将文件放入 `NotBad/Resources/MockData/`，保持 UTF-8 编码。
- 命名约定：使用小写下划线，例如：`review_sessions.json`。
- 日期/时间：优先使用 ISO8601 字符串，测试中通过 `JSONDecoder.dateDecodingStrategy = .iso8601` 解码。

## MockDataProvider

- 用途：集中管理 Mock JSON 的读取与映射，供测试与 SwiftUI 预览共享。
- 现有 API：
  - `MockDataProvider.loadReviewSessions() -> [ReviewSession]`
- 难度值映射：
  - "简单" → `.easy`
  - "中等" → `.medium`
  - "困难" → `.hard`

## 契约测试（Contract Tests）

- 目的：在模型演进时保障 JSON 结构与含义稳定，避免破坏性变更。
- 示例：`NotBadTests/Contracts/ReviewSessionContractTests.swift`
  - 直接从源码树读取 JSON，断言条数与字段（如本地化难度）。
  - 通过 `MockDataProvider` 解码为领域模型，断言映射正确。

## 在 SwiftUI 预览中使用 Mock

- 在 `#if DEBUG` 下调用 Provider，提供非空数据，提升预览效果与 DX。
- 示例思路：
  - 读取若干 `ReviewSession`，构造一个示例 `ReviewItem` 与相应 `ViewModel`。
  - 在 `PreviewProvider` 中注入 `AppEnvironment`/`ServiceContainer`。

> 提示：预览/测试路径分离时，可使用 `#filePath` 计算相对工程根目录定位 JSON，避免依赖 Bundle 资源配置。
