# CaptureKit

NotBad 的**录入链路核心库**，负责图片采集、存储和 OCR 识别。

## 职责

CaptureKit 处理错题的**采集和识别**流程：

| 模块 | 职责 | 技术栈 |
|------|------|--------|
| **图片存储** | App Groups 共享存储 | FileManager |
| **OCR 识别** | 文字识别 | Vision Framework |
| **扫描界面** | 相机/相册/文档扫描 | VisionKit |

## 核心功能

### 1. 图片存储

```swift
import CaptureKit

let storage = ImageStorageService()

// 保存图片到共享目录
let path = try storage.save(image, for: reviewItemID)

// 读取图片
let image = try storage.load(from: path)

// 删除图片
try storage.delete(at: path)
```

### 2. OCR 文字识别

```swift
let ocrService = OCRService()

// 识别图片中的文字
let recognizedText = try await ocrService.recognizeText(in: image)
```

### 3. 扫描界面

使用 VisionKit 提供的原生扫描体验：
- 相机拍照
- 相册选择
- 文档扫描（自动边缘检测）

## 架构特点

- ✅ **App Groups 共享** - 主 App 和 Widget 都能访问图片
- ✅ **路径存储** - 只存储文件路径，避免 SwiftData 膨胀
- ✅ **纯 Swift** - 无 UI 依赖，可独立测试
- ✅ **Swift 6 并发** - async/await + Sendable

## 与 ProcessKit 的区别

| CaptureKit | ProcessKit |
|------------|------------|
| 采集 + 识别 | 编辑 + 增强 |
| Vision (OCR) | Core ML (语义分割) |
| 原图存储 | 图像处理 |

## 运行测试

```bash
cd Packages/CaptureKit
swift test
```
