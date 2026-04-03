---
paths:
  - "CLAUDE.md"
  - "STATUS.md"
---

<!-- last verified: 2026-04-04 -->
# 协作模式

终端和 Xcode 中是**同一个 Claude（claude-opus-4-6）**，区别是入口和工具集：

| 入口 | 上下文 | 独有能力 | 适合场景 |
|---|---|---|---|
| **终端（Max 订阅）** | 1M token | 大上下文全局分析 | 规划、重构、文档审计、研究 |
| **Xcode** | 200K token | 19 个 MCP（Preview、DocumentationSearch、实时诊断） | SwiftUI 开发、Apple API、编译修复 |

两者共享：Bash、Git/gh、WebSearch、Auto Memory、文件读写。
选择原则：**需要大上下文 → 终端。需要看 UI 或查 Apple 文档 → Xcode。**
交流方式：GitHub Issue comment（两个入口都能读写）。
