# NotBad App - 技术术语表 v6.0 (Swift 6.2 + iOS 26)

## 文档定位：技术团队统一词汇表 (Technical Vocabulary Reference)

本文档面向**开发、测试、运维**角色，定义基于iOS 26+ Swift 6.2前沿技术栈的核心技术概念、架构模式、实现规范，是确保技术团队高效协作和代码一致性的**唯一事实来源**。

## 文档治理与变更流程

- **从属关系**: 术语表支撑PRD和TDD的技术实现，确保技术概念一致性
- **更新触发**: TDD技术架构变更时，术语表必须同步更新
- **版本同步**: 术语表版本号与PRD、TDD保持一致
- **使用原则**: 所有技术文档和代码注释应优先使用术语表中的标准术语

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md)
- TDD: [docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v6.0.md](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md)
- RTM: [docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v6.0.md](../rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v6.0 (Swift6.2 + iOS26).md](NotBad%20App%20-%20业务术语表%20v6.0%20(Swift6.2%20+%20iOS26).md)
- 术语→代码索引: [docs/glossary/NotBad App - 术语到代码索引 v6.0 (Swift6.2 + iOS26).md](NotBad%20App%20-%20术语到代码索引%20v6.0%20(Swift6.2%20+%20iOS26).md)

| 版本 | 日期 | 作者 | 变更说明 | 状态 |
| :---- | :---- | :---- | :---- | :---- |
| v1.1 | 2025-09-04 | Tech Team | 基于PRD v4.0和TDD v4.0的基础技术术语 | 已归档 |
| **v6.0** | **2025-09-19** | **Tech Team** | **🚀 全面升级至Swift 6.2 + iOS 26技术栈，新增前沿技术术语** | ✅ **生效中** |

## 1. Swift 6.2 前沿技术术语 (Swift 6.2 Cutting-edge Technologies)

### 1.1 并发编程术语 (Concurrency Programming)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Enhanced Actor Isolation** | Enhanced Actor Isolation | Swift 6.2 Actor增强隔离 | OCR处理、数据同步的线程安全 |
| **Improved TaskGroup** | Improved TaskGroup | Swift 6.2 TaskGroup改进 | 批量图片处理、并发OCR |
| **Enhanced Sendable** | Enhanced Sendable Checking | 编译时并发安全验证 | 数据模型跨Actor传递验证 |
| **Structured Concurrency** | Structured Concurrency | 结构化并发编程模式 | 防止并发泄漏和竞态条件 |
| **Actor Re-entrancy** | Actor Re-entrancy | Actor重入性控制 | 复杂业务逻辑的并发协调 |
| **Isolated Parameters** | Isolated Parameters | 参数隔离标注 | 函数参数的并发安全保证 |
| **Global Actor** | Global Actor | 全局Actor模式 | MainActor UI更新协调 |

### 1.2 数据处理术语 (Data Processing)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Enhanced Collections** | Enhanced Collections | Swift 6.2集合增强 | 高性能错题搜索和排序 |
| **Advanced Pattern Matching** | Advanced Pattern Matching | 增强模式匹配 | 复杂数据筛选和分类 |
| **Result Builders** | Result Builders | 结果构建器 | 声明式数据构建 |
| **Property Wrappers** | Property Wrappers | 属性包装器 | 数据验证和转换 |
| **KeyPath Expressions** | KeyPath Expressions | 键路径表达式 | 动态数据访问和绑定 |

### 1.3 错误处理术语 (Error Handling)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Improved Error Handling** | Improved Error Handling | Swift 6.2错误处理改进 | 优雅的异常处理机制 |
| **Typed Throws** | Typed Throws | 类型化异常抛出 | 明确的错误类型声明 |
| **Error Recovery** | Error Recovery | 错误恢复机制 | 网络异常和数据冲突处理 |
| **Failure Propagation** | Failure Propagation | 失败传播控制 | 复杂调用链的错误处理 |

## 2. iOS 26 平台技术术语 (iOS 26 Platform Technologies)

### 2.1 视觉处理术语 (Vision Processing)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Advanced Vision Framework** | Advanced Vision Framework | iOS 26 Vision增强 | 超高精度OCR识别 |
| **Enhanced Text Recognition** | Enhanced Text Recognition | 增强文字识别 | 中文和数学公式识别 |
| **Smart Document Scanning** | Smart Document Scanning | 智能文档扫描 | 自动裁剪和质量增强 |
| **Real-time OCR** | Real-time OCR | 实时文字识别 | 相机预览实时识别 |
| **Multi-language Support** | Multi-language Support | 多语言识别支持 | 中英文混合识别 |
| **Formula Recognition** | Formula Recognition | 公式识别 | 数学公式专项识别 |

