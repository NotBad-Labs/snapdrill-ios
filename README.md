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
| `Docs/PRD.md` | 产品需求文档（v0.7）：产品定位、目标用户、核心流程、功能清单与优先级、订阅定价、品牌规范、合规与技术验证计划 |
| `.gitignore` | Xcode / SwiftPM / 签名材料忽略规则 |

## 当前状态

- `Docs/PRD.md`（v0.7）已就绪，旧版冲突草稿与过程审计文档已全部清理
- `develop` 分支原样保留，不在本次重构里修改或删除

## 恢复与切换

```bash
git checkout develop                                    # 回到旧基线
git diff develop..greenfield/rebuild-from-zero --stat   # 查看与旧基线的差异
```
