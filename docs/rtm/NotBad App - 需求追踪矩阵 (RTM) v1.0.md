# **NotBad App \- 需求追踪矩阵 (RTM) v1.0**

| PRD需求ID | 优先级 | 用户故事 | 验收标准 | TDD技术实现 | 计划Sprint | 实际完成Sprint | 测试用例ID | 实现状态 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **REQ-001** | Must | 快速拍照录入 | AC1: \<3秒进入编辑 | CreateReviewItemUseCase | Sprint 1 | - | TC-001\~005 | ⏳ 待开发 |
| **REQ-002** | Must | OCR文字识别 | AC2: 识别率\>85% | VisionOCRService | Sprint 1 | - | TC-006\~010 | ⏳ 待开发 |
| **REQ-003** | Should | 智能分类 | AC1: 分类准确率\>80% | HybridAIService | Sprint 2 | - | TC-011\~015 | ⏳ 待开发 |
| **REQ-004** | Must | 专注复习模式 | AC1: 卡片加载\<0.3秒 | StudySessionUseCase | Sprint 1 | - | TC-016\~020 | ⏳ 待开发 |
| **REQ-005** | Should | 错题重做 | AC1: 自动识别答题区域 | RedoTemplateService | Sprint 2 | - | TC-021\~025 | ⏳ 待开发 |
| **REQ-006** | Should | 家长统计查看 | AC1: 仅显示统计数据 | ParentModeService | Sprint 2 | - | TC-026\~030 | ⏳ 待开发 |
| **REQ-007** | Should | 配额检查 | AC1: 检查准确率100% | QuotaService | Sprint 2 | - | TC-031\~035 | ⏳ 待开发 |
| **REQ-008** | Must | 云端同步 | AC1: 同步成功率\>99% | CloudKitSyncService | Sprint 1 | - | TC-036\~040 | ⏳ 待开发 |
| **REQ-009** | Should | 账户异常恢复 | AC1: 支持Apple ID恢复 | AccountRecoveryService | Sprint 2 | - | TC-041\~045 | ⏳ 待开发 |
| **REQ-010** | Should | 订阅到期降级 | AC2: Pro功能优雅降级 | SubscriptionManager | Sprint 2 | - | TC-046\~050 | ⏳ 待开发 |
| **REQ-011** | Must | 指标分层实现（L1/L2/L3） | AC: L1 埋点上报且可计算（月） | MetricsCalculator / AnalyticsService | Sprint 1 | - | TC-051\~053 | ⏳ 待开发 |
| **REQ-012** | Should | 家长授权撤销 | AC-301.3: 撤销后家长立即失去访问权限 | ParentAccessService | Sprint 3 | - | TC-054\~055 | ⏳ 待开发 |
| **REQ-013** | Should | 教师班级与作业 | US-302 / US-303: 班级创建、布置作业、匿名统计 | ClassManagementService | Sprint 3 | - | TC-056\~060 | ⏳ 待开发 |
| **REQ-014** | Should | OCR一键重新识别 | AC-403.1: 用户可一键重新识别并修正 | OCRService.reprocess | Sprint 2 | - | TC-061 | ⏳ 待开发 |
| **REQ-015** | Should | 分阶段交付映射 | PRD 分阶段：Core/Enhance/Full 时间盒 | ReleasePlan / CI Config | Sprint 1 | - | TC-062 | ⏳ 待开发 |
| **REQ-016** | Should | 班级匿名统计 | AC-302.2: 匿名聚合 | ClassManagementService.getAnonymizedStats | Sprint 3 | - | TC-063\~065 | ⏳ 待开发 |
| **REQ-017** | Should | 教师布置作业 | AC-303.1: 作业分发 | ClassManagementService.assignHomework | Sprint 3 | - | TC-066\~070 | ⏳ 待开发 |

## **追踪状态说明**

* ✅ **已完成**: 功能已实现并通过测试  
* ⏳ **待开发**: 已设计，待实现  
* 🔍 **测试中**: 已开发，测试验证中  
* ❌ **被阻塞**: 依赖外部条件或技术问题  
* 📝 **需求变更**: 需要重新评估或调整

## **版本追踪**

* **v1.0 (2025-09-03)**: 初版矩阵，覆盖MVP核心及边界需求  
* **v1.1 (2025-09-04)**: 同步 PRD v4.0 与 TDD v4.0 的新增项（指标分层、教师/家长撤销、OCR 重识别、分阶段发布计划）。
* **更新频率**: 每Sprint结束后更新一次  
* **负责人**: 产品经理维护，技术负责人确认实现状态

## **本次同步说明（简要）**
本次 RTM 更新旨在将最近对 PRD v4.0 与 TDD v4.0 的变更反映到需求追踪表中，确保产品/开发/测试三方对齐：

- 新增 REQ-011 对应指标分层（L1/L2/L3），要求数据团队实现埋点并提供月度派生表；测试需覆盖埋点准确性与计算口径。
- 新增 REQ-012 支持家长按题授权与撤销（审计日志），测试需验证撤销即时生效与跨设备一致性。
- 新增 REQ-013 教师班级与作业功能为 v1.x 的探索项，建议以邀请制 Beta 先行验证。
- 新增 REQ-014 OCR 重识别作为用户体验修复路径，需覆盖低置信度场景。
- 新增 REQ-015 将 PRD 的分阶段交付计划映射到 ReleasePlan 与 CI 配置，以便按时间盒推进开发与测试。

若你同意，我会将该 RTM 文件提交到分支并更新变更记录（commit 并 push）；或者我可以先生成一个 patch 给你审批（取决于你希望的工作流）。

## **分阶段交付映射 (Phase Mapping)**

| PRD需求ID | 交付阶段 | 目标完成周 |
| :--- | :--- | :--- |
| REQ-001~005 | 核心MVP | Week 1-6 |
| REQ-006~010 | 增强MVP | Week 7-10 |
| REQ-011~017 | 完整v1.0 | Week 11-16 |
