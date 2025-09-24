# NotBad 理想项目结构

## 顶层结构

```text
NotBad/
├── NotBad/                    # 主应用
│   ├── Application/           # App 生命周期
│   ├── Domain/               # 业务逻辑
│   │   ├── Models/          # 领域模型
│   │   ├── UseCases/        # 用例
│   │   └── Repositories/    # 仓库接口
│   ├── Data/                 # 数据层
│   │   ├── Local/           # 本地存储
│   │   ├── Remote/          # 远程 API
│   │   └── Repositories/    # 仓库实现
│   ├── Presentation/         # 展示层
│   │   ├── Views/           # SwiftUI 视图
│   │   ├── ViewModels/      # 视图模型
│   │   └── Components/      # 可复用组件
│   └── Infrastructure/       # 基础设施
│       ├── Extensions/      # 扩展
│       ├── Utilities/       # 工具类
│       └── Services/        # 系统服务
├── NotBadTests/              # 单元测试
│   ├── Domain/
│   ├── Data/
│   └── Presentation/
├── NotBadUITests/            # UI 测试
├── Scripts/                  # 自动化脚本
├── docs/                     # 文档
│   ├── devops/              # DevOps 文档
│   ├── api/                 # API 文档
│   └── guides/              # 用户指南
└── .github/                  # GitHub 配置
```

## 文件命名规范

- Models: `*Model.swift`
- Views: `*View.swift`
- ViewModels: `*ViewModel.swift`
- Tests: `*Tests.swift`
- Mocks: `Mock*.swift`
