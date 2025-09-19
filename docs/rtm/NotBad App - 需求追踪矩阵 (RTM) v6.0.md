# NotBad App - 需求追踪矩阵 (RTM) v6.0

## 文档定位：需求→设计→测试双向追踪矩阵 (Bidirectional Traceability Matrix)

本文档建立PRD v6.0需求到TDD v6.0技术实现，再到测试用例的完整双向追踪关系，确保从产品需求到最终交付的端到端可追溯性。作为质量保证的核心工具，RTM确保所有需求都有对应的技术实现和测试验证。

## 文档治理与变更流程 (Document Governance)

- **从属关系**: RTM建立PRD→TDD→测试的双向追踪，不改变需求本身
- **更新触发**: PRD或TDD变更时，RTM必须同步更新追踪关系
- **版本同步**: RTM版本号与PRD、TDD保持一致，确保追踪准确性
- **质量保证**: 每个PRD需求必须有对应的TDD实现和测试用例

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md)
- TDD: [docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v6.0.md](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v6.0 (Swift6.2 + iOS26).md](../glossary/NotBad%20App%20-%20业务术语表%20v6.0%20(Swift6.2%20+%20iOS26).md)
- 技术术语表: [docs/glossary/NotBad App - 技术术语表 v6.0 (Swift6.2 + iOS26).md](../glossary/NotBad%20App%20-%20技术术语表%20v6.0%20(Swift6.2%20+%20iOS26).md)
- 术语→代码索引: [docs/glossary/NotBad App - 术语到代码索引 v6.0 (Swift6.2 + iOS26).md](../glossary/NotBad%20App%20-%20术语到代码索引%20v6.0%20(Swift6.2%20+%20iOS26).md)
- 附录A: [验收标准模板](../appendices/ACCEPTANCE_CRITERIA_TEMPLATE.md)
- 附录B: [分析事件规范](../appendices/ANALYTICS_EVENT_SPEC.md)
- 附录C: [指标对齐](../appendices/METRICS_ALIGNMENT.md)

| 版本 | 日期 | 作者 | 变更说明 | 状态 |
| :---- | :---- | :---- | :---- | :---- |
| v2.0 | 2025-09-03 | Product & Tech Team | 基于PRD v4.0和TDD v4.0的需求追踪 | 已归档 |
| **v6.0** | **2025-09-19** | **Product & Tech Team** | **🚀 全面升级至PRD v6.0和TDD v6.0，新增Discovery社区、iOS 26技术栈追踪** | ✅ **生效中** |

## 1. 核心功能需求追踪 (Core Feature Requirements Traceability)

### 1.1 错题录入模块 (Capture Module)

| PRD需求ID | 优先级 | 功能描述 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-UC-01** | Must | 拍照录入错题 | AC-UC-01: 启动相机<3秒，支持批量拍照 | OCRProcessor + VisionOCRService | TC-UC-001~005 | MVP Phase 1 | iOS 26 Camera, Vision Framework | Medium | ⏳ 待开发 |
| **F-UC-02** | Must | OCR文字识别 | AC-UC-02: 中文识别率>95%，数学公式>90% | EnhancedVisionOCRService | TC-UC-006~010 | MVP Phase 1 | iOS 26 Enhanced Vision | High | ⏳ 待开发 |
| **F-UC-03** | Should | 手动编辑校正 | AC-UC-03: OCR结果可编辑，支持富文本 | ReviewContentEditor | TC-UC-011~015 | MVP Phase 1 | SwiftUI Rich Text | Low | ⏳ 待开发 |
| **F-UC-04** | Should | 批量处理优化 | AC-UC-04: 支持50张图片批量处理 | BatchProcessor (Swift 6.2 TaskGroup) | TC-UC-016~020 | MVP Phase 2 | Enhanced TaskGroup | Medium | ⏳ 待开发 |

### 1.2 错题管理模块 (Management Module)

