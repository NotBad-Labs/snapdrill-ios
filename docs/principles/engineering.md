---
last_verified: 2026-04-14
layer: principle
---
# 工程哲学

## 元原则

1. **战术勤奋不掩盖战略懒惰** — 先问全局有没有未解决的战略问题
2. **局部最优 ≠ 全局最优** — 从全局视角审视
3. **设计阶段成本最低** — 先讨论透再动手
4. **方法论持续优化** — 实证驱动修订，不固守教条

## 决策前研究铁律

**不确定就先研究，禁止想当然写代码。**

- UI/UX：Apple 原生 App → 行业标杆 → HIG
- 技术：Apple 文档 → WWDC → 现有代码库

## 奥卡姆剃刀 (Occam's Razor)

新增抽象前必答：

1. 解决什么具体问题？
2. 有没有更简单的方式？
3. 删掉还能工作吗？（"删掉方案的一半，还能解决问题吗？"）
4. 改一个需求动 N 个文件？N > 3 是警告

与元原则 #1 互补：战术上精心设计的抽象，如果战略方向错了，越精致越浪费。先确认战略正确，再审视抽象必要性。

## YAGNI (You Aren't Gonna Need It)

**不为假设性未来需求写代码。**

- 本项目禁止 Domain 层 / UseCase 层（`coding.md`）— 单人开发 + ViewModel 直调 Repository，多余的层是 YAGNI
- 内测阶段不做 Schema 迁移（`feedback.md` F-004）— 没有外部用户，不需要向前兼容
- 三行相似代码优于一个过早抽象 — 重复不一定是坏事，过早抽象才是

守门问题：**这个功能现在有真实用户需要吗？没有就不做。**

## 三次法则 (Rule of Three)

**看到模式出现 3 次再抽象，不提前。**

- 新 rules 文件的入口条件：识别到重复性约束 3 次以上 → 从 feedback 提升为 rule（`KNOWLEDGE_MAP.md`）
- 代码中改一个需求动 N 个文件、N > 3 是抽象不当的警告 — 同一个数字 3 的两面：出现不够 3 次别抽象，扩散超过 3 处说明抽象缺失

与奥卡姆剃刀的关系：奥卡姆剃刀回答"要不要抽象"，三次法则回答"什么时候抽象"。

## 编译期拦截 (Fail Fast at Compile Time)

**能让编译器拦的，就不留到运行时。**

| 实践 | 配置 / 规则 |
|---|---|
| 零容忍警告 | `Shared.xcconfig`: `GCC_TREAT_WARNINGS_AS_ERRORS = YES`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` |
| 完整并发检查 | `Shared.xcconfig`: `SWIFT_STRICT_CONCURRENCY = complete` |
| typed throws | 业务验证用 `throws(SpecificError)`，禁止 `case underlying(Error)` 逃生舱（`coding.md`） |
| 包边界编译器强制 | 5 个 SPM 包单向依赖，反向 import 直接编译失败（`architecture.md`） |
| 禁止不安全标注 | `@unchecked Sendable`、`force unwrap !` 列入禁止清单（`coding.md`） |

如果一个 bug 能在编译期被发现却在运行时才暴露，说明约束不够强。

## 单一真相源 (Single Source of Truth)

**每个事实只有一个权威来源，其余都是指针。重复就会漂移，漂移就会矛盾。**

| 事实 | 唯一来源 | 指针示例 |
|---|---|---|
| 版本号 | `Configs/Shared.xcconfig` | pbxproj 读取 xcconfig |
| 委派约束 | `docs/principles/shared-constraints.md` | codex-delegation.md / gemini-delegation.md 要求"读取并内联" |
| 术语定义 | `docs/product/product-glossary.md` | 各文档使用一致术语 |
| 开发规则 | `docs/principles/` | `.claude/rules/` 作为指针路由 |

违反信号：同一信息在两处出现且措辞不同 → 必须确定谁是源、谁是指针，消除重复。

## 可逆性优先 (Prefer Reversible Decisions)

**在信息不完整时，优先选择可以撤回的方案。**

- 软删除 5 秒撤销窗口（`DeletionScheduler`）— 用户决策可逆
- ADR 可被新 ADR 废弃替代 — 架构决策可逆
- 内测阶段不锁 Schema — 数据结构可逆
- feature branch + PR — 代码变更可逆

不可逆决策（App Store 发布、Schema 迁移、数据删除永久化）需要更高的审查门槛。

## 关注点分离 (Separation of Concerns)

**每个模块只有一个变更理由。**

| 层 | 职责 | 变更理由 |
|---|---|---|
| SnapDrillCore | 协议、服务、SM-2 引擎、DI | 业务逻辑变更 |
| SnapDrillData | @Model、Repository、备份、迁移 | 数据结构变更 |
| SnapDrillUI | Router 协议、可复用组件 | UI 组件库变更 |
| SnapDrillFeatures | View + ViewModel 配对 | 功能需求变更 |
| SnapDrillInfrastructure | Firebase 封装 | 第三方 SDK 替换 |

Infrastructure 隔离 Firebase：替换 Firebase 只改这一层，Core 通过协议解耦（`architecture.md`）。View/ViewModel 分离：View 纯渲染，ViewModel 持有状态和逻辑（`coding.md`）。

## 协议优先 (Protocol-Oriented)

**优先用协议定义契约，实现在下游。**

- `ServiceContainer` 协议 → `LiveServiceContainer` / `MockServiceContainer` 实现
- `OCRServiceProtocol` → `OCRService`（可替换为测试 Mock）

协议定义在 Core 层，实现在各具体层。依赖方向始终向上（Feature → Core），不反向。

## 值语义默认 (Value Semantics First)

**跨边界传递的数据用 struct，有状态的对象用 class + @MainActor。**

| 场景 | 类型 | 原因 |
|---|---|---|
| DTO / Snapshot / 配置 | `nonisolated struct` + `Sendable` | 跨 actor 零成本传递 |
| ViewModel | `@Observable class` | 有可变状态，需 MainActor 隔离 |
| Service（无状态） | `struct` 或 `enum` 命名空间 | 无实例状态则无需 class |
| Service（有状态） | `actor` | 自带隔离，如 `BackupService` |

守门问题：**这个类型需要 identity 吗？不需要就用 struct。**

## 并发安全优先 (Structured Concurrency First)

**强 actor 隔离优于手工同步。编译器能检查的并发安全，不用运行时验证。**

- `defaultIsolation(MainActor)` — 全局默认隔离，减少标注负担
- `nonisolated` 显式声明无隔离需求（纯计算、DTO 转换）
- `actor` 隔离有状态的后台服务（`BackupService`）
- `Task.detached` 仅用于确需脱离当前 actor 的场景（文件 IO、图片压缩）

优先使用 actor 隔离，避免 `NSLock`、`os_unfair_lock` 等手工同步原语。
UIKit 桥接场景（AVFoundation 回调、UIKit 动画调度）允许 `DispatchQueue.main.async`。

## 单向状态流 (Unidirectional Data Flow)

**状态从 ViewModel 流向 View，反向通过通知或回调。**

```
View ──(用户操作)──→ ViewModel ──(修改状态)──→ @Observable 自动刷新 View
                                    │
                                    ├──(持久化)──→ Repository
                                    └──(广播)──→ NotificationCenter → 其他 ViewModel
```

- View 通过 ViewModel 调用 Service（埋点等轻量操作可直接调用 `analyticsService`）
- ViewModel 之间通过 `NotificationCenter`（`.reviewDataDidChange`）解耦，不互相引用
- 跨模块状态同步走通知，不走共享可变状态
