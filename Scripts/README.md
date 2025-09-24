# NotBad Scripts - 质量保障工具集

本目录包含 NotBad 项目的质量保障和 CI/CD 相关脚本，专注于代码质量检查与自动化测试。

注意：自 v6.0 起，脚本与文档遵循统一的“单一事实来源”策略：
- 质量门槛以 `docs/QUALITY_GATES.md` 为准（双阈值）
- 流程以 `docs/DEVELOPMENT_WORKFLOW.md` 为准（Git Flow）

## 🚀 首选脚本（推荐）

### 1) 本地 CI 一键跑通（覆盖率导出 + 阈值校验）

`local-ci.sh` 会执行构建、单元测试（含覆盖率）、导出 JSON 快照，并校验双阈值；默认并行执行。

用法：

```bash
# 快速本地验证（建议在 zsh 下运行）
SKIP_MARKDOWNLINT=1 MAX_WORKERS=4 zsh Scripts/local-ci.sh
```

要点：
- `DESTINATION` 默认 iPhone 17，可通过环境变量覆盖
- `MAX_WORKERS` 控制并行度（默认 4）
- `SKIP_MARKDOWNLINT=1` 可跳过 markdownlint 加速本地循环

### 2) 质量门槛与快照（双阈值）

`check-quality.sh` 负责统一的质量门槛检查与快照落盘；在集成分支上用它来对齐仓库策略。

用法：

```bash
zsh Scripts/check-quality.sh
```

### 3) 覆盖率分析（定位低覆盖高 ROI 文件）

`analyze_coverage.py` 会对 `local_artifacts/coverage-local.json` 进行分析并输出 Top N 低覆盖文件。

用法：

```bash
python3 Scripts/analyze_coverage.py local_artifacts/coverage-local.json --limit 25
```

## 🧰 兼容/遗留脚本（Deprecated）

`quality_gate.sh` 为早期整合脚本，现已被 `local-ci.sh` 与 `check-quality.sh` 覆盖（功能更清晰、与策略一致）。暂保留以便迁移；新流程请不要再引用它。

## 📁 脚本清单

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `local-ci.sh` | 本地 CI 一键验证 | 构建 + 测试 + 覆盖率导出 + 双阈值校验 + 可选 markdownlint |
| `check-quality.sh` | 质量门槛与快照 | 与仓库策略对齐的门槛校验与快照落盘 |
| `analyze_coverage.py` | 覆盖率分析 | 排序输出低覆盖文件，指导增量测试 |
| `check_coverage.py` | 覆盖率阈值检查 | 被上述脚本调用，执行阈值判断 |
| `check_performance_regression.py` | 性能回归检测 | 检查性能是否退化（可选） |
| `extract_performance_metrics.py` | 性能指标提取 | 从测试结果中提取性能数据（可选） |
| `quality_gate.sh` | 旧版整合脚本 | Deprecated：请改用 `local-ci.sh`/`check-quality.sh` |

## 💻 使用建议

### 本地日常

```bash
# 首选：快跑迭代，生成覆盖率 JSON
SKIP_MARKDOWNLINT=1 MAX_WORKERS=4 zsh Scripts/local-ci.sh

# 或：对齐仓库门槛并落盘快照
zsh Scripts/check-quality.sh
```

### CI/CD 流水线

在 GitHub Actions 中，建议调用 `check-quality.sh` 以对齐阈值与文档策略；必要时可在 `develop`/`release/*` 上追加性能与 UI 测试工序。

## 🎯 质量标准（单一事实来源）

请以 `docs/QUALITY_GATES.md` 为准：
- 整体覆盖率阈值：≥ 65%
- 逻辑覆盖率阈值（排除 Views）：≥ 80%
- 其余项（编译、风格、性能等）以该文档描述为准

## 📖 相关文档

- [质量门槛详细说明](../docs/QUALITY_GATES.md)
- [开发工作流程](../docs/DEVELOPMENT_WORKFLOW.md)
- [CI/CD 配置入口](../docs/ci-cd/README.md)

---

> 💡 提示：本目录中的脚本与 pre-commit hooks 和 CI/CD 流程配合使用。若发现与文档阈值/流程不一致，请以 `docs/QUALITY_GATES.md` 与 `docs/DEVELOPMENT_WORKFLOW.md` 为准，并提 PR 修正脚本文案。
