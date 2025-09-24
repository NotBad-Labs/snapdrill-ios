# 覆盖率路线图

本文档描述 NotBad 项目的测试覆盖率提升计划与阶段目标，采用“渐进式拉升 + 质量优先”的策略。

## 目标与原则

- 双门槛持续生效：
  - 逻辑覆盖率（排除 SwiftUI Views）≥ 80%（当前已长期稳定 ≥ 90%）
  - 整体覆盖率：随阶段逐步提升
- 质量优先：避免仅为覆盖率而写无意义测试；优先验证交互、状态变化与错误分支。
- 覆盖率与重构并进：以测试驱动重构（TDR）提升可测试性与设计质量。

## 阶段里程碑

- [x] Phase 1：60%（当前）
- [ ] Phase 2：65%（Q4 2025）
- [ ] Phase 3：70%（Q1 2026）
- [ ] Phase 4：75%（Q2 2026）

## 每阶段关注重点

- Phase 2（65%）：
  - 业务核心：`Domain/Shared/ReviewItemRepository.swift`（当前 ~20.51%）
  - ViewModel：`Presentation/ViewModels/LibraryViewModel.swift`（~58.33%）
  - 用例层：`Application/UseCases/CaptureReviewItemUseCase.swift`（~75%）
- Phase 3（70%）：
  - 进一步完善 ViewModel（`CaptureViewModel`、`HomeDetailViewModel`），覆盖错误与边界分支
  - UI 组件行为性测试（有限度，重在状态与导航）
- Phase 4（75%）：
  - 边缘场景与错误路径系统性补齐
  - 低频模块的“防回退”测试（薄弱但重要路径）

## 执行方法与规范

1. 识别薄弱模块：使用 `Scripts/analyze_coverage.py` 分析最新快照
2. 测试驱动重构（TDR）：先补测试暴露设计问题，再做小步重构
3. PR 准入：新功能/改动需附带相应测试用例
4. 质量脚本：持续运行 `Scripts/check-quality.sh` 并生成快照

## 命令示例

```bash
# 运行质量脚本并生成最新覆盖率快照
./Scripts/check-quality.sh

# 分析薄弱文件（排除 Views 与测试目录）
python3 Scripts/analyze_coverage.py docs/coverage/coverage-<timestamp>.json \
  --exclude-path-regex 'NotBad/(NotBadUITests|NotBadTests)/.*|NotBad/NotBad/Presentation/(.*/)?Views/.*\\.swift' \
  --min-executable-lines 20 --limit 20
```

## 附录：测试优先级建议

- 高风险/高频路径优先：仓库、用例、服务层
- 纯 UI 布局延后：通过轻量渲染烟雾测试覆盖即可
- 错误与边界分支不可忽略：归入阶段性“补齐任务”
