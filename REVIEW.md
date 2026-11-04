# 对抗性审查交接（greenfield 草稿）

> 供 `chbearxiong` 账号审查
> 分支 `greenfield/rebuild-from-zero`，**已推送至远端**，未合入、未开 PR；orphan 分支与 `develop` 无共同祖先
> 审查目标：找出本草案中未经证实的前提、错误结论，以及被我悄悄丢掉的重要约束

---

## 1. 我做了什么

- 在 orphan 分支上从零建立 7 个文件的基线；`develop` 及其 720 个文件**原样未动**
- 无代码、无构建配置、无 CI 接线、无签名/隐私/发布证据
- **已推送分支（普通 push，未 force）**；未开 PR、未合并、未转 Ready、未触发上传或发布
- 未运行旧仓库任何脚本，未在本机跑构建
- 作者身份曾误设为 PO 个人账号，按方案 A 更正，见第 7、11 节

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
- 11 条 Must 已完成逐条回链（见第 8 节），**发现大量结果级边界丢失，尚未修正到 `PRODUCT.md`**
- `feat-backup.md` L51 的约束只在 `PRODUCT.md` 引用，未落为可执行检查
- `CUTOVER.md` 路径 B 的 5 项确认尚未得到 PO 回答
- 新基线无代码、无 CI、无签名/隐私/发布证据；目前只是**文档级骨架**
- 我未核实 `chbearxiong` 与组织的关系，也未验证第二台自托管机器

## 6. 希望审查者回答的问题

1. 假设 1 是否成立？是否真的从未向非 PO 自然人分发过构建？
2. 第 8 节列出的边界丢失，哪些必须补回、哪些可以接受？（此项已由起草方自检给出候选答案）
3. 被简化掉的治理约束里，有没有哪条其实是安全 / 数据 / 隐私必需项？
4. 是否存在我未发现的第四套产品权威路径？
5. orphan 分支 + 中性提交身份，是否符合你对「从 0 开始」的预期？

## 7. 身份边界说明

本机 `gh` CLI 登录 `chramboliao`，推送与只读 API 调用均以该凭证发起——这是**凭证 / 操作身份**，与 git author 不是一回事。`chbearxiong` 是审查者账号，我未接触、不需要其凭证，也不在另一台机器上继承任何会话上下文。

**身份误用（18:12 复核确认）**：第 2、3 个 commit（`1e16a32`、`fd0404b`）的 author / committer 被起草方误设为 `chramboliao <144546498+chramboliao@users.noreply.github.com>`。依据不足：把 PO 的「你使用 chramboliao 在这个新分支工作」过度推断为 git author，而该表述指的是操作身份；邮箱字符串取自 `develop` 已有 merge commit 的 author 行，格式合法、id 与账号匹配，但归属不当。GitHub API 确认这两个 commit 的 `github_author` / `github_committer` 均解析为 `chramboliao`，`verification.verified = false (unsigned)`。**实际起草者是 WorkBuddy，PO 未参与起草**，这两条 commit 不构成 PO 对内容的背书。

按 PO 选择的**方案 A**：不 rewrite history、不 force push，attribution 保留，以更正 commit 与第 11 节作可追溯记录。自更正 commit 起，起草方 commit 一律使用中性占位 `greenfield-draft <greenfield-draft@localhost>`（仅 `git -c` 临时指定，未写配置），不代表任何账号；种子提交 `1894a4d` 同样是中性占位，保持不改。若 PO 希望改用明确的 bot 身份或由本人提交，需另行指定。

## 8. 上游稳定性自检（第一性原理，17:35）

按「越上游越要清晰稳定」的要求，我把 `Docs/PRODUCT.md` 的 11 条 Must 逐条回链到 `develop` 的 effective `release-1-prd.md` §3.1 M1–M10 与裁决表。**结论：主干覆盖，但边界大量丢失。**

