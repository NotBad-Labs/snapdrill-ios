# SnapDrill · greenfield baseline

> 分支：`greenfield/rebuild-from-zero`（orphan 分支，从零重构）
> 用途：破坏性重构的工作面。当前处于阶段 0（产品定义与技术验证），唯一产品需求权威为 `Docs/PRD.md`。

---

## 从 0 开始

本分支不读取、不调和、不继承旧仓库（`develop`）的文档、裁决编号和实现。

`Docs/PRD.md` 是本分支唯一的产品权威。要修改产品定位或需求范围，先修改 `Docs/PRD.md` 并经 PO 确认。

## 仓库文件

| 文件 | 用途 |
| --- | --- |
| `README.md` | 本文件，仓库入口说明 |
| `Docs/PRD.md` | 产品需求文档（v0.8）：产品做什么（**唯一产品权威**） |
| `Docs/ARCHITECTURE.md` | 架构与模块边界：怎么拆、多 Agent 并行规则、服务「合同」 |
| `Docs/DEVELOPMENT_PRINCIPLES.md` | 开发原则：不造轮子、不返工、P1–P10、Agent 检查清单 |
| `Docs/PR_TEMPLATE.md` | PR 描述模板（一 PR 一边界） |
| `Docs/STAGE0_CHARTER.md` | 阶段 0 章程：样张、指标、A/B/C 裁决表、与 v1.0 冻结条件 |
| `Docs/ROADMAP.md` | PO 里程碑路线图（非工程任务分解） |
| `Docs/STAGE0_SAMPLES.md` | 阶段 0 样张编号表（不含原图） |
| `Docs/STAGE0_COLLECTION.md` | 样张收集说明（给拍卷的人） |
| `.gitignore` | Xcode / SwiftPM / 签名材料忽略规则 |
| `project.yml` / `SnapDrill.xcodeproj` | iOS 工程（`xcodegen generate`） |
| `SnapDrill/` | MVP 应用源码 |
| `Docs/ENGINEERING.md` | 本地编译与 Slice 边界 |

## 当前状态

- `Docs/PRD.md`（v0.8）已就绪（PR #985 已合并）
- **默认分支**：`greenfield/rebuild-from-zero`（新产品与代码只在此线开展）
- **旧线归档**：`develop` 冻结只读；快照 tag `legacy/pre-greenfield-2026-11`（`develop` @ 2026-07-25）
- 远端已清理历史 Agent 分支；仍开放 **Draft PR #984**（`gemini/upgrade-xcode-27-toolchain`，须 retarget 到本分支）
- **执行策略**：方案 1 并行（见 `Docs/ROADMAP.md`）；**MVP Slice 1** 工程壳已入仓，打开方式见 `Docs/ENGINEERING.md`

## 分支策略（PO 2026-11-16）

| 分支 | 用途 |
| --- | --- |
| `greenfield/rebuild-from-zero` | 唯一开发主线 |
| `develop` | 旧实现考古，不新增功能 |
| `main` | 历史壳，可忽略 |
| `gemini/upgrade-xcode-27-toolchain` | 可选工具链 PR，合并前 retarget greenfield |

新工作：`feat/*`、`fix/*`、`docs/*`、`spike/*` 从 greenfield 切出，合并后删远端分支。

## 恢复与切换

```bash
git checkout develop                                    # 旧基线（只读参考）
git diff develop..greenfield/rebuild-from-zero --stat   # 与旧线差异
git show legacy/pre-greenfield-2026-11                  # 冻结快照
```
