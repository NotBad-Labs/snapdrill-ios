# SnapDrill 开发流程

- 状态：当前工程协作规则
- 最后确认：2026-07-25

本文定义人和 Agent 如何把 [PRD.md](PRD.md) 变成可审阅代码。架构边界见
[ARCHITECTURE.md](ARCHITECTURE.md)，数据高风险边界见 [DATA.md](DATA.md)。

## 1. 开工顺序

每个任务先确认：

1. **结果**：用户或仓库最终能观察到什么；
2. **范围**：允许修改的文件和明确不做的事情；
3. **依据**：对应 PRD、数据契约、平台规范或可复现缺陷；
4. **验收**：通过 / 失败的可执行判断；
5. **风险**：需要的验证等级和是否必须由 PO 决策。

旧 issue、旧 PR、历史审计和聊天摘要默认只有线索价值。除非当前任务明确要求历史调查，
不得仅凭旧编号恢复工作。

## 2. T0 基线

任何写入前：

```bash
git fetch origin develop
git rev-parse origin/develop
git status --short
git worktree list
```

- 主 checkout 不写入；
- 从最新 `origin/develop` 创建独立 worktree 和 `codex/` 分支；
- 确认 worktree 无无关脏文件；
- 记录 base SHA、目标、范围、验收和阻塞项；
- 同时 active write 最多两个，合并始终串行。

## 3. 决策边界

Agent 可以自主：

- 复现缺陷、分析代码和官方资料；
- 在已确认 PRD / 数据 /架构边界内实现；
- 增补测试、修正客观事实、更新 owner 文档；
- push 分支并创建 Draft PR；
- 修复 CI 中与该分支直接相关的问题。

必须由 PO 决定：

- 产品身份、目标用户、需求优先级和公开文案承诺；
- 新功能是否进入 PRD；
- 商业模式、平台、区域、账号、同步和隐私政策；
- 对外数据兼容或 wire 政策；
- PR 合并、上传、TestFlight 开放、go / no-go 和发布；
- 账号、密钥、证书和不可逆外部操作。

PO 的对话意图先进入对应 owner 文档的候选变更；只有合入 `develop` 后才成为其他任务的基线。

## 4. 改动原则

1. 先读 live code、调用方和当前 owner 文档，再修改。
2. 选择满足验收的最简单完整方案，不添加投机抽象和未要求配置。
3. 每行改动都能追溯到结果、根因、验收或保持构建一致所必需的工作。
4. 不覆盖其他 worktree 或用户的改动，不顺手清理无关文件。
5. 结构化数据使用结构化 API；错误显式处理，禁止 silent `try?` 吞错。
6. 外部平台和工具事实优先查官方文档；社区资料只作补充。

## 5. 验证等级

| 等级 | 适用范围 | 最低证据 |
|---|---|---|
| T0 | 只读调查 | base、cleanliness、path:line 或命令证据 |
| T1 | 文档、模板、无行为脚本 | 文档集合检查、`git diff --check` |
| T2 | 代码行为、Core / Data / ViewModel | T1 + SwiftLint + build + targeted tests |
| T3 | 用户可见 UI / 文案 | T2 + affected UI tests + AX / Dynamic Type + 截图 |
| T4 | 数据、隐私、wire、恢复、签名、发布 | T3 适用项 + fault paths + clean routine check + 设备 / 发布证据 |

`build-for-testing` 只证明编译，不等于测试已运行。

## 6. Canonical 命令

```bash
# T1 文档改动
python3 Scripts/validate_docs.py --check

# T2+ 代码候选
bash Scripts/check.sh
```

- `bash Scripts/check.sh` 运行文档集合检查、SwiftLint、编译和全部非 UI 测试。
- 迭代期间可以用 `xcodebuild test -only-testing:<target>/<suite>` 缩短反馈；候选 push 前仍运行
  `check.sh`。
- `swift test` 不适用；SPM 只声明 iOS 平台。
- 仓库不安装强制 Git hook，也不维护自定义模拟器解析、证据数据库或工具版本解析器；命令失败时
  直接处理 SwiftLint、Xcode 或测试报告的原始错误。
- 相机、文档扫描、打印、签名和安装必须在真实设备或对应系统表面验证。

## 7. PR 与合并

Draft PR 至少说明：

- base 与精确 head；
- 结果、范围和未做事项；
- 实际运行的命令与结果；
- 未运行项和剩余风险；
- 用户可见变更的截图；
- 数据或发布改动的失败路径证据。

Draft / Ready、绿色 CI 和旧授权都不等于合并授权。每次合并必须由 PO 针对当前精确 head 明确
授权；head 移动后重新授权。

## 8. 文档规则

- 当前事实只写入 `README.md`、`AGENTS.md` 或 `docs/` 的五个 owner。
- 产品需求只写 `PRD.md`；不得建立平行 roadmap、feature spec 或决策回执。
- 临时计划、审计、截图和运行日志不提交到 `docs/`。
- 旧事实通过 Git 历史查找，不在当前树中保留“已废弃”副本。
- 新增长期文档必须先证明五个 owner 无法合理承载，并同步更新文档门禁。
