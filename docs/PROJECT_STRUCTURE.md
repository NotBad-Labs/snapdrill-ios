# 项目结构（NotBad）

> 精简版占位文档，描述主目录职责，确保链接可用。

```
NotBad/
├── App/                 # 入口与 App 生命周期
├── Assets.xcassets/     # 资源（图标、颜色等）
├── Data/                # 数据访问、迁移计划
├── Domain/              # 协议、值对象等（历史/兼容）
├── Infrastructure/      # 外部服务封装（OCR、AI、Analytics 等）
├── Presentation/        # SwiftUI 视图与导航
├── Resources/           # 本地化资源
└── Widget/              # Widget 相关代码
```

- `NotBadTests/`：单元、集成、性能测试。
- `NotBadUITests/`：UI 测试。
- `Packages/`：模块化拆分（ReviewKit、CaptureKit、ProcessKit）。
- `docs/`：架构/规范/术语表等文档；归档文档位于 `docs/archive/`。
