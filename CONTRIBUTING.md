# 贡献指南 (Contributing)

欢迎为 NotBad 项目贡献！本项目采用 **"PRD 为宪法"** 的治理模型，确保所有变更可追溯、可验证、符合产品愿景。

---

## 🎯 核心原则

### PRD 为单一事实来源（SSoT）

**唯一权威文档**：[docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.2.md](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.2.md)

- ✅ **先改 PRD，再改实现**：任何功能变更必须先更新 PRD，再提交代码
- ❌ **禁止反向约束**：代码/文档不得要求修改 PRD（应先提 PRD 变更请求）
- ✅ **可验证性**：每项需求必须有验收标准（AC）与测试映射

---

## 🚀 快速开始：我该怎么做？

### 第一步：确定你的工作类型

```
┌─────────────────────────────────────────────┐
│    我不确定该走哪个流程？                     │
│    👉 查阅决策树：docs/WORKFLOW.md          │
└─────────────────────────────────────────────┘
```

**常见场景快速指引**：

| 你想做什么 | 查阅文档 | 走哪个流程 |
|-----------|---------|-----------|
| 🆕 实现新功能 | [WORKFLOW §流程B](docs/WORKFLOW.md#-流程-b功能实现流程) | 功能实现流程 |
| 🐛 修复 Bug | [WORKFLOW §流程C](docs/WORKFLOW.md#-流程-cbug-修复流程) | Bug 修复流程 |
| 📝 修改 PRD | [WORKFLOW §流程A](docs/WORKFLOW.md#-流程-aprd-变更流程最高优先级) | PRD 变更流程 |
| ⚡ 重构/优化 | [WORKFLOW §流程D](docs/WORKFLOW.md#-流程-d重构优化流程) | 重构优化流程 |
| 📄 更新文档/工具 | [WORKFLOW §流程E](docs/WORKFLOW.md#-流程-e文档工具流程) | 文档工具流程 |

### 第二步：阅读相关文档

**必读**（按顺序）：
1. 📄 [PRD v6.2](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.2.md) - 了解产品定义
2. 🔄 [WORKFLOW.md](docs/WORKFLOW.md) - 了解工作流程
3. 🗺️ [ROADMAP.md](docs/ROADMAP.md) - 了解当前进度与优先级

**AI 协作者额外阅读**：
4. 🤖 [AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md) - AI 专用操作指南

---

## 📋 提交步骤（通用）

### 1. 创建 Issue（可选但推荐）

```bash
# 使用 GitHub Issue 模板
# - 功能建议 / Bug 报告 / PRD 变更请求
```

### 2. 创建分支

```bash
# 分支命名规范：
# - feature/{phase}-{module}-{brief-desc}  # 新功能
# - bugfix/issue-{N}-{brief-desc}          # Bug 修复
# - refactor/{module}-{brief-desc}         # 重构
# - docs/{brief-desc}                      # 文档

git checkout -b feature/phase2-capture-ocr
```

### 3. 编写代码（TDD 优先）

**必须遵守**：
- ✅ 每个新文件顶部包含 PRD 溯源注释
- ✅ 先写测试，再写实现（TDD）
- ✅ 关键算法/决策必须引用 PRD 条款
- ❌ 不要添加"PRD 应该改"等反向约束注释

**示例**：
```swift
//
//  OCRService.swift
//  NotBad
//
//  PRD 章节：§4.3.1 错题捕获 - OCR 识别
//  验收标准：AC-UC-OCR-01（P90 ≤ 2.5s）
//  性能要求：§5.1 Baseline OCR
//

import Vision

/// OCR 服务实现
class OCRService {
    // ...implementation
}
```

### 4. 本地验证

```bash
# 编译检查
xcodebuild build -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 运行测试
xcodebuild test -scheme NotBad -testPlan UnitTestPlan

# 检查覆盖率（要求 ≥60%）
xcodebuild test -scheme NotBad -enableCodeCoverage YES

# 代码规范检查
swiftlint lint
```

### 5. 提交 PR

```bash
git add .
git commit -m "feat(capture): 实现 OCR 服务 (PRD §4.3.1, AC-UC-OCR-01)"
git push origin feature/phase2-capture-ocr
```

**PR 描述必填**（使用模板）：
- [ ] PRD 章节（格式：§X.Y.Z）
- [ ] 验收标准（格式：AC-XXX-YYY-NN）
- [ ] 测试覆盖说明
- [ ] 性能验证（如适用）
- [ ] 合规检查（如涉及个人数据）

### 6. CI 自动检查

你的 PR 将自动触发以下检查（必须全部通过）：

- ✅ **PRD 对齐检查**：验证 PR 描述包含 PRD 引用
- ✅ **测试覆盖率**：单元测试覆盖率 ≥ 60%
- ✅ **性能基线**：满足 PRD §5.1 性能要求
- ✅ **编译检查**：Debug + Release 配置均通过
- ✅ **代码规范**：SwiftLint 检查通过
- ✅ **反向约束检查**：无"PRD 应该改"等注释

如果检查失败，请根据 CI 反馈修复。

### 7. 人工评审

评审者将检查：
- 代码实现与 PRD 描述是否一致
- 测试是否充分覆盖验收标准
- 性能是否满足 NFR 要求
- 是否有反向约束 PRD 的内容

### 8. 合并

所有检查通过 + 至少 1 位评审人批准后，PR 将被合并。

---

## ⚠️ 常见错误与解决方案

### ❌ 错误 1：PR 无 PRD 引用

**CI 错误信息**：
```
❌ PRD 对齐检查失败
PR 必须在描述中引用 PRD 章节（格式：§X.Y.Z）
```

**解决方案**：
编辑 PR 描述，添加：
```markdown
PRD 章节：§4.3.1 错题捕获
验收标准：AC-UC-OCR-01
```

### ❌ 错误 2：测试覆盖率不足

**CI 错误信息**：
```
❌ 测试覆盖率不足：45% < 60%
```

**解决方案**：
增加单元测试，覆盖关键逻辑路径。

### ❌ 错误 3：反向约束 PRD

**CI 错误信息**：
```
❌ 发现反向约束 PRD 的注释
NotBad/Core/DataManager.swift:42: TODO: PRD 应该增加离线缓存功能
```

**解决方案**：
- 移除该注释
- 如确需增加功能，先走 [流程 A：PRD 变更流程](docs/WORKFLOW.md#-流程-aprd-变更流程最高优先级)

### ❌ 错误 4：实现了 PRD 未定义的功能

**评审反馈**：
```
🔄 此功能未在 PRD 中定义，请先走【流程 A：PRD 变更流程】
```

**解决方案**：
1. 关闭当前 PR
2. 创建 [PRD 变更请求 Issue](.github/ISSUE_TEMPLATE/prd-change.md)
3. PRD 变更批准后，重新提交实现 PR

---

## 🤝 协作规范

### 人类贡献者

- 提交前查阅 [WORKFLOW.md](docs/WORKFLOW.md) 确认流程
- 使用 Issue/PR 模板（自动填充必填项）
- 遵循 TDD 原则（先写测试）
- 积极参与 Code Review

### AI 贡献者

- **必读**：[AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md)
- 每次任务前先查阅 PRD 对应章节
- 遵循决策树（WORKFLOW.md）
- 遇到 PRD 不清晰时停止并请求人类帮助
- 使用响应模板库（AI_COLLABORATION_GUIDE.md）

---

## 📊 质量标准

### 代码质量
- 测试覆盖率：≥60%（关键模块 ≥80%）
- SwiftLint：无 error，warning ≤ 5
- 性能：满足 PRD §5.1 基线要求

### 文档质量
- 所有公共 API 必须有文档注释
- 关键算法/决策必须引用 PRD 条款
- README/CHANGELOG 保持更新

### 流程合规
- 100% PR 包含 PRD 引用
- 0 次反向约束 PRD 的提交
- PRD 变更频率 ≤ 1 次/周

---

## 🚨 紧急情况处理

### 安全漏洞修复
1. 立即修复，无需等待 PRD 变更
2. 24 小时内补充 PRD 说明
3. 通知安全团队

### 编译错误阻断
1. 立即修复编译错误
2. 验证不改变功能行为
3. 合并后立即补充流程文档

### 第三方库强制升级
1. 评估影响范围
2. 如改变行为，先更新 PRD
3. 更新测试确保兼容性

---

## 📚 参考资源

### 核心文档
- 📄 [PRD v6.2](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.2.md)
- 🔄 [WORKFLOW.md](docs/WORKFLOW.md)
- 🗺️ [ROADMAP.md](docs/ROADMAP.md)
- 🤖 [AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md)

### 模板
- [PR 模板](.github/PULL_REQUEST_TEMPLATE.md)
- [PRD 变更请求模板](.github/ISSUE_TEMPLATE/prd-change.md)

### 自动化
- [PRD 对齐检查](.github/workflows/prd-alignment-check.yml)
- [测试与性能检查](.github/workflows/test-and-performance.yml)

---

## 💬 获取帮助

- 📖 遇到流程问题：查阅 [WORKFLOW.md](docs/WORKFLOW.md)
- 🐛 遇到技术问题：创建 Issue 并打上 `help-wanted` 标签
- 💡 有功能建议：先查阅 PRD，再创建 PRD 变更请求
- 🤖 AI 协作问题：查阅 [AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md)

---

**感谢你为 NotBad 项目贡献！让我们一起构建最好的错题本应用 🚀**

*最后更新：2025-11-19*
