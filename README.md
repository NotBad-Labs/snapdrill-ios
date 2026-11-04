# SnapDrill · greenfield baseline（本地草稿）

> 分支：`greenfield/rebuild-from-zero`，**orphan 分支**，无父提交、从零历史
> 状态：未推送、未发布、未 effective、未 ratify；**不是产品决策**，不替代 `develop`
> 用途：供对抗性审查；不构成第二套仓库内权威

---

## 从 0 开始，不背包袱

本分支**不继承**：106 份旧文档、30 项裁决台账、五态决策生命周期、Gate B/C/P 编号、Current Admission 五字段 brief、frozen merge queue、WIP ≤ 2、exact-head 授权、`document-control.json` registry、生成索引与三套文档门禁、多 agent lane / cross-audit / 反哺协议、历史审计目录。

产品语义沿用 effective 文档（`docs/product/vision.md` + `release-1-prd.md`）的提炼重组，**未改变**；若要改产品语义，需 PO 单独书面裁决。

## 内容

| 文件 | 用途 |
| --- | --- |
| `README.md` | 本文件，新基线入口 |
| `Docs/PRODUCT.md` | 一句话定位、核心价值链、耐久边界、11 条 Must outcomes、明确非目标、验收判据、简化变更规则 |
| `Docs/ENGINEERING.md` | 6 阶段链路、T0–T4 验证分层、三条硬规则、被简化掉的旧包袱清单、环境事实 |
| `Docs/ACCEPTANCE.md` | 11 条 Must 的可执行验收用例、T1–T4 映射、完成报告六项 |
| `Docs/CUTOVER.md` | 路径 A 可逆新建、路径 B 替换、红线、分层触发条件 |
| `REVIEW.md` | **对抗性审查交接**：假设清单、未做的事、可复核命令、已知薄弱点 |
| `.gitignore` | Xcode / SwiftPM / 签名材料忽略规则 |

工作区 `../greenfield/` 保留一份对照副本，内容与 `Docs/` 一致。

## 当前状态

- **无代码、无构建配置、无 CI 接线、无签名与发布证据**
- `ACCEPTANCE.md` 全部用例均**未执行**：本机 Windows 无 Xcode/swift/swiftlint/fastlane，self-hosted runner `mac-mini` 当前 offline
- 已确认当前无外部用户、App 从未发布，因此不涉及存量数据迁移
- `develop` 分支及其 720 个文件**原样保留**，未删除、未修改；远端未做任何写操作

## 恢复与切换

```bash
git checkout develop                       # 回到旧基线
git diff develop..greenfield/rebuild-from-zero --stat   # 审查完整差异
```

切换策略与触发条件见 `Docs/CUTOVER.md`。

---

*本地草稿，未推送；本次提交作者为中性占位 `greenfield-draft`，不代表任何 GitHub 账号。*