| PRD需求ID | 优先级 | 功能描述 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-BK-01** | Must | 分类体系管理 | AC-BK-01: 按学科、难度、掌握度分类 | CategoryManager + SwiftData | TC-BK-001~005 | MVP Phase 1 | iOS 26 SwiftData | Low | ⏳ 待开发 |
| **F-BK-02** | Must | 搜索功能 | AC-BK-02: 搜索响应<500ms，支持全文检索 | SearchEngine (Enhanced Collections) | TC-BK-006~010 | MVP Phase 1 | Swift 6.2 Collections | Medium | ⏳ 待开发 |
| **F-BK-03** | Should | 标签系统 | AC-BK-03: 自定义标签，支持多标签 | TagManager | TC-BK-011~015 | MVP Phase 2 | Core Data Relations | Low | ⏳ 待开发 |
| **F-BK-04** | Should | 统计分析 | AC-BK-04: 实时统计，数据可视化 | AnalyticsEngine | TC-BK-016~020 | MVP Phase 2 | Charts Framework | Medium | ⏳ 待开发 |

### 1.3 复习模块 (Review Module)

| PRD需求ID | 优先级 | 功能描述 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-RR-01** | Must | 卡片式复习 | AC-RR-01: 卡片加载<100ms，流畅滑动>120fps | StudySessionManager | TC-RR-001~005 | MVP Phase 1 | iOS 26 ProMotion Max | Medium | ⏳ 待开发 |
| **F-RR-02** | Must | 智能复习计划 | AC-RR-02: 基于遗忘曲线，个性化调整 | IntelligentScheduler | TC-RR-006~010 | MVP Phase 1 | AI Algorithms | High | ⏳ 待开发 |
| **F-RR-03** | Should | 重做功能 | AC-RR-03: 生成空白模板，验证掌握度 | RedoTemplateGenerator | TC-RR-011~015 | MVP Phase 2 | Image Processing | Medium | ⏳ 待开发 |
| **F-RR-04** | Should | 进度跟踪 | AC-RR-04: 复习次数、正确率统计 | ProgressTracker | TC-RR-016~020 | MVP Phase 2 | Analytics Core | Low | ⏳ 待开发 |

## 2. 新增功能需求追踪 (New Feature Requirements Traceability)

### 2.1 Discovery社区模块 (Discovery Community)

| PRD需求ID | 优先级 | 功能描述 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-DS-01** | Should | 错题分享 | AC-DS-01: 匿名分享，按学科分类 | DiscoveryPostManager | TC-DS-001~005 | MVP Phase 2 | CloudKit Public | Medium | ⏳ 待开发 |
| **F-DS-02** | Should | 智慧众包 | AC-DS-02: 多种解法，AI筛选优质内容 | ContentModerationService | TC-DS-006~010 | MVP Phase 2 | Local AI + Cloud | High | ⏳ 待开发 |
| **F-DS-03** | Should | 学习打卡 | AC-DS-03: 每日进度分享，激励机制 | SocialProgressTracker | TC-DS-011~015 | MVP Phase 2 | Gamification | Low | ⏳ 待开发 |
| **F-DS-04** | Should | 互助问答 | AC-DS-04: 学科知识点讨论，同龄人互助 | CommunityForumService | TC-DS-016~020 | MVP Phase 3 | Moderation System | Medium | ⏳ 待开发 |
| **F-DS-05** | Must | 隐私保护 | AC-DS-05: 完全匿名化，年龄分层控制 | PrivacyProtectionService | TC-DS-021~025 | MVP Phase 1 | COPPA/GDPR | High | ⏳ 待开发 |

### 2.2 云同步模块 (Cloud Sync)