### 2.2 数据持久化术语 (Data Persistence)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Enhanced SwiftData** | Enhanced SwiftData | iOS 26 SwiftData增强 | 现代化本地数据存储 |
| **Advanced CloudKit** | Advanced CloudKit | iOS 26 CloudKit增强 | 跨设备数据同步 |
| **Optimized Queries** | Optimized Queries | 查询优化 | 高性能数据检索 |
| **Automatic Migration** | Automatic Migration | 自动数据迁移 | 版本升级数据兼容 |
| **Relationship Management** | Relationship Management | 关系管理 | 复杂数据关联处理 |
| **Data Validation** | Data Validation | 数据验证 | 模型层数据完整性 |

### 2.3 用户界面术语 (User Interface)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **ProMotion Max** | ProMotion Max | iOS 26 120fps+显示 | 极致流畅的滚动体验 |
| **Advanced SwiftUI** | Advanced SwiftUI | iOS 26 SwiftUI增强 | 现代化用户界面 |
| **Dynamic Island Integration** | Dynamic Island Integration | 灵动岛集成 | 学习状态实时显示 |
| **Adaptive Layout** | Adaptive Layout | 自适应布局 | 多设备屏幕适配 |
| **Interactive Widgets** | Interactive Widgets | 交互式小组件 | 桌面快速操作 |

### 2.4 设备端AI术语 (On-device AI)

| 术语 (中文) | 英文术语 | 技术实现 | 使用场景 |
|-------------|----------|----------|----------|
| **Device-side AI Models** | Device-side AI Models | 设备端AI模型 | 本地智能分析处理 |
| **Neural Engine Optimization** | Neural Engine Optimization | 神经引擎优化 | AI任务硬件加速 |
| **Local Machine Learning** | Local Machine Learning | 本地机器学习 | 隐私保护的AI处理 |
| **Core ML Integration** | Core ML Integration | Core ML集成 | AI模型部署和推理 |
| **Privacy-preserving AI** | Privacy-preserving AI | 隐私保护AI | 无需上传数据的AI分析 |

## 3. 架构设计术语 (Architecture Design)

### 3.1 Clean Architecture术语

| 术语 (中文) | 英文术语 | 架构层级 | 职责描述 |
|-------------|----------|----------|----------|
| **Clean Architecture** | Clean Architecture | 整体架构模式 | 四层分离的架构设计 |
| **Domain Layer** | Domain Layer | 领域层 | 业务逻辑和规则的核心层 |
| **Application Layer** | Application Layer | 应用层 | 用例协调和业务流程 |
| **Presentation Layer** | Presentation Layer | 表现层 | UI和用户交互处理 |
| **Infrastructure Layer** | Infrastructure Layer | 基础设施层 | 外部依赖和技术实现 |
| **Dependency Inversion** | Dependency Inversion | 依赖倒置 | 高层不依赖低层的设计原则 |
| **Protocol-Oriented Programming** | Protocol-Oriented Programming | 面向协议编程 | Swift协议驱动的设计模式 |

### 3.2 现代化设计模式

| 术语 (中文) | 英文术语 | 设计模式 | 应用场景 |
|-------------|----------|----------|----------|
| **MVVM-C** | Model-View-ViewModel-Coordinator | MVVM-C模式 | SwiftUI应用架构 |
| **Repository Pattern** | Repository Pattern | 仓储模式 | 数据访问抽象层 |
| **Use Case Pattern** | Use Case Pattern | 用例模式 | 业务逻辑封装 |
| **Factory Pattern** | Factory Pattern | 工厂模式 | 对象创建抽象 |
| **Observer Pattern** | Observer Pattern | 观察者模式 | 数据变化通知 |
| **Coordinator Pattern** | Coordinator Pattern | 协调器模式 | 导航流程管理 |

## 4. 数据安全术语 (Data Security)

### 4.1 加密技术术语

