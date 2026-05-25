---
last_verified: 2026-05-25
layer: principle
scope: standards
name: dependency-propagation
description: 文档变更后传播同步。当改了任何文档/API/ADR 后，按 DOC_DEPENDENCY_MAP.md 找到所有下游文件，grep 具体引用并同步更新。当用户说"同步下游/传播变更/propagate/更新下游文档"或改完文档后自动触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /dependency-propagation — 文档变更传播

## 一句话

改了一个文档后，不能只改这一个。依赖图里的所有下游文件必须检查并同步。

## 触发场景

- 改了任何产品/技术/标准文档后
- 改了 public API 后
- 新建/更新 ADR 后
- 用户说："同步下游 / 传播变更 / propagate / 更新下游文档"
- PR 合并后发现下游不一致（修复场景）

## 工作流

### Step 1：确定变更源

明确刚才改了什么：
- **文件路径**：改的是哪个文档
- **变更类型**：新增事实 / 修改已有事实 / 删除 / 重命名
- **变更内容**：一句话描述改了什么

### Step 2：查依赖图找下游

读 `docs/DOC_DEPENDENCY_MAP.md` §2 变更传播规则表，找到该文件的下游清单：

```
改动源头 → 最少同步清单
product-vision.md → design + requirements + business + cases + glossary + compliance
ADR-* → 相关 product/tech 文档 + 实现代码与测试
product-design.md / product-requirements.md → cases + business
compliance.md / NFR.md → deployment
代码 public 接口 → api-reference.md
PR 合并 / issue 状态变化 → STATUS.md + handoff.md
```

如果变更源不在表中，用 §1 依赖矩阵查找"下游影响"列。

### Step 3：逐一下游 grep 具体引用

对每个下游文件，不盲目全改，精确 grep 变更相关的关键词：

```bash
# 例：改了 product-vision.md 里的 "免费版含 3 份试卷" → "免费版含 5 份试卷"
# 在 requirements.md 中 grep 相关引用
grep -n -i "3.*试卷\|试卷.*3\|免费.*试卷" docs/product/product-requirements.md
```

只更新实际引用了变更内容的行，不做无关改动。

### Step 4：区分主链与交叉引用

改主链上游 → 必须传播到下游（内容生成方向）。
改交叉引用目标 → 不自动改引用方，但确认引用方仍能追溯。

```
主链示例：vision → design → requirements → cases（必须传播）
交叉引用示例：cases 引用 workflow 的 S0-S3 定义（改 workflow 时 cases 不需要自动改）
```

### Step 5：判断是否需要 ADR

重大决策必须走 ADR：
- 影响架构、商业模式、数据模型 → 创建/更新 ADR
- 影响多个产品文档的根本假设 → 创建 ADR
- 纯事实更新（版本号、日期）→ 不需要 ADR

### Step 6：输出传播报告

```markdown
## 变更传播报告

**变更源**: <文件> — <一句话>
**依赖图引用**: DOC_DEPENDENCY_MAP.md §2

| 下游文件 | 状态 | 改动 |
|---|---|---|
| requirements.md | ✅ 已更新 | L42: "3 份" → "5 份" |
| business.md | ✅ 无需改 | 未引用具体数量 |
| cases.md | ⚠️ 待确认 | L18 引用但需人工判断 |
```

## 辅助命令

```bash
# 查某文档的下游（从依赖图直接提取）
grep -A1 "^| \`docs/product/product-vision.md\`" docs/DOC_DEPENDENCY_MAP.md

# 全局搜某关键词在哪些文档出现（找隐藏引用）
grep -r "关键词" docs/ --include="*.md" -l

# 搜代码中的 API 引用（改 public 接口时）
grep -r "旧API名" Packages/ --include="*.swift" -l
```

## 反模式

- ❌ 改了 vision 不传播到 requirements — 产品文档自相矛盾
- ❌ 逐个文件问用户"要不要改这个" — 噪声轰炸，应该自动 grep + 报告
- ❌ 把交叉引用当主链全量重写 — 过度传播
- ❌ 传播时顺手改无关内容 — scope creep

## 关联文档

- `docs/DOC_DEPENDENCY_MAP.md` — 完整依赖图
- `docs/KNOWLEDGE_MAP.md` — 知识分层索引
- `docs/protocol.md` §决策变更收尾 — 传播闭环流程

---

## 外部事实研究 - API 引入前 (吸纳自 api-research)


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

本 skill 是 F-017 的权威执行器。`docs/memory/feedback.md` 仅保留索引指针。

- `docs/tech/api-pitfalls.md` — 已知 API 陷阱
- `docs/tech/apple-limits.md` — Apple 平台能力边界
- `docs/standards/apple-native.md` — Apple 原生 UI 模式推荐
