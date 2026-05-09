---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 6: 工程管道体系审计

## Goal

审计 CI/CD、Scripts、fastlane、xcconfig、xcodeproj 的完整性、一致性和可复现性。

## Scope

47 文件：ci.yml(1) + Scripts(24) + fastlane(1) + xcconfig(5) + xcodeproj(7) + .swiftlint.yml(1) + ExportOptions.plist(1) + upload_testflight.sh(1) + CI templates(5)

## Findings

### Critical (0)

无 Critical 发现。

### Warning (6)

**W1: Configs/ 下存在 2 个孤儿 xcconfig 文件**
- `Configs/Debug.xcconfig` — Xcode project.pbxproj 未引用。实际使用的是根级 `Debug.xcconfig`。
- `Configs/Release.xcconfig` — 同上，未被引用。
- 风险：如果有人修改 `Configs/Debug.xcconfig` 以为在改项目配置，改动不会生效。已知多份文档（engineering.md、handoff.md、devops skill）指向 `Configs/Shared.xcconfig` 作为版本号 SSOT，但 `Configs/` 下的 Debug/Release 从未被使用。
- 修复：删除 `Configs/Debug.xcconfig` 和 `Configs/Release.xcconfig`，或从 pbxproj 改为引用 Configs/ 版本。

**W2: ci-local.sh 与 CI 使用不同 scheme，不是真正的"本地 CI 复现"**
- ci-local.sh 用 `SnapDrill` scheme（`build` + `test -skip-testing:SnapDrillUITests`）
- CI 用 `AllTests` scheme（`build-for-testing` + `test-without-building -only-test-configuration CI`）
- 差异：(a) ci-local 不跑 snapshot 测试 (b) ci-local 用 `xcodebuild test` 而非 `build-for-testing` + `test-without-building` (c) ci-local 不跑 AllTests.xctestplan 的 CI configuration
- 风险：开发者在本地 ci-local 绿了就推送，但 CI 可能红（不同的测试集、不同的构建方式）

**W3: fastlane beta lane 测试 scheme 与 CI 不一致**
- Fastfile `run_tests(scheme: "SnapDrill")` — 普通 test action
- CI `AllTests` scheme + test plan + CI configuration
- 风险：beta 发布前跑的测试和 CI 门禁不同，可能发布未经 snapshot 测试验证的构建

**W4: gemini_review.py 尝试加载 .claude/gemini-context.md 但文件不存在**
- 代码 L14-17：`context_path = os.path.join(..., ".claude", "gemini-context.md")`
- 文件 `/Users/yiming/Developer/snapdrill-ios/.claude/gemini-context.md` 不存在
- 后果：Gemini 审查时缺乏项目架构上下文，增加假阳性率。静默降级，无错误提示。

**W5: docaudit-preflight.sh 在 git rebase 上触发不合理**
- 匹配模式包含 `git rebase`，每次 rebase 都跑完整的 `docaudit all --strict --baseline`
- 风险：变基是高频操作，每次触发完整 docaudit 扫描增加不必要的延迟，且变基期间文档一致性检查的边际价值很低

**W6: 无代码覆盖率门禁和密钥扫描**
- CI 无代码覆盖率报告或门禁
- 无 secrets scanning（GitHub 免费提供的 CodeQL / secret scanning 未启用）
- AllTests.xctestplan 中 `codeCoverage: false`

### Info (3)

**I1: Mac mini 自托管 runner 是单点故障**
- 唯一的 macOS runner，离线时全部 build job 排队等待
- 当前无 GitHub-hosted macOS runner fallback

**I2: 7 个一次性 Ruby 脚本仍在 Scripts/ 中**
- `add_assets.rb`、`add_swiftlint_phase.rb`、`fix_duplicate_assets.rb`、`inspect_project.rb`、`migrate_share_to_sync_group.rb`、`migrate_to_yaml_frontmatter.py`、`check_headers.py`
- 合理迁移到 `Scripts/archive/` 或标记为已执行

**I3: .swiftlint.yml 与 swift-autolint.sh 双向耦合**
- `.swiftlint.yml:41-42` 注释明确要求：修改 excluded 时同步 hook 的 case 块
- 这是 Issue #666 已记录的已知耦合，有注释锚定

## Positive Findings

- ✅ CI 双 job 并行设计合理（docs on ubuntu-latest 不占 Mac mini）
- ✅ 依赖方向 grep 检查覆盖 5 条规则，能拦截架构泄漏
- ✅ build-for-testing + test-without-building 分离，CI 效率好
- ✅ 模拟器擦除防止 SwiftData 死锁
- ✅ xcresult artifact 上传（失败时保留 7 天）
- ✅ Xcode 版本检查有兜底逻辑（显式路径 → default → version 校验）
- ✅ docaudit policy 设计成熟：分级 + legacy_whitelist + expires_on
- ✅ Shared.xcconfig 是真正的版本号单一来源
- ✅ `-parallel-testing-enabled NO` 正确规避了 SwiftData 竞态

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 正确性 | 7/10 | 核心 CI 流程正确，但 ci-local 和 fastlane 与 CI 不一致 |
| 完整性 | 6/10 | 缺覆盖率门禁、密钥扫描、ci-local 功能不完整 |
| 一致性 | 6/10 | 重复 xcconfig、scheme 不一致、gemini-context.md 缺失 |
| 可维护性 | 8/10 | 结构清晰，注释充分，policy.yaml 设计良好 |
| **综合** | **6.8/10** | |

## Risks

- 如果某人修改 `Configs/Debug.xcconfig` 而非根级版本，调试可能浪费大量时间
- 如果 CI Mac mini 长时间离线（如硬件故障），所有 PR 阻塞

## Next

Step 2: 验证体系审计
