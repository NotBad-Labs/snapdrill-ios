# ADR 0002: 解除对 Struct 内部 Mutation 的禁止策略

**日期**: 2026-02-25
**状态**: ✅ Accepted

## 1. 背景 (Context)

在早期的《20条最佳实践宪法》中，第 20 条规定：“禁止 Mutable 值对象，struct 的属性一律使用 let，修改返回新实例”。这是试图模仿纯函数式编程（如 Haskell），但完全违背了 Swift 的 `Copy-on-Write (CoW)` 和栈级内存就地突发性能优化机制。这导致一旦 Struct 较大，开发者为了改一个属性需要写满版的样板代码（Boilerplate），极大增加了维护负担和无意义的多次内存分配副本。

## 2. 决策 (Decision)

**全面解禁 Struct 内部的 `var` 与 `mutating func`**。
我们确认：在 Swift 6 严格并发检查以及 `Sendable` 协议的基础上，值类型（Struct）由于被复制时具有值语义（Value Semantics），本身就是并发安全的。不变性（Immutability）的权力应该交还给调用方（使用 `let` 还是 `var` 变量声明），而不是在声明处通过 `let` 卡死。

## 3. 后果 (Consequences)

- 修改 `swift6_rules_full.md`，删除第 20 条对 Immutable Struct 的无理要求。
- 减轻了开发者的心智负担，提升了复杂 Model 更新的内存利用性能。