| PRD需求ID | 优先级 | 功能描述 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-SY-01** | Must | iCloud同步 | AC-SY-01: 同步成功率>99.9%，支持冲突解决 | EnhancedCloudKitService | TC-SY-001~005 | MVP Phase 1 | iOS 26 CloudKit | High | ⏳ 待开发 |
| **F-SY-02** | Must | 多设备支持 | AC-SY-02: iPhone/iPad同步，实时增量 | SyncCoordinator | TC-SY-006~010 | MVP Phase 1 | Device Registration | Medium | ⏳ 待开发 |
| **F-SY-03** | Should | 数据备份 | AC-SY-03: 自动备份，支持恢复 | BackupManager | TC-SY-011~015 | MVP Phase 2 | iCloud Storage | Low | ⏳ 待开发 |
| **F-SY-04** | Should | 离线处理 | AC-SY-04: 100%离线可用，网络恢复自动同步 | OfflineQueueManager | TC-SY-016~020 | MVP Phase 1 | Local Storage | Medium | ⏳ 待开发 |

## 3. 非功能性需求追踪 (Non-Functional Requirements Traceability)

### 3.1 性能需求 (Performance Requirements)

| PRD需求ID | 优先级 | 性能指标 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **NF-PERF-01** | Must | 应用启动时间 | AC-PERF-01: 冷启动<0.8秒 | Swift 6.2 优化启动流程 | TC-PERF-001~005 | MVP Phase 1 | iOS 26 优化 | High | ⏳ 待开发 |
| **NF-PERF-02** | Must | 内存使用 | AC-PERF-02: 正常使用<150MB | MemoryManager | TC-PERF-006~010 | MVP Phase 1 | iOS 26 Memory | Medium | ⏳ 待开发 |
| **NF-PERF-03** | Must | 响应时间 | AC-PERF-03: 核心交互<100ms | Enhanced Actor Pattern | TC-PERF-011~015 | MVP Phase 1 | Swift 6.2 Concurrency | Medium | ⏳ 待开发 |
| **NF-PERF-04** | Should | 滚动流畅度 | AC-PERF-04: 列表滚动>120fps | ProMotion Max 优化 | TC-PERF-016~020 | MVP Phase 2 | iOS 26 Display | Low | ⏳ 待开发 |
| **NF-PERF-05** | Must | OCR准确率 | AC-PERF-05: 中文>95%，数学公式>90% | Enhanced Vision Framework | TC-PERF-021~025 | MVP Phase 1 | iOS 26 Vision | High | ⏳ 待开发 |

### 3.2 安全隐私需求 (Security & Privacy Requirements)

| PRD需求ID | 优先级 | 安全要求 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **NF-SEC-01** | Must | 数据加密 | AC-SEC-01: AES-256本地加密，TLS 1.3传输 | EncryptionService | TC-SEC-001~005 | MVP Phase 1 | CryptoKit | Medium | ⏳ 待开发 |
| **NF-SEC-02** | Must | 未成年人保护 | AC-SEC-02: COPPA/GDPR合规，年龄分层 | ComplianceManager | TC-SEC-006~010 | MVP Phase 1 | Legal Framework | High | ⏳ 待开发 |
| **NF-SEC-03** | Must | 数据分类保护 | AC-SEC-03: 高/中/低敏感度分级保护 | DataClassificationService | TC-SEC-011~015 | MVP Phase 1 | Privacy Framework | High | ⏳ 待开发 |
| **NF-SEC-04** | Should | 访问控制 | AC-SEC-04: Face ID/Touch ID认证，细粒度授权 | BiometricAuthService | TC-SEC-016~020 | MVP Phase 2 | LocalAuthentication | Medium | ⏳ 待开发 |

## 4. 商业模式需求追踪 (Business Model Requirements Traceability)

### 4.1 付费功能 (Premium Features)

| PRD需求ID | 优先级 | 商业功能 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **F-PM-01** | Should | Premium订阅 | AC-PM-01: ¥10/月或¥100/年，无限录入 | SubscriptionManager | TC-PM-001~005 | MVP Phase 2 | StoreKit 2 | Medium | ⏳ 待开发 |
| **F-PM-02** | Should | 免费额度控制 | AC-PM-02: 1500题/月免费，超出提示升级 | QuotaService | TC-PM-006~010 | MVP Phase 2 | Local Counter | Low | ⏳ 待开发 |
| **F-PM-03** | Should | 云端高级分析 | AC-PM-03: Premium用户AI深度分析 | PremiumAnalyticsService | TC-PM-011~015 | MVP Phase 3 | Cloud AI API | High | ⏳ 待开发 |
| **F-PM-04** | Should | 家长协作(vNext) | AC-PM-04: Premium功能，推迟至vNext | ParentCollaborationService | TC-PM-016~020 | vNext | Parent System | Medium | 🚫 已推迟 |

