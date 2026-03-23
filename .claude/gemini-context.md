# SnapDrill — Gemini 审查上下文

> **上游依赖**：`architecture.md`（包结构）、`conventions.md`（编码规范）、`principles.md`（工程哲学）
>
> 本文件供 Gemini GitHub Action 自动 review 使用，注入项目基本事实与架构约束。
> 所有约束的完整定义在权威文档中，本文件只做精简摘要和指针。

---

## 项目基本事实

- **技术栈**：Swift 6.2 + SwiftUI + SwiftData，iOS 26.0+
- **规模**：5 个 SPM 包（Core / Data / UI / Features / Infrastructure），~176 个 Swift 文件
- **产品定位**：本地优先单用户练习题数字化存档与间隔重复复习 App（面向全球发布，中国和美国为 T1 核心市场）
- **并发模型**：Swift 6 strict concurrency，所有 ViewModel 为 `@Observable @MainActor final class`

## 包结构

详见 `architecture.md`。依赖方向严格单向，反向依赖禁止。

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore（零依赖）
        │                                      ▲
        └──────────► SnapDrillUI ──────────────┘
SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

## 架构约束（完整理由见 principles.md）

| 约束 | 可修改触发条件 |
|---|---|
| 禁止 Domain 层 / Domain struct | 引入后端 API / 多设备同步 / @Model 超 20 属性 |
| 禁止 UseCase 层 | 3+ ViewModel 共享同一逻辑 / 跨 Repository 编排 |
| Repository 无协议 | 出现第二个实现 / 需脱离 SwiftData 环境测试 |
| 禁止 `any` / `!` / `@unchecked Sendable` | `conventions.md` | 硬性禁止（已批准例外见 conventions.md） |
| 禁止 `print()` | `conventions.md` | 硬性禁止 |

## 审查优先级

1. 🔴 逻辑错误（崩溃、数据丢失、状态不一致）
2. 🔴 Swift 6 并发安全违规
3. 🟡 SwiftData 使用错误 / 硬性禁止项违规
4. 🟢 代码质量优化
5. 🔵 约束触发条件已满足（单独列出说明）

**请勿建议**引入当前规模不需要的抽象层，除非明确说明触发条件已满足并附具体证据。
