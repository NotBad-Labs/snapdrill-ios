# Phase 00b Results: Control-Plane Blind Review

## Outcome

Claude、Antigravity、Grok 在同一 `develop@d62fead8` 上独立审阅。首次 launcher 试跑暴露两项编排错误：Grok 的 plan 模式不执行读取；Antigravity 会忽略 cwd 并回到已有 project。两者修正启动参数后重新运行，首次无效输出未参与结论。

Codex C1 对所有候选重新读取 live files、执行命令并控制 scope。最终接受 3 条 finding，拒绝或路由其余候选。

## Verified Findings

### RA-00B-001 — P2 — Fresh setup does not declare the PyYAML dependency required by pre-commit

- `Scripts/pre-commit:20-27` 只检查 `python3` 存在，随后执行两个导入 `yaml` 的生成器。
- `Scripts/setup.sh:11-18` 只安装 SwiftLint；仓库没有 requirements / pyproject 对 PyYAML 作声明。
- 复现：在 clean venv 执行 `python Scripts/generate_feature_status.py --check`，稳定返回 `ModuleNotFoundError: No module named 'yaml'`。
- 影响：新环境按 setup 完成后仍会在第一次 commit 被阻断；CI 仅因当前 self-hosted runner 已有该包而绿色。

### RA-00B-002 — P3 — Release/CI reference is behind the live workflow

- `docs/how-to/release-and-ci.md:47-74` 的 step list 缺少 live `Validate docs` 与两处 `Prime SPM cache`，也未描述 UI simulator boot/bootstatus 和 retry 逻辑。
- live 证据：`.github/workflows/ci.yml:53-60,105-122,179-217`。
- `last_verified: 2026-06-20` 的 `ci_change` decay trigger 已被 2026-07-02 的 CI commit 触发。
- 影响：形成一份不完整的 CI 描述；不影响实际 workflow 执行。

### RA-00B-003 — P3 — Two process pointers target deleted paths

- `.gitignore:48` 声称 `reports/` 由不存在的 `Scripts/audit/docaudit.py` 生成。
- `Scripts/hooks/pre-push:18` 把被阻断的操作者指向不存在的 `docs/memory/feedback.md` 和私有 `MEMORY`。
- Git 历史确认这些路径曾存在后被删除，并非当前 checkout 漏文件。
- 影响：触发流程时引导到第二真相源或死路；hook / ignore 本身仍工作。

## Routed Candidates

以下事实由 C1 复现，但超出 00b primary/direct-reference 文件边界，登记到 Phase 09，不进入本轮 ledger：

1. **CAND-09-001**：`Scripts/ci-local.sh` 使用 `SnapDrill` scheme；该 scheme 的 TestAction 只绑定 `UITests.xctestplan`，脚本又跳过 `SnapDrillUITests`，仍可打印“本地 CI 全部通过”。它也不运行 docs、dependency 和 test-plan gates。
2. **CAND-09-002**：根 `README.md:95-97` 的 `test-without-building` 命令可合法运行，不需要强制 `-xctestrun`；但未指定 `-only-test-configuration CI`，实测同一 Swift Testing suite 在 `CI` 与 `SnapshotRecord` 两个 configuration 各执行一次。加 CI selector 后只执行一次。

## Rejected Candidates

- **必须传 `-xctestrun`**：不成立。scheme + test plan 能复用同路径 DerivedData；本地 targeted test 成功。
- **DoD 未被 pre-commit 全量执行就是缺陷**：不成立。DoD 明确是人工/agent 完成门，hook 没声称覆盖 build-for-testing。
- **Xcode 26.5 与 CI 26.4+ 矛盾**：不成立。前者是当前本地工具链事实，后者是 CI 最低版本。
- **worktree / lane / DoR 未机器强制**：不成立。文档将其定义为协作政策，没有承诺 CI enforcement。
- **本地 soft pre-push 等于隐藏风险**：已知且透明；live GitHub API 对 branch protection / rulesets 均返回 private-plan 403，hook 文案与事实一致。
- **生成文档缺少 hard gate**：不成立。tracked pre-commit 和 CI 都执行 `--check`；本机 stale hook 已刷新。

## Recovery

- brief：`phases/00b-control-plane.md`
- raw reports：阶段归一化后从 `/private/tmp` 删除
- next：Phase 01a GitHub metadata snapshot
