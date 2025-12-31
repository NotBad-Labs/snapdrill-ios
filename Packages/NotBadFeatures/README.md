
# NotBadFeatures

**功能模块集 (Feature Modules Collection)**

`NotBadFeatures` 是应用的主要业务逻辑载体，它将原来的多个分散模块整合为一个统一的编译单元，以提高聚合度和编译速度。

## 模块清单

### 1. Capture (采集)
- **职责**: 文档扫描、拍照、OCR 识别。
- **关键类**: `SmartCameraView`, `CaptureResultView`.

### 2. Library (题库)
- **职责**: 浏览、编辑和管理已保存的错题。
- **关键类**: `LibraryView`, `LibraryDetailView`.

### 3. Review (复习)
- **职责**: 提供沉浸式的 Flashcard 复习体验。
- **关键类**: `ReviewView`.

### 4. Dashboard (仪表盘)
- **职责**: 首页概览，展示复习进度统计。
- **关键类**: `DashboardView`.

### 5. Settings (设置)
- **职责**: 应用配置、关于页面、开源许可。
- **关键类**: `SettingsView`, `LicenseView`.

## 依赖关系
- `NotBadCore`: 获取业务逻辑和服务。
- `NotBadUI`: 使用 UI 组件。
- `NotBadData`: 进行数据读写。