## 5. 技术架构需求追踪 (Technical Architecture Requirements Traceability)

### 5.1 Swift 6.2 & iOS 26 技术栈

| PRD需求ID | 优先级 | 技术要求 | 验收标准 | TDD技术实现 | 测试用例ID | 交付阶段 | 依赖 | 风险等级 | 实现状态 |
|-----------|--------|----------|----------|-------------|------------|----------|-----|----------|----------|
| **NF-TECH-01** | Must | Swift 6.2并发模型 | AC-TECH-01: 100%编译时并发安全 | Enhanced Actor Isolation | TC-TECH-001~005 | MVP Phase 1 | Swift 6.2 | High | ⏳ 待开发 |
| **NF-TECH-02** | Must | iOS 26兼容性 | AC-TECH-02: 充分利用iOS 26新特性 | iOS 26 Feature Adoption | TC-TECH-006~010 | MVP Phase 1 | iPhone 15 Pro+ | Medium | ⏳ 待开发 |
| **NF-TECH-03** | Should | Enhanced Collections | AC-TECH-03: 高性能搜索和排序 | SearchEngine Optimization | TC-TECH-011~015 | MVP Phase 1 | Swift 6.2 Collections | Medium | ⏳ 待开发 |
| **NF-TECH-04** | Must | SwiftData现代化 | AC-TECH-04: 充分利用SwiftData新特性 | PersistenceController v6.0 | TC-TECH-016~020 | MVP Phase 1 | iOS 26 SwiftData | Low | ⏳ 待开发 |

## 6. 分阶段交付映射 (Phased Delivery Mapping)

### 6.1 MVP Phase 1 (Week 1-6) - 核心功能

| 交付目标 | 包含需求 | 验收标准 | 风险评估 |
|----------|----------|----------|----------|
| **基础录入与管理** | F-UC-01, F-UC-02, F-BK-01, F-BK-02 | 拍照录入可用，OCR准确率>90% | Medium |
| **离线复习系统** | F-RR-01, F-RR-02, F-SY-04 | 卡片复习流畅，100%离线可用 | Low |
| **性能基线** | NF-PERF-01~03, NF-PERF-05 | 启动<0.8s，内存<150MB | High |
| **安全合规基础** | NF-SEC-01~03, F-DS-05 | 数据加密，COPPA合规 | High |

### 6.2 MVP Phase 2 (Week 7-10) - 增强功能

| 交付目标 | 包含需求 | 验收标准 | 风险评估 |
|----------|----------|----------|----------|
| **Discovery社区** | F-DS-01~03 | 匿名分享，内容审核可用 | Medium |
| **云端同步** | F-SY-01~03 | 多设备同步，成功率>99% | High |
| **Premium功能** | F-PM-01~02 | 订阅系统，配额控制 | Medium |
| **高级分析** | F-BK-04, F-RR-04 | 统计分析，进度跟踪 | Low |

### 6.3 MVP Phase 3 (Week 11-14) - 生产就绪

| 交付目标 | 包含需求 | 验收标准 | 风险评估 |
|----------|----------|----------|----------|
| **社区完善** | F-DS-04, F-PM-03 | 互助问答，Premium分析 | Medium |
| **性能优化** | NF-PERF-04, F-UC-04 | 120fps滚动，批量处理 | Low |
| **安全加固** | NF-SEC-04 | 生物识别，访问控制 | Medium |
| **发布准备** | 所有测试用例通过 | App Store就绪 | Low |

## 7. 依赖关系与风险管理 (Dependencies & Risk Management)

### 7.1 关键技术依赖

