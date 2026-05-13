---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 0: 审计边界定义

## Goal

定义归零审计的精确范围：哪些文件入审、哪些排除、7 体系各自归属多少文件。

## 审计 Universe

**git 跟踪文件总计：440 文件**

不含：DerivedData、.build、reports、TestResults.xcresult、.env、build_output.txt、.claude/worktrees/、.claude/reviews/、.claude/session-*、__pycache__

## 排除项

| 类别 | 路径 | 理由 |
|---|---|---|
| 构建产物 | DerivedData/、.build/、*.hmap、*.ipa | 生成物，不可审计 |
| 测试产物 | TestResults.xcresult/ | CI 生成 |
| 报告产物 | reports/、__pycache__/ | docaudit 生成 |
| 本地配置 | .env、xcuserdata/、.DS_Store | 不入 git |
| Claude 运行时 | .claude/reviews/、.claude/session-*、.claude/worktrees/ | 会话临时文件 |
| 第三方源码 | Packages/*/.build/、DerivedData 中的 checkout | 不审第三方 |

## 7 体系文件分布

| 体系 | 文件数 | 占比 | 主要组成 |
|---|---|---|---|
| 1. 产品运行 | **201** | 45.7% | Swift 源码(177) + 资源/lproj/xcassets(12) + PrivacyInfo/entitlements/plist(12) |
| 2. 验证 | **67** | 15.2% | 测试 Swift(49) + snapshot PNG(16) + xctestplan(1) + XCUITest(1) |
| 3. 知识 | **53** | 12.0% | docs/product(7) + docs/tech(6) + docs/standards(16) + docs/decisions(3) + docs/archive(5) + KNOWLEDGE_MAP(1) + DOC_DEPENDENCY_MAP(1) + README(7) + docc(6) |
| 4. 状态与记忆 | **16** | 3.6% | STATUS.md(1) + docs/memory/handoff(1) + decisions(1) + feedback(1) + checkpoints(10) + README(1) + codex-handoff(1) |
| 5. 智能体治理 | **44** | 10.0% | .claude/rules(13) + .claude/skills(11) + .claude/hooks(10) + .claude/settings(1) + .agent-harness(4) + CLAUDE.md + CODEX.md + docs/workflow.md + docs/memory/feedback.md |
| 6. 工程管道 | **47** | 10.7% | .github/workflows(1) + .github/ISSUE_TEMPLATE(4) + .github/PULL_REQUEST_TEMPLATE(1) + Scripts(24) + fastlane(1) + Configs(3) + 根级 xcconfig(2) + xcodeproj(7) + .swiftlint.yml + ExportOptions.plist + upload_testflight.sh |
| 7. 依赖与供应链 | **12** | 2.7% | Package.swift(5) + Package.resolved(5) + GoogleService-Info.plist(1) + 根 Package.resolved(1) |
| **合计** | **440** | 100% | |

注：`.claude/hooks/*.sh`（10 文件）同时匹配体系 5 和体系 6 模式，归类为体系 5（主用途是智能体治理）。docs/memory/feedback.md 同时出现在体系 4 和体系 5，归类为体系 5（三方共识结论）。

## 跨体系边界文件

这些文件的归属需要明确：

| 文件 | 归属体系 | 理由 |
|---|---|---|
| `.claude/hooks/*.sh` | 体系 5 | 主用途是治理，脚本是实现手段 |
| `docs/memory/feedback.md` | 体系 5 | 三方共识：规范性规则，受众是 Agent |
| `docs/standards/coding.md` | 体系 3 | 受众是人类开发者 |
| `docs/standards/collaboration.md` | 体系 5 | 受众是 Agent |
| `docs/standards/permission-model.md` | 体系 5 | 定义了 Agent 权限 |
| `CLAUDE.md` / `CODEX.md` | 体系 5 | Agent 入口路由文件 |
| `SnapDrill/PrivacyInfo.xcprivacy` | 体系 1 | 属于产品合规配置 |
| `docs/archive/` | 体系 3 | 历史知识归档 |

## STATUS.md 事实声称回检补充

STATUS.md 是状态入口，不能只按文件归入体系 4 抽样审计。后续归零审计必须先从 STATUS.md 逐行抽取事实性声称，并为每条声称记录证据入口：

| 声称类型 | 主验证体系 | 必需证据 |
|---|---|---|
| 当前代码、架构、合规状态 | 体系 1/2/3/6 | 当前仓库 grep、测试、脚本或配置验证 |
| 当前 STATUS/handoff/checkpoint 新鲜度 | 体系 4 | frontmatter、last_verified、引用目标存在性 |
| Agent 版本、规则、hooks、skills、私有计划引用 | 体系 5 | 本地文件存在性；私有路径只作参考，需标注不可由仓库 CI 复验 |
| CI/test 通过数、历史本地验证 | 体系 2/6 | 最新可复验命令、CI run、xcresult 或日志摘要；无证据时不得写成已验证 |
| GitHub PR/Issue/open count、合并状态 | 体系 4 横切外部状态 | `gh`/GitHub 页面实时查询结果和查询日期 |
| Apple Developer/App Store Connect 状态 | 体系 4 横切外部状态 | Apple 后台或用户提供截图/记录；无访问权时必须标为用户声明 |
| 外部仓库 public/license/branch 状态 | 体系 5 横切外部状态 | GitHub 实时查询或 pinned commit/license 文件 |

若某条 STATUS.md 声称只能由外部服务、私有目录或历史运行日志验证，审计报告必须把它列为“外部/私有证据依赖”，不能用当前仓库静态审计替代。

## 私有空间（不入审计主语，仅在体系 5 做对照参考）

| 位置 | 文件数 | 内容 |
|---|---|---|
| `~/.claude/projects/.../memory/` | 34 | 用户偏好 + Claude 私有 feedback + 项目状态快照 + 工具参考 |
| `~/.claude/plans/` | ~8 | 历史 planning 产物 |

## 安全基线

- ✅ 无 .env / credentials / tokens 在 git 中
- ✅ 无超过 1MB 的大文件
- ✅ .gitignore 覆盖合理
- ✅ 无敏感文件泄露

## Next

进入 Step 6：工程管道体系审计。
