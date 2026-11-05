# SnapDrill · greenfield baseline（本地草稿）

> 分支：`greenfield/rebuild-from-zero`，**orphan 分支**，无父提交、从零历史
> 状态：**已推送至远端分支**，未合入、未开 PR、未发布、未 effective、未 ratify；**不是产品决策**，不替代 `develop`
> 用途：破坏性重构的工作面。阶段 0 只写产品定义，不写代码

---

## 从 0 开始

本分支不读取、不调和、不继承旧仓库的文档、裁决编号和实现。旧内容互相冲突，不再作为这条重构的输入。

`Docs/PRODUCT.md` 是本分支的产品权威。要改产品语义，先改这份文件，并先有 PO 书面确认。

## 协作

PO 有最终决定权。Mac 上的 Cursor 用 `chbearxiong` 提交和推送，Windows 上的 WorkBuddy 用 `chramboliao` 提交和推送。两边都可以建议，也可以直接完善本分支上的文件。产品语义、阶段准出和不可逆动作，未经 PO 书面确认不算生效。两边不共享会话，交叉面是这条分支上的提交。

## 内容

| 文件 | 用途 |
| --- | --- |
| `README.md` | 本文件，新基线入口 |
| `Docs/PRODUCT.md` | 阶段 0：愿景、立项结论、Release 1 结果、非目标、平台约束、验收规则 |
| `Docs/ENGINEERING.md` | 6 阶段链路、T0–T4 验证分层、三条硬规则、被简化掉的旧包袱清单、环境事实 |
| `Docs/ACCEPTANCE.md` | 阶段 0 的 11 条结果验收。每条对应该产品定义，尚未执行 |
| `Docs/CUTOVER.md` | 路径 A 可逆新建、路径 B 替换、红线、分层触发条件 |
| `REVIEW.md` | 审查交接。第 2、5、6、8 节是 11 月 4 日的历史快照 |
| `Docs/STAGE0-REVIEW-RESPONSE.md` | Windows 对 `6b7e3d1` 的审查：6 项接受，5 项澄清 |
| `.gitignore` | Xcode / SwiftPM / 签名材料忽略规则 |

产品定义以本分支 `Docs/` 为准。

## 当前状态

- 阶段 0 进行中：`Docs/PRODUCT.md` 是候选，还没有书面确认
- 无代码、无构建配置、无 CI、无签名与发布证据
- `ACCEPTANCE.md` 尚未执行
- `develop` 原样保留，不在本次重构里修改或删除

## 恢复与切换

```bash
git checkout develop                       # 回到旧基线
git diff develop..greenfield/rebuild-from-zero --stat   # 审查完整差异
```

切换策略与触发条件见 `Docs/CUTOVER.md`。

---

*本地草稿已推送至远端分支（未合入、未开 PR）；作者归属与身份误用更正记录见 `REVIEW.md` 第 7、11 节。*
