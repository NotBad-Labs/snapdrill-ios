# **NotBad 错题本 App \- 技术设计文档 (TDD) v4.0**

**文档定位：技术实现单一事实来源 (Single Source of Truth for Implementation)**

本文档基于 [**PRD v4.0**](https://www.google.com/search?q=./notbad_prd_v4.0.md) 的产品需求，为NotBad App的技术实现提供了唯一的、权威的、详尽的蓝图。它是开发、测试及运维团队的**核心行动纲领**，定义了应用的架构设计、模块职责、接口契約、数据结构和非功能性实现方案。

| 版本 | 日期 | 作者 | 变更说明 | 状态 |
| :---- | :---- | :---- | :---- | :---- |
| v3.1 | 2025-09-02 | Tech Team | 基于初步评审意见进行优化 | 已归档 |
| **v4.0** | **2025-09-03** | **Tech Team** | **综合全部评审意见，扩展所有章节，升级为技术实现“单一事实来源”版本** | ✅ **生效中** |

## **1\. 技术概述 (Technical Overview)**

### **1.1 技术目标 (Technical Goals)**

构建一个高性能、高可靠、可扩展且易于维护的iOS原生应用，严格承接PRD v4.0中定义的所有功能性及非功能性需求，确保：

* **性能卓越**: 满足所有性能指标（启动\<2s, 核心响应\<3s, 列表滚动\>58fps）。  
* **数据安全**: 实现端到端加密，完全符合COPPA和GDPR隐私合规要求。  
* **极致可靠**: 核心功能100%离线可用，崩溃率低于0.1%。  
* **架构优雅**: 通过Clean Architecture实现高度的可测试性和可维护性。

### **1.3 与 PRD v4.0 的技术影响 (PRD sync notes)**

以下为最近 PRD v4.0 更新中涉及到的要点及对本技术设计的直接影响：

- 订阅定价调整（月 ¥10 / 年 ¥99 / 永久 ¥688）本身为产品/商业层面的变更，对客户端实现影响有限，但会影响我们对“Pro”特性的优先级与云端资源分配策略。
- PRD 明确将“基础 iCloud 同步”对所有用户免费开放——因此本版本的同步实现以 **CloudKit/ iCloud 为基础方案**（无额外自建后端成本），并在 TDD 中保留对“高级同步”（多平台、历史版本、实时协同）需要自建后端的说明与扩展接口。 
- PRD 中关于 AI 与家长协同的增加，意味着 **云端 AI 调用（例如 Gemini 或第三方模型）应当视为增值能力**：若决定将部分 AI 能力作为 Pro 权益，需要在后端或第三方API上实现配额/鉴权与计费，并在本地实现健壮的脱网降级策略（CoreML）。
- PRD 明确了 MVP 的 Must Have 功能集，TDD 将这些功能列为实现与测试优先级（见第6章测试策略）。

技术团队需与产品/运营沟通：确认哪些 Pro-only 的AI/分析能力将调用云端服务、预估调用量与成本，以便在CI/CD 和成本模型中反映这些依赖。

### **1.2 架构决策记录 (ADR)**

本项目的关键技术决策均通过**架构决策记录 (ADR)** 进行系统性存档。ADR旨在理解决策背景、评估备选方案并追踪决策后果。

* [**ADR-001: 本地持久化框架选型**](https://www.google.com/search?q=./architecture_decision_record_template.md)  
* [**ADR-002: 云同步方案选型**](https://www.google.com/search?q=./adr_cloud_sync.md) (待创建)  
* [**ADR-003: OCR引擎选型**](https://www.google.com/search?q=./adr_ocr_engine.md) (待创建)

## **2\. 系统架构设计 (System Architecture)**

### **2.1 架构原则 (Architecture Principles)**

* **Clean Architecture**: 严格分层，依赖倒置。领域层是核心，不依赖任何外部实现。  
* **接口驱动设计 (Protocol-Oriented)**: 模块间通过协议（Protocol）通信，而非具体实现，实现高度解耦。  
* **本地优先 (Local-First)**: 用户数据首先在设备本地进行处理和存储，网络仅用于同步，确保离线可用性和响应速度。  
* **SOLID原则**: 遵循单一职责、开闭、里氏替换、接口隔离和依赖倒置原则。

### **2.2 分层架构图 (Layered Architecture)**

┌─────────────────────────────────────┐  
│           Presentation Layer (MVVM-C)        │  
│    (SwiftUI Views, ViewModels, Coordinators)   │  
├─────────────────────────────────────┤  
│           Application Layer                  │  
│      (Use Cases / Interactors)             │  
├─────────────────────────────────────┤  
│             Domain Layer                     │  
│   (Entities, Value Objects, Repository Protocols)  │  
├─────────────────────────────────────┤  
│          Infrastructure Layer                │  
│  (SwiftData, CloudKit, Vision, Networking, Analytics)│  
└─────────────────────────────────────┘

## **3\. 数据设计 (Data Design)**

### **3.1 核心数据模型 (Core Data Models)**

领域层的核心实体定义如下，它们是纯粹的Swift结构体，不包含任何持久化逻辑。

// Domain/Entities/ReviewItem.swift  
struct ReviewItem {  
    let id: UUID  
    var content: ReviewContent  
    var metadata: ReviewMetadata  
    var studyHistory: \[StudyRecord\]  
    var masteryLevel: MasteryLevel  
}  
// ... 其他实体定义

### **3.2 数据持久化 (Data Persistence)**

* **本地存储**: 采用**SwiftData**实现本地持久化。具体实现封装在Infrastructure层，遵循Domain层定义的ReviewItemRepository协议。  
* **数据加密**: 所有存储在SwiftData中的用户内容字段，在写入前必须通过EncryptionService进行AES-256加密。图片等二进制文件在保存到文件系统前也需加密。

### **3.3 数据迁移与回滚 (Data Migration & Rollback)**

* **迁移策略**:  
  1. **版本控制**: 使用SchemaMigrationPlan管理SwiftData模型版本。  
  2. **轻量级迁移**: 优先使用自动迁移。  
  3. **重量级迁移**: 复杂的数据模型变更（如字段拆分、合并），需编写自定义迁移逻辑，并进行充分测试。  
* **回滚方案**:  
  1. **强制备份**: 在执行任何重量级迁移前，App必须自动为用户的本地数据库创建一个加密备份。  
  2. **失败处理**: 若迁移过程失败，App应能引导用户从备份中恢复数据，并将失败日志上传至监控系统。  
  3. **版本兼容**: 新版本App必须能兼容至少前两个主版本的数据库模型。

## **4\. 接口契约规范 (API Contracts)**

所有模块间及与外部服务的交互，均需遵循以下接口契约。

### **4.1 内部服务接口 (Internal Service Contracts)**

#### **4.1.1 OCR服务接口**

* **协议**: OCRService  
* **实现**: VisionOCRService (位于Infrastructure层)  
* **性能约束**: P95（95%的请求）响应时间 \< 2秒。  
* **错误定义**:  
  * OCRError.invalidImage: 输入图像格式无效或损坏。  
  * OCRError.lowConfidence(confidence: Double): 识别结果置信度低于85%。

#### **4.1.2 AI分析服务接口**

* **协议**: AIAnalysisService  
* **实现**: HybridAIService (根据用户类型和网络状态，动态选择本地CoreML或云端Gemini)  
* **业务规则**:  
  * Pro用户优先使用云端API，有每日调用配额。  
  * 云端服务失败或免费用户，自动降级至本地模型。  
* **性能约束**: P95响应时间 \< 1秒 (本地), \< 5秒 (云端)。

### **4.2 数据同步接口 (Data Sync Contract)**

* **协议**: SyncService  
* **实现**: CloudKitSyncService  
* **同步规则**:  
  * **触发时机**: 应用启动、从后台返回、本地数据发生变更后。  
  * **冲突解决**: 默认策略为“最后写入获胜(Last-Write-Wins)”。对于复杂冲突，将标记数据并提示用户手动选择保留哪个版本。  
* **错误处理**:  
  * SyncError.authError: iCloud账户认证失败，引导用户检查系统设置。  
  * SyncError.networkError: 网络不可达，自动转入离线模式，待网络恢复后重试。

### **4.3 通用错误码规范**

| 业务错误码 | 含义 | 用户提示 | 日志级别 |
| :---- | :---- | :---- | :---- |
| 1001 | 无效请求参数 | "请求失败，请稍后重试" | WARN |
| 1002 | 未授权/需要登录 | "请先登录iCloud账户" | INFO |
| 2001 | 配额超限 | "使用次数已达上限，请升级Pro" | INFO |
| 9999 | 未知服务器错误 | "服务暂时不可用，请稍后重试" | ERROR |

## **5\. 安全与隐私设计 (Security & Privacy by Design)**

### **5.1 数据加密实现**

* **密钥管理**: 每个用户的加密密钥（SymmetricKey）独立生成，并安全地存储在设备的**Keychain**中。密钥永不离开设备。  
* **加密流程**:  
  * 文本数据: String \-\> Data \-\> AES.GCM.seal \-\> EncryptedData \-\> SwiftData  
  * 图片数据: Data \-\> AES.GCM.seal \-\> EncryptedData \-\> File System

### **5.2 隐私合规技术方案**

* **COPPA合规**:  
  1. **年龄闸门**: App首次启动时，必须显示年龄选择界面。  
  2. **13岁以下用户**: 若用户选择年龄\<13岁，必须跳转至家长同意流程。在该流程完成前，禁用所有第三方分析SDK，并将dataCollectionLevel设为.minimal。  
* **GDPR合规**:  
  1. **数据导出**: 在设置中提供“导出我的数据”功能，该功能会查询所有本地数据，并生成一个加密的、标准格式（如JSON）的数据包。  
  2. **账户删除**: 提供“删除账户”功能，该功能将：(1) 删除所有本地数据库和文件；(2) 向CloudKit发送删除该用户所有记录的指令；(3) 清理Keychain中的密钥。此操作不可逆。

## **6\. 质量保证与测试策略 (QA & Testing Strategy)**

### **6.1 测试金字塔 (Testing Pyramid)**

* **单元测试 (70%)**: 使用XCTest，覆盖Domain层和Application层的所有业务逻辑，代码覆盖率目标 \> 80%。  
* **集成测试 (20%)**: 测试Application层与Infrastructure层实现的交互，例如Use Case调用真实的SwiftData Repository。  
* **UI/E2E测试 (10%)**: 使用XCUITest，覆盖PRD中定义的核心用户故事（US-101, US-201等），确保端到端流程正确。

### **6.2 Gherkin AC 到自动化测试**

PRD中的每个Gherkin格式验收标准（AC），都必须有一个或多个对应的自动化测试用例。

* **PRD AC**: 鉴于 用户在主界面 当 用户点击“拍照创建”... 那么 系统应在3秒内进入...  
* **XCUITest映射**:  
  // TC\_AC\_101\_1\_PerformanceTest.swift  
  func testLaunchToEditScreenPerformance() {  
      let app \= XCUIApplication()  
      app.launch()  
      let start \= Date()  
      app.buttons\["createNewItemButton"\].tap()  
      app.buttons\["capturePhotoButton"\].tap()  
      XCTAssertTrue(app.otherElements\["editScreen"\].waitForExistence(timeout: 3.0))  
      let duration \= Date().timeIntervalSince(start)  
      XCTAssertLessThanOrEqual(duration, 3.0)  
  }

### **6.3 性能测试计划**

* **测试场景**: 应用冷启动、大数据量列表滚动、批量OCR处理。  
* **测试工具**: XCTest自带的measure{}、Instruments (Time Profiler, Leaks)。  
* **回归标准**: CI流程中会运行性能基准测试，任何导致核心指标（如启动时间）劣化超过10%的合并请求将被阻止。

## **7\. DevOps与可观测性 (DevOps & Observability)**

### **7.1 CI/CD 管道**

* **工具**: GitHub Actions。  
* **流程**:  
  1. **每次提交**: 运行SwiftLint、编译、单元测试。  
  2. **创建PR时**: 额外运行集成测试、代码覆盖率检查。  
  3. **合并到主干**: 额外运行UI测试、性能基准测试，并自动打包构建提交至TestFlight。

### **7.2 可观测性体系 (Observability)**

* **日志 (Logging)**:  
  * **规范**: 所有日志必须为**结构化JSON格式**，包含traceID, userID, module等字段。  
  * **级别**: DEBUG, INFO, WARN, ERROR。生产环境默认只上报INFO及以上级别。  
* **指标 (Metrics)**:  
  * **业务指标**: WAIC、CVR等，通过分析服务上报。  
  * **性能指标**: P99/P95响应延迟、启动耗时、崩溃率，通过Sentry等工具收集。  
* **追踪 (Tracing)**: 对于关键的用户流程（如复习项创建），实现分布式追踪，连接从UI操作到后台处理再到数据同步的完整链路。  
* **报警 (Alerting)**:  
  * **P0级报警** (崩溃率 \> 1%): 电话、短信、Slack通知On-Call工程师，要求5分钟内响应。  
  * **P1级报警** (核心API成功率 \< 99%): Slack @channel 通知，要求30分钟内响应。

## **8\. 附录 (Appendix)**

* [**PRD v4.0**](https://www.google.com/search?q=./notbad_prd_v4.0.md)  
* [**需求追踪矩阵 (RTM)**](https://www.google.com/search?q=./rtm_matrix.md)  
* [**技术术语表**](https://www.google.com/search?q=./technical_glossary.md)