| 术语 (中文) | 英文术语 | 技术实现 | 安全级别 |
|-------------|----------|----------|----------|
| **AES-256 Encryption** | AES-256 Encryption | AES-256对称加密 | 高敏感数据保护 |
| **End-to-End Encryption** | End-to-End Encryption | 端到端加密 | 传输过程数据保护 |
| **Keychain Services** | Keychain Services | 钥匙串服务 | 密钥安全存储 |
| **Secure Enclave** | Secure Enclave | 安全隔离区 | 硬件级安全存储 |
| **TLS 1.3** | Transport Layer Security 1.3 | 传输层安全协议 | 网络通信加密 |
| **Certificate Pinning** | Certificate Pinning | 证书绑定 | 防止中间人攻击 |

### 4.2 隐私保护术语

| 术语 (中文) | 英文术语 | 合规标准 | 实现方式 |
|-------------|----------|----------|----------|
| **COPPA Compliance** | COPPA Compliance | COPPA合规 | 13岁以下用户保护 |
| **GDPR Compliance** | GDPR Compliance | GDPR合规 | 欧盟数据保护法规 |
| **Data Classification** | Data Classification | 数据分类 | 高/中/低敏感度分级 |
| **Age-stratified Protection** | Age-stratified Protection | 年龄分层保护 | 不同年龄段的保护策略 |
| **Privacy by Design** | Privacy by Design | 隐私设计原则 | 系统设计阶段的隐私考虑 |
| **Data Minimization** | Data Minimization | 数据最小化 | 只收集必要的用户数据 |
| **Anonymization** | Anonymization | 数据匿名化 | 移除个人标识信息 |

## 5. 性能优化术语 (Performance Optimization)

### 5.1 内存管理术语

| 术语 (中文) | 英文术语 | 优化技术 | 目标指标 |
|-------------|----------|----------|----------|
| **Advanced Memory Management** | Advanced Memory Management | iOS 26内存管理 | <150MB内存使用 |
| **Automatic Reference Counting** | ARC (Automatic Reference Counting) | 自动引用计数 | 内存泄漏防护 |
| **Memory Pressure Monitoring** | Memory Pressure Monitoring | 内存压力监控 | 主动内存回收 |
| **Lazy Loading** | Lazy Loading | 延迟加载 | 减少初始内存占用 |
| **Image Caching** | Image Caching | 图片缓存 | 智能内存管理 |
| **Memory Pool** | Memory Pool | 内存池技术 | 频繁分配优化 |

### 5.2 性能监控术语

| 术语 (中文) | 英文术语 | 监控指标 | 目标值 |
|-------------|----------|----------|----------|
| **Launch Performance** | Launch Performance | 启动性能 | <0.8秒冷启动 |
| **Response Time** | Response Time | 响应时间 | <100ms核心交互 |
| **Frame Rate** | Frame Rate | 帧率 | >120fps滚动 |
| **CPU Usage** | CPU Usage | CPU使用率 | <30%正常使用 |
| **Network Efficiency** | Network Efficiency | 网络效率 | <20MB/月流量 |
| **Battery Optimization** | Battery Optimization | 电池优化 | <2%/小时耗电 |

## 6. DevOps与监控术语 (DevOps & Monitoring)

### 6.1 CI/CD术语

| 术语 (中文) | 英文术语 | 工具/平台 | 应用场景 |
|-------------|----------|----------|----------|
| **Continuous Integration** | Continuous Integration (CI) | GitHub Actions | 代码集成自动化 |
| **Continuous Deployment** | Continuous Deployment (CD) | Xcode Cloud | 自动化部署流程 |
| **Build Automation** | Build Automation | Fastlane | 构建过程自动化 |
| **Test Automation** | Test Automation | XCTest + XCUITest | 自动化测试执行 |
| **Code Quality Gates** | Code Quality Gates | SwiftLint + SonarQube | 代码质量检查 |
| **Performance Regression** | Performance Regression | XCTest Performance | 性能回归检测 |

### 6.2 可观测性术语

| 术语 (中文) | 英文术语 | 监控工具 | 监控内容 |
|-------------|----------|----------|----------|
| **Structured Logging** | Structured Logging | OSLog + JSON | 结构化日志记录 |
| **Distributed Tracing** | Distributed Tracing | 自定义TraceID | 分布式链路追踪 |
| **Real User Monitoring** | RUM (Real User Monitoring) | Analytics SDK | 真实用户行为监控 |
| **Crash Reporting** | Crash Reporting | Crashlytics | 崩溃日志收集 |
| **APM** | Application Performance Monitoring | 自定义APM | 应用性能监控 |
| **Health Checks** | Health Checks | 自定义检查 | 系统健康状态 |