| 环节 | 丢掉的上游约束 | 下游会怎么出错 |
| --- | --- | --- |
| 采集 | C2-Image「内容真相是用户确认裁剪/方向后的 App-managed 可读图片；不承诺原始字节或完整分辨率」；OCR 支持印刷体简中+英文、结果可见可编辑、不承诺手写/公式/答案准确率 | 实现可能去保原始字节，或把 OCR 当成保存前置 |
| 故障路径 | M3 的「输入取消」 | 取消路径无人验，出现半成品 |
| 导出 | D2-A「基础 PDF 不含封面」「空选择渲染前失败」「取消不留部分 App-owned 输出」「已保存到 App 外部的副本不承诺回滚」；C6-A §3「打印必须真实系统预览与打印验证，分享/保存不能替代」 | 我把打印写成并列出口，**弱化了它是独立正式终点** |
| 备份/恢复 | M7 的「超限/恶意备份不崩溃、不穿越文件边界、不静默覆盖」；M8 独立一项（store 打不开时明确知情后可选空库继续）；DATA-1-R 事件材料清理规则；D1-B `.snapdrillbackup` 格式裁决；D3-B inventory 精确表示缺失图片 | M8 被我塞进 A6，恢复语义与事件材料生命周期没有唯一 owner |
| 隐私 | M9「清楚说明本地存储、卸载丢失、手动备份责任；公开隐私声明与数据流一致」；C6-A §5 隐私声明/entitlements/AX 与 binary 一致 | EXIF GPS 只是其中一条，隐私声明与构建一致性无人验 |
| 隐藏能力 | Capability Manifest 的 `audience: po-only / research / public-candidate` 三段式；manifest 只能缩小范围、不能新增产品权威；旧 build 证据不继承 | 逐 build 的可见性边界无契约 |
| 发布 | C1-A 三阶段证据、C6-A §2 同一 build lineage（source commit / Marketing Version / Build / ASC build ID）、§8 结果级验收双向追溯、S0–S3 门禁 | **整条发布证据链被我简化掉了**，这是 M1–M10 之外最重要的结果级约束 |
| 验收追溯 | §8「每个 Must 至少 1 个结果 oracle，每个测试/勾选项都能指回 Must，无孤儿勾选项」 | `ACCEPTANCE.md` 只做了单向 Must→用例，缺反向声明与孤儿检查 |

### 三条自我批判（请优先攻击）

1. **「产品语义未改变」这个声明不准确。** 准确说法是「主干未变、结果级边界有丢失」。我在 `PRODUCT.md` 里写「语义来源：提炼与重组，产品语义未改变」，这会被下游当成「可以按精简版实现」的许可——正是上游不稳造成下游各自补解释的典型。
2. **我把最防污染的一条规则删了。** `document-control.md` 的「关键事实必须有唯一 owning tracked source，聊天/agent 私有记忆/仓库外报告不得成为唯一持有者」，是防止两台机器、多个 agent 各自把结论沉进对话记忆的核心机制。而这次分工的目标恰恰是「不被上下文污染」——**我的简化与目标直接冲突**，这是第一性原理层面的自相矛盾。建议轻量补回，不恢复 106 份文档与 registry：一条规则即可，见第 9 节。
3. **发布证据链不该被当包袱。** 它是「上游结论能被下游独立验证」的唯一保障；当前无用户、未发布，不代表首次分发时不需要。

> 以上修正我**没有擅自写回 `PRODUCT.md`**，留给 PO / 审查者裁决：产品语义与边界的取舍属于上游裁决权，不该由起草 agent 单方面决定。

## 9. 对抗性工作协议

**角色隔离**

| 方 | 身份 / 环境 | 职责 |
| --- | --- | --- |
| 起草 | `chramboliao` 凭证，本机 Windows，分支 `greenfield/rebuild-from-zero` | 起草、落地、自证 |
| 审查 | `chbearxiong`，另一台 MacBook Air，独立 clone | 独立复核、反驳 |

两边不共享会话上下文；**唯一交叉面是 GitHub 上的分支与 tracked 文件**。其他可能出现的智能体同样只读 tracked 文件，不继承任何一方对话。

**事实归属（建议补回 ENGINEERING.md 的轻量规则）**

> 影响产品、数据、验证或发布的关键结论，必须落到本分支的 tracked 文件，且每条有唯一 owner 文件；聊天、审查意见、agent 私有记忆、仓库外报告只作发现入口，不成为事实持有者。

**每个环节的第一性原理准入判据**

1. 这条产出回答的是什么问题？能否一句话说清
2. 结论是否可证伪？有没有可观察的验证方式
3. 下游会依赖它吗？依赖处是否无歧义、无第二种合理解释
4. 是否有唯一 owner 与明确的变更规则
5. **上游错了，下游能不能发现**——而不是各自补解释

