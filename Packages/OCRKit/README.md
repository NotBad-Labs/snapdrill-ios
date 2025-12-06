# OCRKit

NotBad 的文字识别核心库，基于 Apple Vision 框架。

## 特性

- ✅ **中英文混合识别** - 支持简体、繁体中文和英文
- ✅ **跨平台** - 支持 iOS 和 macOS
- ✅ **置信度信息** - 返回识别置信度和边界框
- ✅ **可配置** - 支持自定义识别级别和语言
- ✅ **协议抽象** - 支持依赖注入和测试

## 使用方法

```swift
import OCRKit

let service = OCRService.shared

do {
    // 简单识别
    let text = try await service.recognizeText(from: image)
    print("识别结果: \(text)")
    
    // 带置信度识别
    let result = try await service.recognizeTextWithConfidence(from: image)
    print("文本: \(result.text)")
    print("置信度: \(result.confidence)")
    print("描述: \(result.confidenceDescription)")
} catch {
    print("识别失败: \(error)")
}
```

## 自定义配置

```swift
let service = OCRService(
    recognitionLevel: .fast,           // .fast 或 .accurate
    languages: ["en-US"],               // 识别语言
    usesLanguageCorrection: true        // 语言校正
)
```

## 辅助方法

```swift
// 提取标题（第一行，最多50字符）
let title = service.extractTitle(from: text)

// 提取数学表达式
let expressions = service.extractMathExpressions(from: text)
```

## 测试

```bash
cd Packages/OCRKit
swift test
```

## 相关 Package

- [ReviewKit](../ReviewKit) - 复习算法
- [ImageKit](../ImageKit) - 图片存储
