# NotBad Scripts - 质量保障工具集

本目录包含NotBad项目的质量保障和CI/CD相关脚本，专注于代码质量检查和自动化测试。

注意：自 v6.0 起，所有与 PRD 相关的脚本均以 `docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md` 为目标文件；早期指向 v5.1 (iOS17) 的路径已弃用。

## 🚀 核心脚本

### 质量门槛检查

```bash
# 运行完整质量检查（推荐）
./Scripts/quality_gate.sh

# 检查文档一致性和链接有效性
./Scripts/check_docs_consistency.sh

# 自动修复文档格式问题
./Scripts/check_docs_consistency.sh --fix
```

这些脚本会运行所有质量检查，包括编译、测试、覆盖率、性能检查和文档验证。

## 📁 脚本列表

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `quality_gate.sh` | 质量门槛检查 | 运行所有质量检查的主脚本 |
| `check_docs_consistency.sh` | 文档一致性验证 | 检查文档一致性和链接有效性 |
| `check_coverage.py` | 覆盖率检查 | 验证测试覆盖率是否达标 |
| `check_performance_regression.py` | 性能回归检测 | 检查性能是否有退化 |
| `extract_performance_metrics.py` | 性能指标提取 | 从测试结果中提取性能数据 |

## 💻 使用方法

### 本地开发

```bash
# 提交前运行质量检查
./Scripts/quality_gate.sh

# 检查文档问题
./Scripts/check_docs_consistency.sh

# 修复文档格式问题
./Scripts/check_docs_consistency.sh --fix
```

### CI/CD流水线

这些脚本会在GitHub Actions中自动运行：

- `check_coverage.py` - 在CI中验证测试覆盖率
- `extract_performance_metrics.py` - 提取性能测试结果
- `check_performance_regression.py` - 性能回归检测
- `check_docs_consistency.sh` - 文档一致性和链接验证

## 🎯 质量标准

- **测试覆盖率**: ≥ 80%
- **编译检查**: 0 errors
- **代码风格**: SwiftLint 合规
- **性能回归**: ≤ 10%
- **文档质量**: Markdown格式规范，链接有效性

## 📖 相关文档

- [质量门槛详细说明](../docs/QUALITY_GATES.md)
- [开发工作流程](../docs/DEVELOPMENT_WORKFLOW.md)

---

> 💡 **提示**: 这些脚本与pre-commit hooks和CI/CD流水线集成，确保代码质量始终保持高标准。