| 依赖项 | 风险等级 | 影响范围 | 缓解策略 | 负责人 |
|--------|----------|----------|----------|--------|
| **Swift 6.2兼容性** | High | 整体架构 | 早期原型验证，保留Xcode 15降级方案 | Tech Lead |
| **iOS 26新特性** | Medium | 性能优化 | 渐进式采用，核心功能保持兼容 | iOS Team |
| **Enhanced Vision OCR** | High | 核心功能 | 多算法备选，人工校正机制 | AI Team |
| **CloudKit配额限制** | Medium | 数据同步 | 配额监控，压缩优化，降级策略 | Backend Team |

### 7.2 业务风险评估

| 风险项 | 概率 | 影响程度 | 风险等级 | 应对措施 |
|--------|------|----------|----------|----------|
| **用户接受度** | Medium | High | High | MVP快速验证，用户反馈驱动迭代 |
| **竞品压力** | High | Medium | Medium | 技术差异化，用户体验优势 |
| **隐私合规变化** | Low | High | Medium | 法务团队持续跟踪，预留合规余量 |
| **设备覆盖率限制** | Medium | Medium | Medium | 20-30%早期采用者足够验证 |

## 8. 质量保证追踪 (Quality Assurance Traceability)

### 8.1 测试覆盖率要求

| 测试类型 | 覆盖率目标 | 关联需求 | 自动化程度 |
|----------|------------|----------|------------|
| **单元测试** | >80% | Domain层所有业务逻辑 | 100%自动化 |
| **集成测试** | >70% | Application→Infrastructure交互 | 90%自动化 |
| **UI测试** | >60% | 核心用户流程 | 80%自动化 |
| **性能测试** | 100% | 所有性能指标 | 100%自动化 |

### 8.2 关键测试场景

| 测试场景 | 优先级 | 验收标准 | 自动化状态 |
|----------|--------|----------|------------|
| **启动性能** | P0 | <0.8秒冷启动 | ✅ 自动化 |
| **OCR准确率** | P0 | 中文>95%，数学>90% | ✅ 自动化 |
| **并发安全** | P0 | 无数据竞争，无死锁 | ✅ 自动化 |
| **内存泄漏** | P0 | 长时间使用无内存增长 | ✅ 自动化 |
| **网络异常** | P1 | 离线模式正常工作 | ⏳ 计划中 |

## 9. 变更日志 (Change Log)

**v6.0 (2025-09-19)**: 全面升级至PRD v6.0和TDD v6.0追踪体系
- **新增Discovery社区**: 完整的匿名分享和内容审核追踪
- **技术栈升级**: iOS 26+ Swift 6.2全面追踪
- **性能指标对齐**: 启动0.8s、内存150MB等严格指标
- **隐私保护强化**: COPPA/GDPR合规追踪
- **商业模式简化**: 单一Premium订阅模式追踪
- **分阶段交付**: 14周完整交付计划映射
- **风险管理**: 技术和业务风险完整评估体系

**v2.0 (2025-09-03)**: 基于PRD v4.0和TDD v4.0的基础追踪矩阵 (已归档)

---

## 追踪状态说明 (Traceability Status)

- ✅ **已完成**: 功能已实现并通过测试验证
- ⏳ **待开发**: 需求已明确，等待技术实现
- 🔍 **测试中**: 技术实现完成，质量验证中
- ❌ **被阻塞**: 存在技术或业务依赖阻塞
- 🚫 **已推迟**: 推迟至vNext版本实现
- 📝 **需求变更**: 需要重新评估或调整

**统计数据**:
- 总需求数: 35个 (核心17个，新增8个，非功能6个，商业4个)
- MVP Phase 1: 18个需求 (51%)
- MVP Phase 2: 12个需求 (34%)
- MVP Phase 3: 5个需求 (15%)
- 高风险需求: 8个 (23%)

**更新频率**: 每Sprint结束后更新一次实现状态
**维护责任**: 产品经理维护需求追踪，技术负责人确认实现状态，QA负责人维护测试状态

**最后更新**: 2025年9月19日 - RTM v6.0需求追踪矩阵建立完成
