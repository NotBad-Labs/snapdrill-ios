# NotBadCore

**核心逻辑层 (The Core Logic Layer)**

`NotBadCore` 包含应用共享的纯业务实体、基础服务、算法引擎和通用工具。它是应用的心脏，不依赖于 UI 或 Data 层。

## 组成部分

### 1. Domain (领域实体)
- `ReviewItem`: 复习条目
- `Subject`: 学科枚举
- `ReviewSource`: 来源枚举

### 2. Engine (算法引擎)
- 间隔重复算法 (Spaced Repetition) 的核心实现。

### 3. Service (基础服务)
- `OCRService`: 文本识别服务 (基于 Vision)。
- `ImageStorage`: 图片文件管理。
- `CaptureService`: 采集流程协调。

### 4. Utils (通用工具)
- `Date+Extension`, `Collection+Safe` 等基础扩展。

## 依赖
- *无依赖* (纯 Swift)
