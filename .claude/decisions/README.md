# Architecture Decision Records (ADR)

本目录记录 SnapDrill 项目的核心架构决策。格式遵循 Michael Nygard 模板，每个 ADR 包含背景、决策、被否决方案（含重新评估条件）和后果。

## 索引

| ADR | 标题 | 状态 | 日期 |
|---|---|---|---|
| [ADR-001](ADR-001-model-as-domain-object.md) | @Model 直接作领域对象（删除 Domain 层） | Accepted | 2026-03-03 |
| [ADR-002](ADR-002-repository-no-protocol.md) | Repository 无协议（in-memory ModelContainer 替代测试） | Accepted | 2026-03-03 |
| [ADR-003](ADR-003-five-package-structure.md) | 5 包结构与严格单向依赖 | Accepted | 2026-03-07 |
| [ADR-004](ADR-004-dependency-injection-pattern.md) | DependencyContainer 唯一单例（DI 模式） | Accepted | 2026-03-13 |
| [ADR-005](ADR-005-infrastructure-isolation.md) | SnapDrillInfrastructure 包隔离（Firebase 封装） | Accepted | 2026-03-04 |
| [ADR-006](ADR-006-swiftdata-over-coredata.md) | SwiftData 而非 CoreData | Accepted | 2026-03-01 |
| [ADR-007](ADR-007-sm2-algorithm.md) | SM-2 间隔重复算法选型 | Accepted | 2026-03-01 |
| [ADR-008](ADR-008-voiceover-scope-deferral.md) | VoiceOver 全覆盖推迟到 v1.5 | Accepted | 2026-03-19 |

## 创建新 ADR

1. 文件名格式：`ADR-{NNN}-{短横线分隔的标题}.md`
2. 必须包含：背景、决策、被否决方案（每个方案须有「何时重新评估」或说明「不适用」）、后果
3. 创建后更新本索引
4. 在 `principles.md` 或 `architecture.md` 中添加指针
