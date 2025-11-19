# NotBad 错题本 App

## 🚀 项目状态：重起炉灶完成 + 工作流闭环就绪

**代码库清理时间**：2025-11-19  
**工作流建立时间**：2025-11-19  
**编译状态**：✅ BUILD SUCCEEDED（iOS 26.1 Simulator）

当前代码库已完成清理，仅保留：
- ✅ 主入口 `NotBadApp.swift`（最小可运行版本）
- ✅ 基础资源（Assets、Info.plist、entitlements）
- ✅ PRD v6.2 作为单一事实来源
- ✅ 完整工作流闭环（WORKFLOW + CI 自动化）

所有历史实现已移除，确保无旧代码反向约束新开发。

---

## 📄 单一事实来源（SSoT）

本项目完全以 **PRD v6.2** 为唯一权威依据：

**[docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.2.md](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.2.md)**

### 核心原则

1. **PRD 为宪法**：所有设计、开发、测试决策必须回溯到 PRD v6.2
2. **禁止反向约束**：任何代码、文档、流程不得对 PRD 施加限制
3. **单向派生**：实现从 PRD 派生，永不反向
4. **产品价值观**：本地优先 · 端侧优先 · 隐私优先 · 免费无广告

---

## 🔄 工作流闭环系统

为确保多人/AI 协作时不出现偏差，本项目建立了完整的工作流闭环：

### 📚 文档体系

| 文档 | 用途 | 适用对象 |
|------|------|----------|
| **[PRD v6.2](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.2.md)** | 单一事实来源 | 所有人 |
| **[WORKFLOW.md](docs/WORKFLOW.md)** | 工作流规范与决策树 | 所有人 |
| **[ROADMAP.md](docs/ROADMAP.md)** | 详细实施计划（11 Phases） | 开发者 |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | 贡献指南 | 贡献者 |
| **[AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md)** | AI 专用操作手册 | AI 助手 |

### 🤖 自动化检查（CI）

每个 PR 自动触发以下强制检查：

- ✅ **PRD 对齐检查**：验证 PR 描述包含 PRD 引用（§X.Y.Z）
- ✅ **测试覆盖率**：单元测试覆盖率 ≥ 60%
- ✅ **性能基线**：满足 PRD §5.1 性能要求
- ✅ **编译检查**：Debug + Release 配置均通过
- ✅ **代码规范**：SwiftLint 检查通过
- ✅ **反向约束检查**：无"PRD 应该改"等注释

**所有检查必须通过，PR 才能合并。**

### 🎯 决策树：我该走哪个流程？

```
开始工作
    ↓
需要改变产品行为？
    ├── 是 → 流程 A：PRD 变更流程
    └── 否 → 是否新增功能？
              ├── 是 → PRD 中已定义？
              │         ├── 是 → 流程 B：功能实现流程
              │         └── 否 → 流程 A：PRD 变更流程
              └── 否 → 是否修复 Bug？
                        ├── 是 → 流程 C：Bug 修复流程
                        └── 否 → 流程 D：重构优化流程
```

**详细流程说明**：[docs/WORKFLOW.md](docs/WORKFLOW.md)

---

## 🛠 技术栈（来自 PRD v6.2）

- **平台**：iOS 26.0+
- **语言**：Swift 6.2
- **UI 框架**：SwiftUI
- **数据持久化**：SwiftData
- **OCR 能力**：Vision Framework
- **云同步**：CloudKit（可选）
- **架构模式**：MVVM + Coordinator

---

## 🎯 当前里程碑：工程基础对齐

- [x] 清理历史代码，保留主入口
- [x] 验证编译成功
- [x] 建立完整工作流闭环（WORKFLOW + CI 自动化）
- [x] 创建文档体系（PRD/WORKFLOW/ROADMAP/AI_GUIDE）
- [ ] 升级工程配置至 Swift 6.2 / iOS 26.0
- [ ] 建立 SwiftData 模型层
- [ ] 实现 Vision OCR 能力
- [ ] 构建核心导航流程（欢迎屏 → 主界面）
- [ ] 集成遥测基础设施

**下一步**：开始 Phase 1 - 工程基础对齐（详见 [ROADMAP.md](docs/ROADMAP.md)）

---