## 7. Discovery社区技术术语 (Discovery Community Technologies)

### 7.1 社区架构术语

| 术语 (中文) | 英文术语 | 技术实现 | 隐私特性 |
|-------------|----------|----------|----------|
| **Content Moderation** | Content Moderation | AI+人工审核 | 内容安全保障 |
| **Anonymization Engine** | Anonymization Engine | 匿名化处理 | 个人信息移除 |
| **Community Forum** | Community Forum | 异步讨论系统 | 学科知识交流 |
| **Gamification System** | Gamification System | 激励机制 | 学习打卡奖励 |
| **Crowdsourced Content** | Crowdsourced Content | 众包内容 | 多解法贡献 |
| **Social Learning** | Social Learning | 社交学习 | 同龄人互助 |

### 7.2 内容安全术语

| 术语 (中文) | 英文术语 | 安全机制 | 保护对象 |
|-------------|----------|----------|----------|
| **Content Filtering** | Content Filtering | 内容过滤 | 不当内容拦截 |
| **Age Verification** | Age Verification | 年龄验证 | 未成年人保护 |
| **Parental Controls** | Parental Controls | 家长控制 | 社交功能管控 |
| **Abuse Detection** | Abuse Detection | 滥用检测 | 恶意行为识别 |
| **Report System** | Report System | 举报机制 | 社区自净能力 |

## 8. 测试技术术语 (Testing Technologies)

### 8.1 测试框架术语

| 术语 (中文) | 英文术语 | 测试框架 | 测试范围 |
|-------------|----------|----------|----------|
| **Swift Testing** | Swift Testing | Swift 6.2新测试框架 | 现代化单元测试 |
| **XCTest Framework** | XCTest Framework | 传统XCTest | 单元和集成测试 |
| **XCUITest** | XCUITest | UI自动化测试 | 端到端用户流程 |
| **Performance Testing** | Performance Testing | XCTest Performance | 性能基准测试 |
| **Snapshot Testing** | Snapshot Testing | 快照测试 | UI回归测试 |
| **Mock Testing** | Mock Testing | 模拟对象测试 | 依赖隔离测试 |

### 8.2 质量保证术语

| 术语 (中文) | 英文术语 | 质量指标 | 目标值 |
|-------------|----------|----------|----------|
| **Code Coverage** | Code Coverage | 代码覆盖率 | >80%单元测试 |
| **Test Pyramid** | Test Pyramid | 测试金字塔 | 70%单元+20%集成+10%UI |
| **Acceptance Criteria** | Acceptance Criteria | 验收标准 | 功能完成验证 |
| **Regression Testing** | Regression Testing | 回归测试 | 功能稳定性验证 |
| **Load Testing** | Load Testing | 负载测试 | 性能极限验证 |

## 9. 变更日志 (Change Log)

**v6.0 (2025-09-19)**: Swift 6.2 + iOS 26 前沿技术术语全面升级

- **Swift 6.2新特性**: Enhanced Actor Isolation、Improved TaskGroup、Enhanced Collections等
- **iOS 26平台特性**: Advanced Vision、Enhanced SwiftData、ProMotion Max、Device-side AI
- **现代架构模式**: Clean Architecture + Swift 6.2并发增强
- **安全隐私强化**: COPPA/GDPR合规、数据分类、年龄分层保护术语
- **Discovery社区**: 内容审核、匿名化、社交学习技术术语
- **性能优化**: 内存管理、监控指标、DevOps术语体系
- **测试技术**: Swift Testing新框架、质量保证术语

**v1.1 (2025-09-04)**: 基于PRD v4.0和TDD v4.0的基础技术术语 (已归档)

---

## 使用指南 (Usage Guidelines)

### 技术文档规范
1. **API文档**: 使用术语表中的标准英文术语
2. **代码注释**: 中英文对照，优先使用术语表术语
3. **架构图**: 统一使用术语表中的架构术语
4. **技术方案**: 引用术语表确保概念一致性

### 团队协作规范
1. **Code Review**: 检查是否使用标准术语
2. **技术讨论**: 基于术语表建立共同语言
3. **文档更新**: 新技术概念及时更新术语表
4. **培训材料**: 以术语表为基础编写培训内容

**维护责任**: 技术负责人维护术语一致性，架构师负责新技术术语定义
**更新频率**: 每个技术架构变更后同步更新
**最后更新**: 2025年9月19日 - 技术术语表v6.0前沿技术栈升级完成
