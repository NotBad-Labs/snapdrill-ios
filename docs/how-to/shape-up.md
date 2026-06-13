# 我们怎么工作：Shape Up（单人 + 强 AI 改编版）

> **本项目整套采纳 Shape Up**（Ryan Singer / Basecamp，免费全文 <https://basecamp.com/shapeup>）。
> 这是**一个完整、成熟、有文档的体系**——不是几家糅合的自创物（教训见为何只采一个标准）。
> 本文只写**我们的改编 + 操作约定**，不复述全书；概念以原书为准。

## 为什么是 Shape Up（而不是别的）

PO 的痛=「大致知道**建什么**，但不清楚**怎么建/步骤**」=交付层问题 → Shape Up（交付节奏体系）。
4 方异源读原典 + 主笔精读收敛。Shape Up 治的是「**做不出 / 做不完**」的风险，**不治「做错产品」**（原书 Introduction「Targeting risk」）——所以见下面那条不可省的纪律。

## 单人 + 强 AI 的改编（依据原书附录「Adjust to Your Size」）

原书附录明说：极小团队**砍掉仪式**（正式 betting table、固定 6 周、多人会议、cool-down 可省），**只保留四阶段 + appetite + pitch + scopes + hill chart + circuit breaker**，关键是**自觉切「现在戴哪顶帽子」**。

| 阶段 | **你**（判断/品味，AI 替不了） | **AI agents（按 [`parallel-lanes.md`](parallel-lanes.md) lane 分工）**（起草/维护/执行/纪律） |
|---|---|---|
| **Shaping** | 定 appetite、收窄问题、拍板取舍、画 breadboard | 起草 pitch、当 shaping 的「技术专家」对照代码挑 rabbit holes、补洞 |
| **Betting** | 自问原书 Ch.9 五问、承诺只赌这个不插队 | 维护「当前赌注」、拦范围蔓延 |
| **Building** | 选第一刀竖切、scope hammer、对 baseline 决定停 | 接**整个项目**(非任务清单)、先打通端到端 slice、按结构划 scopes、维护 hill chart、逐 slice 实现 |
| **Cool-down** | 读反馈但不当场答应 | 修 bug、归档、起草下个 pitch |

## 节奏与纪律

- **周期长度**：起步 **2–4 周**（不是 6 周）。赌注可大小不一（原书附录允许）。WIP=1（一次只赌一个主项目）。
- **三个模式**（原书 Ch.9 New products）：**R&D**（核心流程还不确定→赌 spike，不指望出货）/ **Production**（流程已能点通→周期末出 TestFlight 增量）/ **Cleanup**（上架前打磨）。本项目核心闭环 ~90% → 多在 **Production**。
- **🔑 不可省的纪律（PMF 前）**：**每个 bet 必须绑一个学习目标**。这是 Shape Up 不覆盖的「做错产品」风险的补丁——betting 时除了问「做得完吗」，还要问「这若成功，改变哪条赌注（assumptions.md 的 H#）的置信度？用什么可观察信号？」答不出就别赌。
- **质量地板（ship 的判据，原书 Ch.14 Compare to baseline）**：当它**比用户当前替代方案更好**就 ship，不是完美时。对要拿 PMF 信号的目标用户，地板 = **不崩 + 核心路径可靠 + 像模像样 + EXIF/隐私扎实**；不是每个 edge case/动画完美。先你自己 dogfood 过地板，**再**邀真实用户（内测用户也是用户、且稀缺不可再生）。
- **circuit breaker**：到期不延期。没做完=shaping/scope 错了，打回重塑，不加时间。
- **appetite ≠ 估算**：先定时间，再设计塞得进的方案（原书 Ch.3）。
- **no-gos 必写**：否则 AI 会「顺手完善」。

## 制品（就这几样，AI 维护）

- **Bet / Pitch** → PO 明确接受的 live GitHub issue / PR，或 PO 指定的具名范围文档；固定包含 Problem / Appetite / Solution / Rabbit holes / No-gos（原书 Ch.6）。
- **Scopes** → 在 bet 或 building 中，按产品结构竖切（非前后端分工，原书 Ch.12）。
- **Hill chart** → 一段文本即可：每个 scope 标 `uphill(还在解未知)` / `downhill(只剩执行)`，AI 每 2-3 天更新（原书 Ch.13）。
- 不需要 Basecamp 的专属工具；Markdown + git 即可。

## ⚠️ 不删能跑的代码

「轻装上阵」=**冻结未验证功能的规划重量**（停止往里投入），**不是删字节**。代码价值的判据来自 live code、测试与构建实证，不来自任何 agent 私有记忆。**复习/SmartPaper/Pro 等是「焊死的未验证赌注」→ 进下面的 Parked、停止投入、但一行别删。**

---

## 怎么确定「现在赌什么」

本文件**不固化某个具体周期的进行中赌注**——那会随时间过期且依赖「最新文件名胜出」的脆弱约定。当前赌注的唯一可信来源是**实证**：

- **优先**：当前活跃且已被 PO 接受的 GitHub issue / PR；需要更长说明时，由 PO 明确指定一份具名范围文档。
- 没有被接受的 live issue/PR 或具名范围文档时，先回到 shaping——别凭过期计划、文件名顺序或 agent 私有记忆开工。
- 逐功能权威状态以 [`../reference/feature-status.md`](../reference/feature-status.md)（SSOT，自动生成）为准，不在本文件重复罗列。

### Parked（明确不赌、停止投入，但代码留着 · 取舍的牙齿）

哪些功能被冻结、哪些是阻塞依赖，以 `feature-status.md` 的 frontmatter 与 live GitHub issues 为准，例如：

- 复习/SM-2 增强、SmartPaper 组卷、高级统计 —— 未验证赌注（[`../explanations/assumptions.md`](../explanations/assumptions.md) H9），冻结。
- Pro/StoreKit #479、CloudKit #485、Word 导出 #486 等 —— 延后的外部/产品依赖，描述其状态前先核实 live Issues。
- 公开上架合规队列 —— **不阻塞 TestFlight 内测**（隐私/分析策略见 [`../decisions/ADR-005-analytics-privacy-strategy.md`](../decisions/ADR-005-analytics-privacy-strategy.md)），延到决定公开上架时。

### 链接
- 方法原典：<https://basecamp.com/shapeup>
- 为什么/愿景：[`../explanations/vision.md`](../explanations/vision.md)
- 待验证假设（赌注内容 + 推翻信号）：[`../explanations/assumptions.md`](../explanations/assumptions.md)
- 逐功能状态（SSOT）：[`../reference/feature-status.md`](../reference/feature-status.md)