## 🚀 快速开始

### 对于开发者

```bash
# 1. Clone 仓库
git clone https://github.com/your-org/NotBad.git
cd NotBad

# 2. 阅读核心文档（必读）
# - docs/prd/PRD v6.2.md（了解产品）
# - docs/WORKFLOW.md（了解流程）
# - docs/ROADMAP.md（了解进度）

# 3. 开始工作前，确认流程
# 查阅 WORKFLOW.md 决策树

# 4. 创建分支
git checkout -b feature/phase1-your-task

# 5. 编写代码（TDD 优先）
# 每个文件顶部必须包含 PRD 溯源注释

# 6. 本地验证
xcodebuild test -scheme NotBad -testPlan UnitTestPlan

# 7. 提交 PR（使用模板）
# 必须包含 PRD 章节引用
```

### 对于 AI 助手

```bash
# 1. 阅读 AI 专用指南（必读）
cat docs/AI_COLLABORATION_GUIDE.md

# 2. 每次任务前自查
# - [ ] 已查阅 PRD 对应章节
# - [ ] 已确认走哪个流程（WORKFLOW.md 决策树）
# - [ ] 已查阅 ROADMAP.md 确认优先级

# 3. 遵循强制规则
# - ✅ 先阅读 PRD，再实现功能
# - ❌ 不实现 PRD 未定义的功能
# - ✅ 代码包含 PRD 溯源注释
# - ❌ 不添加反向约束 PRD 的注释

# 4. 使用响应模板
# AI_COLLABORATION_GUIDE.md 提供了完整的响应模板库
```

---

## 🔄 变更流程

需要改变产品行为或架构时：

1. **先修改 PRD**：在 PRD v6.2 中明确变更内容
2. **通过评审**：确保变更符合产品目标与原则
3. **再改实现**：基于更新后的 PRD 修改代码
4. **更新测试**：确保测试覆盖新的 PRD 要求

详见 [WORKFLOW.md §流程A](docs/WORKFLOW.md#-流程-aprd-变更流程最高优先级)

---

## 📊 质量指标

### 代码质量
- 测试覆盖率：≥60%（关键模块 ≥80%）
- SwiftLint：无 error，warning ≤ 5
- 性能：满足 PRD §5.1 基线要求

### 流程合规
- 100% PR 包含 PRD 引用
- 0 次反向约束 PRD 的提交
- PRD 变更频率 ≤ 1 次/周

### 自动化覆盖
- ✅ PRD 对齐自动检查
- ✅ 测试与性能自动验证
- ✅ 反向约束自动拦截

---

## 📋 文档生成策略

其他文档（TDD/RTM/测试规范/指标对齐等）将在实现推进过程中 **按需由 PRD 派生生成**，确保与 PRD 始终一致。

---

## 💬 获取帮助

- 📖 **遇到流程问题**：查阅 [WORKFLOW.md](docs/WORKFLOW.md)
- 🐛 **遇到技术问题**：创建 Issue 并打上 `help-wanted` 标签
- 💡 **有功能建议**：先查阅 PRD，再创建 [PRD 变更请求](.github/ISSUE_TEMPLATE/prd-change.md)
- 🤖 **AI 协作问题**：查阅 [AI_COLLABORATION_GUIDE.md](docs/AI_COLLABORATION_GUIDE.md)

---

## 📜 License

本项目遵循 [LICENSE](LICENSE) 文件中的许可协议。

---

## 🎉 项目亮点

### ✨ 独特的治理模型
- **PRD 为宪法**：首个完全以 PRD 为单一事实来源的 iOS 项目
- **工作流闭环**：完整的文档体系 + CI 自动化，确保多人/AI 协作不偏差
- **可追溯性**：每行代码都可追溯到 PRD 章节与验收标准

### 🤖 AI 友好
- 专门的 AI 协作指南
- 明确的决策树与响应模板
- 自动化检查防止 AI 偏离 PRD

### 🔒 质量保证
- TDD 优先（先写测试）
- 自动化 CI 强制检查
- 性能/合规/测试三重保障

---

**让我们一起构建最好的错题本应用！🚀**

*PRD 版本：v6.2*  
*代码库重建：2025-11-19*  
*工作流闭环建立：2025-11-19*
