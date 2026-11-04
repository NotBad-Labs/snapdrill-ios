# 对抗性审查交接（greenfield 草稿）

> 供 `chbearxiong` 账号审查
> 分支 `greenfield/rebuild-from-zero`，**仅在本地副本，未推送**
> 审查目标：找出本草案中未经证实的前提、错误结论，以及被我悄悄丢掉的重要约束

---

## 1. 我做了什么

- 在 orphan 分支上从零建立 7 个文件的基线；`develop` 及其 720 个文件**原样未动**
- 无代码、无构建配置、无 CI 接线、无签名/隐私/发布证据
- **未推送、未开 PR、未合并、未转 Ready、未触发上传或发布**
- 未运行旧仓库任何脚本，未在本机跑构建

## 2. 我的假设（请优先攻击这些）

| # | 假设 | 依据 | 可能错在哪 |
| --- | --- | --- | --- |
| 1 | 当前无外部用户、App 从未发布 | 用户陈述 + `vision.md` L42、`positioning-and-audience.md` L25、`release-1-prd.md` L89、`feat-profile.md` L28 | 若存在未登记的 TestFlight 外部测试者，兼容 epoch 可能已触发 |
| 2 | `docs/product/` 是唯一 effective 产品权威 | `document-control.json` 的 `effective-authority` 规则 | 若有未合入 `develop` 的 PO 裁决另有权威 |
| 3 | PR #983 分支的 `docs/PRD.md` 是平行 PRD、不应采纳 | `vision.md` L14 禁令 + 内容冲突（Level 字段、竞品参照、兼容承诺、§10 自授执行权） | 若 PO 后来 ratify 了该分支的规范输入，结论反转 |
| 4 | 产品语义应保持不变，只做重组精简 | 我未收到任何改变产品语义的精确裁决 | 若 PO 本意就是改定位，`PRODUCT.md` 第 3 节耐久边界需重开 |
| 5 | 数据兼容可降为「首次分发前冻结」 | 兼容 epoch 未触发 | `feat-backup.md` L51 明确禁止把「无测试用户」外推成任意破坏授权的借口 |
| 6 | `mac-mini` 上线后可承接验证 | runner 元数据 `ARM64` / `macOS` | 当前 offline；Xcode 26.6 → 27.0 迁移中（#984），CI 仍在 beta（#975） |
| 7 | 旧治理体系可整体简化 | 用户明确「不想背着包袱」 | 其中可能混有安全 / 数据 / 隐私必需项，不能一刀切 |

## 3. 我明确没做的事（请核对是否被绕过）

- 未改写 `develop` 任何文件；未 `force push`、未 rewrite history、未删远端分支
- 未合并 PR #983、未触发 archive / TestFlight / 上传 / 发布
- 未把聊天、agent 私有记忆或仓库外报告写成关键事实的唯一持有者
- 未使用 `chramboliao` 或 `chbearxiong` 作为提交身份；本次 commit 作者为中性占位 `greenfield-draft`
- 未接触 `chbearxiong` 的任何凭证

## 4. 可复核的命令（全部只读）

```bash
cd ./snapdrill-ios
git branch -vv
git log --oneline --all
git show --stat HEAD
git diff develop..greenfield/rebuild-from-zero --stat
git status --short
git checkout develop                          # 恢复旧基线
gh api repos/NotBad-Labs/snapdrill-ios/actions/runners \
  --jq '{total_count, runners: [.runners[] | {name,status,busy,os,labels:[.labels[].name]}]}'
```

## 5. 已知薄弱点（我主动列出）

- `ACCEPTANCE.md` 的 11 条用例**一条都没执行**；本机无 Apple 工具链、runner offline
- 11 条 Must 是从 effective PRD 提炼，**未逐条回链到 30 项 ratified decisions**，可能有遗漏或语义偏移
- `feat-backup.md` L51 的约束只在 `PRODUCT.md` 引用，未落为可执行检查
- `CUTOVER.md` 路径 B 的 5 项确认尚未得到 PO 回答
- 新基线无代码、无 CI、无签名/隐私/发布证据；目前只是**文档级骨架**
- 我未核实 `chbearxiong` 与组织的关系，也未验证第二台自托管机器

## 6. 希望审查者回答的问题

1. 假设 1 是否成立？是否真的从未向非 PO 自然人分发过构建？
2. 11 条 Must 与 effective PRD 的 Must outcomes 是否有语义偏差或遗漏？
3. 被简化掉的治理约束里，有没有哪条其实是安全 / 数据 / 隐私必需项？
4. 是否存在我未发现的第四套产品权威路径？
5. orphan 分支 + 中性提交身份，是否符合你对「从 0 开始」的预期？

## 7. 身份边界说明

本机 `gh` CLI 登录的是 `chramboliao`（只读 API 调用时以该凭证发起），**那是本机凭证，不是「我的账号」**；我不扮演、不切换任何 GitHub 身份。`chbearxiong` 是审查者账号，我未接触、不需要其凭证。本次本地 commit 作者为中性占位 `greenfield-draft <greenfield-draft@localhost>`，仅用 `git -c` 临时指定，未写入仓库或全局配置。

---

*本文件为新基线内的审查交接材料，未推送；旧仓库 `develop` 未受影响。*
