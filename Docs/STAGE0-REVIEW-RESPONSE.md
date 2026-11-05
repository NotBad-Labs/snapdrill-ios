# 对 `6b7e3d1` 的审查回应 · 阶段 0

> 回应对象：chbearxiong 的 commit `6b7e3d1cb742fec1529508ac8abce3720b075126`
> 依据：`REVIEW.md` 第 9 节「对抗性工作协议」——每条判定给依据，被推翻项回上游修正
> 起草方：greenfield-draft（中性占位），2026-11-05 09:00
> **状态：已随 `greenfield/rebuild-from-zero` 分支提交**（11-05 17:46）。此前 17:41 的尝试因本机 TLS 出站被重置而失败，第 6 节保留诊断记录，仅作证据留存。

---

## 0. 反馈是什么

不是文字评论，而是**直接往同一分支推的一个 commit**：

| 项 | 值 |
| --- | --- |
| sha | `6b7e3d1`，parent = `edaeea8`（我方最后一个 commit） |
| author / committer | `chbearxiong <152695047+chbearxiong@users.noreply.github.com>` |
| 时间 | 2026-11-04T12:52:56Z（北京时间 20:52） |
| message | 「The rebuild needs one reviewable product baseline before implementation… **without treating the old docs as input**」 |
| 附加 | `Co-authored-by: Cursor <cursoragent@cursor.com>` |
| 改动 | 6 个文件全部 modified：PRODUCT.md(+131/−51)、ACCEPTANCE.md(+19/−45)、CUTOVER.md(+12/−27)、ENGINEERING.md(+5/−5)、README.md(+11/−11)、REVIEW.md(+2) |

同期核查：issue comments（空）、PR 列表（无新 PR）、该 commit 的 commit comments（空）、`users/chbearxiong/events/public`（空数组）。**所有反馈都在这一个 commit 里**。

`REVIEW.md` 顶部新增的工作约定明确：本分支做破坏性重构，阶段 0 产品权威是 `Docs/PRODUCT.md`，旧仓库文档不再回补；下文「产品语义未改变」「把丢失边界写回旧 PRD」停在当时的自检，不再指导这次重构。

---

## 1. 接受（6 项）

| # | 对方改动 | 判定依据 |
| --- | --- | --- |
| A1 | **旧文档不作输入**，PRODUCT.md 是唯一产品权威 | `Docs/PRODUCT.md` 开头「权威：本文件是这条重构的唯一产品权威。旧仓库文档不是输入」。这直接否决我 11-04 第 8 节「把丢失边界写回旧 PRD」的建议——**产品裁决权在 PO，我作为起草方无权指定载体**，判定合理。 |
| A2 | **阶段 0 产品契约整体重写** | 我 11-04 自检发现的边界，新版几乎全部在新契约里**原生写清**了，不是回补：结果 2 = C2-Image 内容真相 + OCR 简中/英文 + 不承诺手写公式答案；结果 5 = D2-A PDF 细节 + 打印不可由分享替代；结果 7 = M3「用户取消采集」；结果 6/7 = M7/M8 恢复语义；结果 9 = M9 隐私三件事；§6.3 = Capability 三段式 + C6-A 同 build lineage；§6.2 = ORI-A 竖屏 + #932-A 兼容分发退出；§7 第 1、2 条 = 结果级双向追溯。**自检内容被采纳，载体被换掉**——这是对抗性工作该有的结果。 |
| A3 | 设备矩阵按设备族、不按机型 | §6.2「机型清单会随苹果更新失效，不能当作产品基线」。第一性原理的直接应用，接受。 |
| A4 | 禁用远程开关与百分比灰度 | §6.3「本产品没有内容后端，运行时灰度会变成一套无法验收的隐藏通道」；且末段已写「已发布的版本不能撤回，修正靠新构建」，自洽。 |
| A5 | 备份格式归阶段 2、不读旧备份 | §6.4 与 CUTOVER 路径 B 第 3 项一致；与我 11-04「数据兼容降级为首次分发前冻结」的结论相容。 |
| A6 | 作者身份做法 | 本人账号 + `Co-authored-by: Cursor`，正是 11-04 讨论后我给出的推荐做法。建议写入协议：起草方中性占位、PO 本人账号、智能体用 co-authored-by。 |

**拒收：0 项。** 这些都属产品裁决与工作方式，是 PO 权限；我没有拒收依据。

---

## 2. 需澄清（5 项，非拒收）

| # | 残留不一致 | 可复核位置 | 建议 |
| --- | --- | --- | --- |
| C1 | **REVIEW.md 假设表仍停在旧语境** | 第 2 节假设 2「`docs/product/` 是唯一 effective 产品权威」、假设 4「产品语义应保持不变，只做重组精简」均已被 `6b7e3d1` 推翻或改了作用域；第 5 节薄弱点、第 6 节待答问题同样。顶部两行约定只笼统点名了两句 | 明确标注「第 2、5、6、8 节为 11-04 自检的历史快照，仅作证据，不指导本次重构」，或逐条更新作用域 |
| C2 | **阶段 0 / 阶段 1 边界模糊** | `CUTOVER.md`「阶段 0：改 PRODUCT.md 和 ACCEPTANCE.md」、`PRODUCT.md` §7「用例在 ACCEPTANCE.md」；但 `ENGINEERING.md` 阶段 1 准出仍是「每条需求有可观察验收结果」 | 明确阶段 1 到底产出什么（单功能 spec？接口契约？），否则该准出与阶段 0 重复 |
| C3 | **ACCEPTANCE.md 删掉了 T1–T4 映射与环境阻塞说明** | 新版只剩「低层验证通过，不等于本表通过」；而 `ENGINEERING.md` 仍保留 T0–T4 表。Windows 无 Apple 工具链、`mac-mini` offline 这两条事实在验收文件里消失 | 恢复两节或交叉引用 `ENGINEERING.md`；另一台 Mac 上的审查者需要知道「为什么现在跑不了」 |
| C4 | **CUTOVER 路径 B 第 2 项理由失去支点** | 仍写「30 项 PO 裁决与 M1–M10 证据链目前只存在于旧仓库」——但新约定是旧文档不再回补 | 删除，或改为「旧仓库仅作历史归档，不作为本次输入」 |
| C5 | **「关键事实唯一 owner」仍未成为规则** | `PRODUCT.md` §8 只固定了产品语义的 owner（本文）；数据契约、隐私契约、发布证据的 owner 文件未指定，§6.4 把备份格式推到阶段 2 | 阶段 0 可接受，但应列为**阶段 2 的显式前置**，否则会重演 11-04 自检里「下游各自补解释」 |

