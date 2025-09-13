# **NotBad App \- 需求追踪矩阵 (RTM) v2.0**

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v4.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v4.0.md)
- TDD: [docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v4.0.md](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v4.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v1.1.md](../glossary/NotBad%20App%20-%20业务术语表%20v1.1.md)
- 技术术语表: [docs/glossary/NotBad App - 技术术语表 v1.1.md](../glossary/NotBad%20App%20-%20技术术语表%20v1.1.md)
- 术语→代码索引: [docs/glossary/NotBad App - 术语到代码索引 v1.0.md](../glossary/NotBad%20App%20-%20术语到代码索引%20v1.0.md)

| 用户故事ID (PRD) | 优先级 | 用户故事 | 验收标准 | TDD技术实现 | 计划Sprint | 依赖 | 风险 (等级) | 测试用例ID | 实现状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **US-101** | Must | 快速拍照录入与OCR | AC-101.1: <3秒进入编辑<br>AC-101.2: 智能裁剪 | CreateReviewItemUseCase, VisionOCRService | Sprint 1 | Camera, Vision | High | TC-001-010 | ⏳ 待开发 |
| **US-102** | Could | 智能分类与打标签 | AC-102.1: 自动学科分类<br>AC-102.2: 推荐知识点标签 | LearningAnalysisService (Local Rules) | Sprint 2 | CoreML | Low | TC-011-015 | ⏳ 待开发 |
| **US-201** | Must | 专注复习模式 | AC-201.1: 沉浸式体验<br>AC-201.2: 手势操作 | StudySessionUseCase | Sprint 1 | SwiftData, SwiftUI | Low | TC-016-020 | ⏳ 待开发 |
| **US-202** | Must | 错题重做 | AC-202.1: 提供并排重做视图 | ReviewItemRedoService | Sprint 2 | SwiftUI | Low | TC-021-025 | ⏳ 待开发 |
| **US-301** | Should | 家长模式（统计查看与授权） | AC-301.1: 隐私保护<br>AC-301.2: 查看授权 | ParentAccessService | Sprint 2 | CloudKit, Analytics | Medium | TC-026-030 | ⏳ 待开发 |
| **US-402** | Must | 数据恢复 (iCloud) | AC-402.1: 新设备恢复数据 | CloudKitSyncService | Sprint 1 | iCloud, Keychain | High | TC-036-040 | ⏳ 待开发 |
| **US-401** | Should | 订阅到期降级 | AC-401.1: 友好提醒<br>AC-401.2: 优雅降级 | SubscriptionManager | Sprint 2 | StoreKit | Medium | TC-046-050 | ⏳ 待开发 |
| **US-302** | Should | 教师班级创建 | AC-302.1: 班级创建与邀请<br>AC-302.2: 匿名统计视图 | TeacherClassService | Sprint 3 | CloudKit, Analytics | Medium | TC-051-055 | ⏳ 待开发 |
| **US-303** | Should | 教师布置作业 | AC-303.1: 布置作业<br>AC-303.2: 回收与统计<br>AC-303.3: 匿名化与隐私控制 | TeacherAssignmentService | Sprint 3 | CloudKit, Push Notifications | Medium | TC-056-060 | ⏳ 待开发 |
| **US-403** | Must | OCR错误修正 | AC-403.1: 一键重新识别<br>AC-403.2: 免费用户导出 | VisionOCRService (补充) | Sprint 1 | Vision Framework | Low | TC-061-065 | ⏳ 待开发 |
| **批量导入** | Should | 从相册批量导入 | 从相册选择多张图片并批量创建复习项 | BatchImportService | Sprint 2 | Photos Framework | Low | TC-066-070 | ⏳ 待开发 |
| **智能提醒** | Should | 基于遗忘曲线的智能提醒 | 根据遗忘曲线算法提供个性化复习提醒 | ForgettingCurveService | Sprint 3 | UserNotifications, CoreML | Low | TC-071-075 | ⏳ 待开发 |
| **NFR-Perf** | Must | 核心性能达标 | PRD 6.1中定义的所有性能指标 | 全局 | Sprint 1-3 | XCTest, Instruments | High | TC-Perf-All | ⏳ 待开发 |
| **NFR-Sec** | Must | 安全与隐私合规 | PRD 6.3中定义的所有安全隐私需求 | 全局 | CryptoKit, Keychain | High | TC-Sec-All | ⏳ 待开发 |

## **追踪状态说明**

* ✅ **已完成**: 功能已实现并通过测试  
* ⏳ **待开发**: 已设计，待实现  
* 🔍 **测试中**: 已开发，测试验证中  
* ❌ **被阻塞**: 依赖外部条件或技术问题  
* 📝 **需求变更**: 需要重新评估或调整

## **版本追踪**

* **v2.1 (2025-09-13)**: **补充完整性修订**。新增 US-302、US-303、US-403、批量导入、智能提醒等缺失功能，完善覆盖度。
* **v2.0 (2025-09-13)**: **结构性重构**。废弃无效的REQ-ID，全面转向以PRD用户故事ID为追踪核心，并同步所有最新技术决策。
* **v1.1 (2025-09-04)**: 同步 PRD v4.0 与 TDD v4.0 的新增项。 (已归档)
* **v1.0 (2025-09-03)**: 初版矩阵。 (已归档)
* **更新频率**: 每Sprint结束后更新一次  
* **负责人**: 产品经理维护，技术负责人确认实现状态

## **分阶段交付映射 (Phase Mapping)**

| 用户故事ID (PRD) | 交付阶段 |
| :--- | :--- |
| US-101, US-201, US-402, US-403 | 核心MVP (Week 1-6) |
| US-102, US-202, US-301, US-401, 批量导入 | 增强MVP (Week 7-10) |
| US-302, US-303, 智能提醒 | 完整v1.0 (Week 11-16) |
| NFR-Perf, NFR-Sec | 贯穿所有阶段 |

## **依赖与风险（简要）**

- 关键依赖：
    - CloudKit / iCloud（同步实现与配额）
    - OCR 模型（CoreML 本地模型 & 云端备选）
    - Analytics/Data Warehouse（指标派生）
    - StoreKit（订阅/支付）

- 风险要点：
    - CloudKit 配额/性能（高）：可能影响大用户量下的同步与存储策略，缓解：配额监控、压缩、服务限流。
    - 教师功能的后端依赖（高）：纯 CloudKit 难以满足复杂班级/作业管理需求，缓解：采用邀请制 Beta 或 BaaS 快速验证。
    - 埋点失真（中）：埋点实现不一致或漏报会影响指标计算，缓解：埋点规范、埋点 QA 与数据校验任务。

---
### **编辑历史 / 贡献者 (Edit History & Contributors)**

| 日期 | 版本 | 主要变更 | 贡献者 |
| :---- | :---- | :---- | :---- |
| 2025-09-13 | v2.1 | 补充缺失用户故事：教师功能(US-302/303)、OCR修正(US-403)、批量导入、智能提醒 | chramboliao, Copilot |
| 2025-09-13 | v2.0 | RTM结构性重构，以用户故事为核心 | chramboliao, Copilot |
| 2025-09-10 | v2.0+auto | 文档评审与结构优化 | Docs Maintainer |
| 2025-09-03 | v2.0 | 增加 REQ-011~017 / Sprint / 依赖风险 | Product & Tech |
| 2025-09-10 | v2.0+links | 添加跨文档快速跳转 & 编辑历史 | Docs Maintainer |

> 若需求集发生重构，创建新版本表格并将旧表格整体归档而不覆写。