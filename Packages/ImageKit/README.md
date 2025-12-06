# ImageKit

NotBad 的图片存储核心库。

## 特性

- ✅ **跨平台** - 支持 iOS (UIKit) 和 macOS (AppKit)
- ✅ **高性能** - 直接使用 FileManager，无内存缓存开销
- ✅ **线程安全** - Sendable 合规
- ✅ **可配置** - 支持自定义存储目录

## 使用方法

```swift
import ImageKit

let storage = ImageStorageService.shared

// 保存图片
if let fileName = storage.save(image: uiImage, with: item.id) {
    item.imagePath = fileName
}

// 加载图片
if let image = storage.load(fileName: item.imagePath) {
    imageView.image = image
}

// 删除图片
storage.delete(fileName: item.imagePath)

// 统计信息
print("图片数量: \(storage.imageCount)")
print("存储大小: \(storage.formattedSize)")
```

## 设计原则

**图片存磁盘，数据库只存路径**

| 存储位置 | 内容 |
|---------|------|
| SwiftData | `imagePath: String?` |
| FileManager | 实际图片文件 (.jpg) |

这样设计的原因：
- 避免 SwiftData 内存溢出
- 图片加载可异步按需进行
- 删除 Model 时手动清理图片

## 测试

```bash
cd Packages/ImageKit
swift test
```

## 相关 Package

- [ReviewKit](../ReviewKit) - 复习算法核心库