---

## 3. 阶段 0 准出检查

按 `PRODUCT.md` §7 的 5 条验收判据与 §2 的准出条件逐条核对：

| # | 判据 | 状态 |
| --- | --- | --- |
| 1 | 只凭第 4 节能写出用例 | ✅ `ACCEPTANCE.md` A1–A11 对应结果 1–11 |
| 2 | 每条用例能指回第 4 或第 6 节，无孤儿 | ✅ 有「结果」列；⚠️ A10 涉及 §6.2 竖屏，但该行只写「10」，未写 §6 引用 |
| 3 | 新用户不用讲解完成链路，且单独完成打印 | ❌ 未执行（无构建） |
| 4 | 草稿 / 撤销 / 库打不开 / 备份损坏不静默丢数据 | ❌ 未执行（无构建） |
| 5 | 公开候选没有未批准能力的入口、运行或副作用 | ❌ 未执行（无构建） |
| 准出 | **书面确认 `PRODUCT.md`** | ❌ 尚未发生，状态仍是「候选契约，待审查」 |

**结论：文档形态的阶段 0 已完成，但关卡未通过。** 这与 `CUTOVER.md`「阶段 0 书面确认之前，不切主干，不写实现，不生成 CI，不上传」一致。因此本轮**不进入阶段 1、不写代码**。

---

## 4. 本轮我不做的事

- 不改 `Docs/PRODUCT.md`（PO 产品权威）、不把 C1–C5 擅自写回任何上游文件
- 不写代码、不生成 CI、不切主干、不上传、不 force push、不 rewrite history
- 不用 GitHub Contents API 绕过身份约定直接写远端（会再次产生 author 归属问题）
- 不以 `chramboliao` 或 `chbearxiong` 身份提交

---

## 5. 待 PO / 审查者回答

1. C1–C5 五项，逐条给「接受 / 修改 / 说明为何保留」
2. 阶段 0 是否**书面确认**？确认前一切实现工作暂停
3. 若确认，阶段 1 的第一个产物是什么（C2）
4. `mac-mini` 是否已上线？未上线则第 3 节 3–5 项无法执行（C3）

---

## 6. 提交记录（失败诊断仅作证据）

### 11-05 17:41 尝试失败

远端 HEAD 复核仍为 `6b7e3d1`（**无新提交**），本地 HEAD 仍为 `edaeea8`、工作树干净。四条本机写通道全部失败：

| 通道 | 结果 |
| --- | --- |
| `git fetch` / `clone`（默认 schannel） | `schannel: failed to receive handshake, SSL/TLS connection failed` |
| `git -c http.sslBackend=openssl`、`http.version=HTTP/1.1`、绕过代理直连 | `TLS connect error: unexpected eof while reading` / 同样握手失败 |
| `curl`（走代理与 `--noproxy '*'` 均试） | `(35) schannel: failed to receive handshake`，`http_code=000`；`api.github.com` 同样 |
| `gh api`（6 次重试）、PowerShell `Invoke-RestMethod` | `EOF` / 「基础连接已经关闭: 发送时发生错误」 |

`HTTP_PROXY` / `HTTPS_PROXY` 均已设置，`git config http.proxy` 为空；直连与走代理都失败，说明是本机 TLS 出站被重置，不是凭证或权限问题。只读 `WebFetch` 通道正常，故反馈内容可完整读取，**但当时写操作无法完成**。未使用任何绕过身份约定的 API 写远端；本地副本工作树保持干净，远端未被改动。

### 17:46 重试成功

`git fetch` 恢复，本地 `merge --ff-only` 快进到 `6b7e3d1`，本文件以 `Docs/STAGE0-REVIEW-RESPONSE.md` 落入分支，用中性 `greenfield-draft` 身份 commit 并普通 push；未 force、未 rewrite history、未改动 `develop`。

### 当时的恢复命令（已执行，留存备查）

```bash
cd snapdrill-ios
git fetch origin greenfield/rebuild-from-zero
git merge --ff-only origin/greenfield/rebuild-from-zero
# 将本文件复制到 Docs/STAGE0-REVIEW-RESPONSE.md，或把第 1–5 节合并进 REVIEW.md
git add -A
git -c user.name="greenfield-draft" -c user.email="greenfield-draft@localhost" \
  commit -m "review: response to 6b7e3d1 (accept 6, clarify 5, stage 0 exit not met)"
git push origin HEAD:refs/heads/greenfield/rebuild-from-zero
```

提交后本地与远端 HEAD 一致，工作树干净。

---

*已随 `greenfield/rebuild-from-zero` 分支推送供审查；阶段 0 仍待书面确认，未 effective；`develop` 未改动。*
