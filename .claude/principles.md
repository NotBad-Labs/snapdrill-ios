# SnapDrill 工程哲学

> 「怎么想」——决策框架。「怎么写代码」见 `conventions.md`，「怎么协作」见 `workflow.md`。

---

## 战略元原则

1. **战术勤奋不能掩盖战略懒惰** — 每次开始新工作前先问：战略层面有没有未解决的问题？
2. **局部最优 ≠ 全局最优** — 决策时从全局视角审视
3. **设计阶段多花时间，远比发布后返工便宜** — 先把设计讨论透
4. **方法论持续优化** — 实证驱动修订规则，不固守教条

---

## 决策前研究铁律

**不确定的实现必须先研究再写代码。**

- **UI/UX**：Apple 原生 App → 行业标杆 App → Apple HIG
- **技术**：Apple 开发者文档 → WWDC → 现有代码库
- 文档有推荐 → 直接采用；行业有惯例 → 采用并注释；完全自创 → 必须有明确理由

用户质量检查触发词：「铁律？」

---

## Apple 原生优先

**UI/交互改动必须先找到 Apple 原生 App 或 HIG 中的对应模式。禁止自创交互。**

| 场景 | 正确做法 | 禁止做法 |
|---|---|---|
| Form 选值（短列表） | `Picker(.menu)` | `Menu` 包裹整行 |
| Form 选值（长列表） | `NavigationLink` → 勾选列表 | 自制 Sheet |
| 破坏性操作确认 | `confirmationDialog` / `.alert` | 自制弹窗 |
| 导航到详情 | `NavigationLink` | `Button` + 手动 push |
| 删除列表项 | `.onDelete` / 左滑删除 | 自制滑动手势 |

心智模型：整行可点 + `>` = NavigationLink；右侧值 + 小箭头 = Picker；底部弹出 = confirmationDialog；Sheet = 临时全屏子流程

---

## 奥卡姆剃刀

新增抽象/协议/层/文件前必答：
1. 解决了什么**具体**问题？"未来可能有用" = 不加
2. 有没有更简单的方式？Swift 原生能做到的不造轮子
3. 删掉这一层代码还能工作吗？能 = 不该存在
4. 改一个需求需要动 N 个文件？N > 3 是警告信号

---

## SwiftData 原则

**@Model = 领域对象**，无 Domain struct，无 UseCase 层，无 Repository 协议。
- 重新评估条件：引入后端 API 或多设备同步需独立领域层
- Repository 无协议：有 in-memory ModelContainer 替代测试，加协议是 test-induced design damage
- 重新评估条件：出现第二个 Repository 实现

**@Query 使用边界**：
- 适合：列表展示、实时统计、简单过滤
- 不适合：复杂业务规则计算、跨源聚合、状态机流程（如 ReviewViewModel）

---

## 包边界与 DI

**依赖严格单向**，编译器强制。跨包用协议，包内用具体类型。

**DI 唯一模式**：协议定义在 Core → 实现在下游 → DependencyContainer 构造 → @Environment 注入 → View 传给 ViewModel

**禁止**：`.shared` 直接调用、ViewModel 默认参数耦合具体类、View 直接调服务、@Environment 注入具体类型

---

## 测试策略

| 代码层 | 策略 |
|---|---|
| 纯算法（SM-2、CSV 转义） | TDD（test-first） |
| ViewModel 状态机 | Test-after（稳定后补） |
| Repository CRUD | Test-after（in-memory ModelContainer） |
| SwiftUI View / 胶水代码 | 不测（Preview + 手动验证） |

禁止：为可测试性加单实现协议、对 View 写单元测试、追求覆盖率数字

---

## 文档治理

- 活文档加 `Last verified` 日期（改 typo ≠ verified）
- 架构决策记录在 architecture.md 和 principles.md 中，不用独立 ADR 文件
- 发版前全量扫描 `.claude/` 文档与代码一致性
