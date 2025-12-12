# NotBad Packages

NotBad 核心业务逻辑模块索引。

## Package 列表

| Package | 职责 | 链接 |
|---------|------|------|
| **ReviewKit** | 领域层核心：数据模型、复习算法、持久化 | [ReviewKit/README.md](ReviewKit/README.md) |
| **CaptureKit** | 录入链路：图片存储、OCR、扫描界面 | [CaptureKit/README.md](CaptureKit/README.md) |
| **ProcessKit** | 图像处理：手写擦除、图像增强 | [ProcessKit/README.md](ProcessKit/README.md) |

## 运行测试

### ReviewKit

```bash
cd Packages/ReviewKit
swift test
```

### ProcessKit

```bash
cd Packages/ProcessKit
swift test
```

### CaptureKit

```bash
cd Packages/CaptureKit
swift test
```

## 架构说明

通过 Swift Package 实现物理模块化，编译器强制执行架构约束：

- Package 无法引用 App 代码（单向依赖）
- Package 保持纯粹（无 UI 依赖）
- App 和 Widget 共享同一 Model 定义

详细信息请参考各 Package 的 README。
