# **NotBad App \- 技术术语表 v1.1**

**目的**: 本文档面向**开发、测试、运维**角色，定义核心技术概念、架构、规范，是确保技术团队高效协作的**唯一事实来源**。

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v4.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v4.0.md)
- TDD: [docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v4.0.md](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v4.0.md)
- RTM: [docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v2.0.md](../rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v2.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v1.1.md](NotBad%20App%20-%20业务术语表%20v1.1.md)
- 术语→代码索引: [docs/glossary/NotBad App - 术语到代码索引 v1.0.md](NotBad%20App%20-%20术语到代码索引%20v1.0.md)

| 版本 | 日期 | 作者 | 变更说明 |
| :---- | :---- | :---- | :---- |
| v1.1 | 2025-09-04 | Team | 同步 PRD/TDD v4.0：新增 Metrics/Teacher/Parent 服务与 Quota Monitoring 术语 |

## **1\. 技术架构术语**

| 术语 (中文) | 英文术语 (English Term) | 技术实现 |
| :---- | :---- | :---- |
| **洁净架构** | Clean Architecture | 四层分离：Presentation, Application, Domain, Infrastructure |
| **领域层** | Domain Layer | Swift结构体和协议 |
| **应用层** | Application Layer | UseCase类和Service协调 |
| **基础设施层** | Infrastructure Layer | SwiftData, CloudKit, Vision等 |
| **依赖注入容器** | Dependency Injection (DI) Container | ServiceContainer单例 |
| **架构决策记录** | Architecture Decision Record (ADR) | Markdown文档 |
| **ADR-002 (Cloud Sync)** | ADR-002: Cloud Sync | 待创建：记录 CloudKit vs 自建后端决策 |
| **ADR-003 (OCR 引擎)** | ADR-003: OCR Engine | 待创建：记录 OCR 引擎选型与性能评估 |

## **2\. 数据管理术语**

| 术语 (中文) | 英文术语 (English Term) | 存储位置/技术 |
| :---- | :---- | :---- |
| **本地存储** | Local Storage | SwiftData数据库 |
| **云端同步** | Cloud Sync | CloudKit私有数据库 |
| **数据迁移** | Data Migration | SwiftData迁移计划 |
| **冲突解决** | Conflict Resolution | Last-Write-Wins \+ 用户选择 |
| **数据脱敏** | Data Anonymization / Masking | 应用层过滤 |
| **CloudKit 配额监控** | CloudKit Quota Monitoring | 监控每日/每用户存储与API调用速率，触发降级/告警 |

## **3\. 质量保证术语**

| 术语 (中文) | 英文术语 (English Term) | 测试方法/工具 |
| :---- | :---- | :---- |
| **验收标准** | Acceptance Criteria (AC) | 功能测试 \+ 用户验证 |
| **单元测试** | Unit Test | XCTest框架 |
| **集成测试** | Integration Test | 模拟依赖测试 |
| **UI测试** | UI Test | XCUITest |
| **性能测试** | Performance Test | XCTest性能监控 |
| **代码覆盖率** | Code Coverage | Xcode Code Coverage |
| **持续集成** | Continuous Integration (CI) | GitHub Actions |

## **新增：指标与分析服务术语**
| 术语 (中文) | 英文术语 (English Term) | 技术实现/说明 |
| :---- | :---- | :---- |
| **指标计算器** | MetricsCalculator | 计算 L1/MARU, L2/MRU, L3/MMU 的服务接口（见 TDD） |
| **埋点事件** | Analytics Event | 事件枚举与 schema（例如 item_marked_mastered, parent_access_revoked） |

## **新增：教师/家长服务术语**
| 术语 (中文) | 英文术语 (English Term) | 技术实现/说明 |
| :---- | :---- | :---- |
| **班级管理服务** | ClassManagementService | 管理班级创建、邀请、作业分发与匿名统计（CloudKit 或 ServerRepository） |
| **家长访问服务** | ParentAccessService | 管理家长申请/授权/撤销与审计日志，必须支持本地即时生效并异步同步 |

## **4\. 错误处理与异常**

| 术语 (中文) | 英文术语 (English Term) | 错误类型 |
| :---- | :---- | :---- |
| **配额超限错误** | Quota Exceeded Error | QuotaError |
| **OCR识别失败** | OCR Failure Error | OCRError |
| **网络连接异常** | Network Error | NetworkError |
| **数据同步冲突** | Sync Conflict Error | SyncConflictError |

## **5\. 安全与隐私**

| 术语 (中文) | 英文术语 (English Term) | 技术实现 |
| :---- | :---- | :---- |
| **端到端加密** | End-to-End Encryption (E2EE) | AES-256加密算法 |
| **本地优先** | Local-First | 离线算法 \+ 本地数据库 |
| **儿童隐私合规** | COPPA Compliance | 家长同意 \+ 数据最小化 |
| **访问控制** | Access Control | 权限验证 \+ 访问日志 |

## **6\. 性能与监控**

| 术语 (中文) | 英文术语 (English Term) | 测量指标 |
| :---- | :---- | :---- |
| **应用启动时间** | App Launch Time | 冷启动、热启动时间 |
| **崩溃率** | Crash Rate | 崩溃次数/启动次数×100% |
| **帧率** | Frames Per Second (FPS) | 每秒渲染帧数 |
| **可观测性** | Observability | 日志(Logs), 指标(Metrics), 追踪(Traces) |

## **7\. 版本演进**
\
---
### **编辑历史 / 贡献者 (Edit History & Contributors)**

| 日期 | 版本 | 主要变更 | 贡献者 |
| :---- | :---- | :---- | :---- |
| 2025-09-10 | v1.1+auto | 脚本验证插入示例 | Docs Maintainer |
| 2025-09-02 | v1.0 | 初版技术术语 / 架构分类 | Tech Team |
| 2025-09-04 | v1.1 | 增加 MetricsCalculator / 服务接口术语 / Quota Monitoring | Tech Team |
| 2025-09-10 | v1.1+links | 添加跨文档快速跳转 & 编辑历史 | Docs Maintainer |

> 大规模架构术语或协议列表调整时，请与 ADR 同步并升级版本号。


| 术语 (中文) | 英文术语 (English Term) | 定义 |
| :---- | :---- | :---- |
| **向下兼容** | Backward Compatibility | 新版本支持旧版本的数据和功能。 |
| **破坏性变更** | Breaking Change | 不兼容旧版本的功能修改。 |
| **特性开关** | Feature Flag / Toggle | 可动态开关的功能控制机制。 |
| **灰度发布** | Canary Release / Gradual Rollout | 分批次逐步扩大发布范围。 |