**审查规则**

- 每条反驳必须给 `path:line` 或可复现命令；不接受「我认为」
- 被推翻的项**回到上游修正**，不在下游打补丁
- 审查意见落到 GitHub review / issue，不落到聊天
- 起草方对每条反驳给出「接受 / 拒收 + 依据」，并更新 tracked 文件

## 10. 如何在 GitHub 上审查这个分支（重要限制）

**这是 orphan 分支，与 `develop` 无共同祖先。** GitHub API `compare/develop...greenfield/rebuild-from-zero` 实测返回 `404 No common ancestor between develop and greenfield/rebuild-from-zero`。因此：

- **无法创建与 `develop` 对比的 PR**，也没有行级 PR review 界面
- 远端分支文件树与 commit 本身正常可读（已核验：根 4 项、Docs 4 份）

| 审查方式 | 入口 / 命令 |
| --- | --- |
| 文件树直接审 | `https://github.com/NotBad-Labs/snapdrill-ios/tree/greenfield/rebuild-from-zero` |
| 对 commit 留言 | `https://github.com/NotBad-Labs/snapdrill-ios/commit/1e16a322b2e2f81bb711ff9b8a8d68d915c9f5cb` |
| 本地完整 diff | clone 后 `git diff develop..origin/greenfield/rebuild-from-zero --stat`（起草方本机已验证：`725 files changed, 401 insertions(+), 102376 deletions(-)`） |

`REVIEW.md` 第 2 / 5 / 6 / 8 / 9 节是审查靶子；请按第 9 节规则把反驳落到 GitHub commit comment 或 issue，**不落到聊天**。

若确需 PR 行级 review，可另建一个**以 `develop` 为父、内容相同**的镜像分支（不动 orphan），代价是继承旧历史——需 PO 决定，起草方不擅自执行。

## 11. 身份误用更正记录（方案 A，18:19）

| 项 | 内容 |
| --- | --- |
| 受影响 commit | `1e16a32`、`fd0404b`（第 2、3 个） |
| 误设 author / committer | `chramboliao <144546498+chramboliao@users.noreply.github.com>` |
| 依据 | 仅 PO 的「你使用 chramboliao 在这个新分支工作」，被起草方**过度推断**为 git author 身份；该表述实际指凭证 / 操作身份 |
| 邮箱来源 | `develop` 已有 merge commit 的 author 行；格式合法、id 与账号匹配，但归属不当 |
| GitHub 实际归属 | `github_author` / `github_committer` = `chramboliao`；`verification.verified = false (unsigned)` |
| 事实 | **实际起草者为 WorkBuddy，PO 未参与起草**；这两条不得读作 PO 的工作或产品裁决 |
| 处置 | PO 选择方案 A：**不 rewrite history、不 force push**；attribution 保留，以本条更正 commit 与本节作可追溯记录 |
| 后续约定 | 自本条 commit 起，起草方 commit 一律用中性占位 `greenfield-draft <greenfield-draft@localhost>`，不代表任何账号、不写配置 |
| 未解决 | GitHub 贡献图与 commit 页面的归属不会因本更正改变；若 PO 要干净归属，需另选方案 B（改 author + `push --force-with-lease`），且应在审查开始前进行 |

**给审查者**：请把 `1e16a32` / `fd0404b` 的 author 字段视为无效元数据，以本节与 commit message 为准。

### 账号关系（18:12 API 核查，供复核）

| 名称 | GitHub 类型 | id | 角色 |
| --- | --- | --- | --- |
| `NotBad-Labs` | **Organization** | 260572809 | 仓库 owner；**组织本身不能作 git author** |
| `chramboliao` | User | 144546498 | PO 个人账号 |
| `notbad-admin` | User | 261622919 | 同为 User；`develop` 最近 100 提交里 65 个归它，疑似服务 / 自动化身份 |
| `NotBad Labs L.L.C.` | 法律实体名称 | — | 见于版权声明，非 GitHub 账号 |

git 里只有 `name <email>`，GitHub 按 email 关联到 User 账号；三个身份（`author` / `committer` / pusher）可以不同，不应混为一谈。本次误用的根因正是把 pusher 当成了 author。

---

*本文件为新基线内的审查交接材料，随分支推送，未合入、未开 PR；旧仓库 `develop` 未受影响。*
