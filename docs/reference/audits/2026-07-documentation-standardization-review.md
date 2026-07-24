# 2026-07 文档标准化独立复核

> **文档状态：固定基线历史证据。** 本文只记录一次只读监督及 C1 的本地复核，不是产品、
> 文档或执行权威；当前入口仍是根 `README.md`。

## 固定输入

- 日期：2026-07-24
- base：`origin/develop@6494d32dbdd9b2becaf019575da59253a8b7c33f`
- reviewed candidate：`a4c4e5f2a7230b640754bb050bf9e1469cd9b91a`
- 最小输入包：1.0 MB，只含文档控制面、生成器 / validator、相关测试和 candidate patch
- 同题 prompt SHA-256：
  `990ba0909d9abe969b35203c0ec74bb11e056439e14bd037f2fbf69ffa60e6ea`
- 输入 manifest SHA-256：
  `b4ab0374fab97e40675869a509d3ab22587907fd90fdeb7a9463c00fe49bd4e4`

两路均使用新会话、固定 cwd、只读 `Read/Grep/Glob`、无 web、无 subagent 和无持久记忆：

| Reviewer | CLI / model | 结果 |
|---|---|---|
| Claude | Claude Code `2.1.217` / `claude-fable-5[1m]` | `ACCEPT-WITH-CHANGES` |
| Grok | Grok CLI `0.2.111` / `grok-4.5`, high | `ACCEPT-WITH-CHANGES` |

raw transcript、debug / auth log 与会话材料未入仓；reviewer 没有仓库写工具。调用合同与已验证
参数由当前 [`agent-invocation-protocol.md`](2026-07-repository/agent-invocation-protocol.md)
维护。

## 复核共识

C1 重新打开候选文件后确认：

1. 根 README、Product Vision & Principles、Release 1 PRD 与 Feature Specs 的层级成立，
   stable decision / intent IDs 保留，候选没有改 Swift 代码或产品行为。
2. `definition-of-ready.md` 仍有跨行的旧英文权威名称；旧 validator 只扫描三个入口、skills
   和 Package 文档，无法发现该缺口。
3. 关键事实需要 existing `document-control.md` 中的唯一 tracked owner 规则；外部 reviewer
   输出必须由 DRI 复核后进入 owner，raw transcript 不是事实或权威。
4. 8 个 active feature spec 仍使用“Release 1 合同符合”，应统一为“Release 1 PRD 符合”。
5. `po-decision-log.md` 的一个仓库外 scorecard 与一条 Claude 私有记忆是唯一持有者，违反
   新事实归属规则；前者应转录最小历史回执，后者应路由到现有执行规范。
6. Product Vision 不应把 Team / Bundle / signing 事实归给已精简的根 README；实际 owner
   是 tracked config、Xcode project / entitlements、archive 和 release guide。

## 处置边界

上述六项均为可本地复现的工程 / 文档控制问题，不需要新增产品裁决。修复进入同一
documentation-standardization 分支；validator 只检查可确定的结构、生命周期、旧术语和已知
私有 holder，不尝试用关键字自动判断语义完整性。

本回执只证明两路独立复核及其已复现 finding。最终候选是否可合并，仍取决于修复后的 tracked
门禁、Draft PR 复核和 PO 对精确 head 的单独授权。

## 修复后验证

2026-07-24，C1 在独立 worktree 对上述 finding 完成修复，并运行：

- `python3 -m unittest Scripts.tests.test_validate_docs`：39 项通过；
- `python3 Scripts/validate_document_control.py --check`：通过；
- `python3 Scripts/validate_docs.py --check`：通过，仅保留既有语义 / legal 人工复核提示；
- `bash Scripts/pre-commit`：SwiftLint 280 个文件零违规，生成器 / 文档 / Capture /
  Release 配置门禁通过，35 项生成器测试与 167 项脚本回归测试通过；
- `git diff --check`：通过。

本 slice 没有改 Swift 源码、产品需求、stable decision / intent ID 或用户行为。修复后不再依赖
reviewer raw transcript、私有记忆或仓库外绝对路径重建上述事实。
