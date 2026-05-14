---
name: api-research
description: F-017 强制执行器。新增/修改 UI 组件或引入新 SDK API 前，必须先查 Apple 最新文档确认没有更合适的新方案。当用户说"加个按钮/改样式/新 API/用这个组件"或涉及 SwiftUI/UIKit/Vision/AVFoundation 等框架时触发。
allowed-tools:
  - Bash
  - Read
  - WebSearch
  - WebFetch
  - Grep
context: fork
disable-model-invocation: false
user-invocable: true
---

# /api-research — Apple 最新 API 研究（F-017 执行器）

## 一句话

iOS 26 每年新增大量 API。Claude 的训练数据不覆盖最新版本。编码前必须先查 Apple 最新文档。

## 触发场景

- 新增 SwiftUI View 组件
- 修改视觉样式（材质、动画、布局）
- 引入新框架 API（Vision、AVFoundation、Charts 等）
- 不确定某个 API 是否为最新版本
- 用户说："用 Apple 原生方案 / 查最新 API / 有没有新 API 替代"

## 工作流

### Step 1：确认目标 iOS 版本

```bash
grep "IPHONEOS_DEPLOYMENT_TARGET" Configs/Shared.xcconfig
```

以项目部署目标为准（当前 iOS 26.0+），查对应版本的 API。

### Step 2：查项目内部知识库

先搜项目内已有知识，避免舍近求远：

```bash
# 查已知的 Apple API 陷阱
grep -i "关键词" docs/tech/api-pitfalls.md

# 查 Apple 平台边界
grep -i "关键词" docs/tech/apple-limits.md

# 查项目推荐的 Apple 原生模式
grep -i "关键词" docs/standards/apple-native.md
```

### Step 3：搜 Apple 最新文档

```bash
# WebSearch 搜 Apple 开发者文档
WebSearch: "iOS 26 <API名称> developer.apple.com"

# WebFetch 读具体文档页
WebFetch: https://developer.apple.com/documentation/<framework>/<api>
```

优先检查：
- 是否有 iOS 26 新增的替代 API（如 Liquid Glass .glassEffect() 替代 .regularMaterial）
- 是否有 WWDC 2025/2026 session 介绍新方案
- API 是否被 deprecated

### Step 4：对比现有代码

```bash
# 搜项目中已有的类似实现
grep -r "旧API" Packages/ --include="*.swift" -l
```

确认新 API 与现有代码的兼容性。

### Step 5：输出研究结论

```markdown
## API 研究

**需求**: <要做什么>
**候选 API**:
| API | iOS 版本 | 状态 | 推荐 |
|---|---|---|---|
| 新方案 X | 26.0+ | 推荐 | ✅ |
| 旧方案 Y | 15.0+ | Deprecated 26.0 | ❌ |

**证据**: <Apple 文档链接 / WWDC session>
**决策**: 使用 X，理由：<一句话>
```

## 反模式

- ❌ 直接用已知 API 不查最新版本 — iOS 26 可能有更好的
- ❌ 只看第一页搜索结果 — 可能有 WWDC session 介绍新方案
- ❌ 跳过 api-pitfalls.md — 已知陷阱可能已经记录了

## 关联规则

- `docs/memory/feedback.md` F-017（UI/SDK 改动前查 Apple 文档）
- `docs/tech/api-pitfalls.md` — 已知 API 陷阱
- `docs/tech/apple-limits.md` — Apple 平台能力边界
- `docs/standards/apple-native.md` — Apple 原生 UI 模式推荐
