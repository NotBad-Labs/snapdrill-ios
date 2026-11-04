# 切换策略：从旧仓库到 greenfield

> 原则：新分支上做破坏性重构。不 force push、不 rewrite history、不改 `develop`。
> 状态：路径 A 已经是当前工作面 `greenfield/rebuild-from-zero`

---

## 路径 A · 可逆（推荐）

1. 新建独立分支（如 `greenfield/rebuild-from-zero`）或独立仓库，从**空目录**开始
2. 种子是本分支的 `Docs/PRODUCT.md`。不复制旧文档，不继承旧裁决
3. `develop` 原样保留，不做删除
4. 阶段 0 书面确认前，不把新基线切成主干

## 路径 B · 替换原仓库

需 PO 逐项书面确认：

| # | 要确认的事 | 为什么 |
| --- | --- | --- |
| 1 | 目标：替换 `snapdrill-ios` 的 `develop`，还是新建 repo？ | 决定影响面 |
| 2 | 旧历史归档到何处、保留多久、如何回溯 | 30 项 PO 裁决与 M1–M10 证据链目前只存在于旧仓库 |
| 3 | 阶段 2 的备份格式是否已冻结 | 用户承诺在 `PRODUCT.md` 结果 6。文件格式不在阶段 0。第一次让非负责人安装之前，格式必须已经冻结 |
| 4 | cutover 失败的恢复点与责任人 | 无验证通道时尤其关键 |
| 5 | 验证：`mac-mini` 上线且工具链对齐后再切换 | 当前 runner offline，本机无 Apple 工具链 |

## 我不会执行的动作（即使「全部授权」）

- 在远端删除或覆盖 `develop` 内容、`git push --force`、rewrite history、删除分支
- 把 PR #983 转 Ready / merge、触发 archive / TestFlight / 上传 / 发布
- 首次对外分发前未冻结数据兼容契约就发布
- 在本机跑构建（Windows 无 Apple 工具链）

这些动作不可逆，而且会影响公开仓库。本分支目前没有可运行的验证对象。重构不迁移旧数据；这不构成对外发布的授权。

## 当前可以做的事

阶段 0：改 `Docs/PRODUCT.md` 和 `Docs/ACCEPTANCE.md`。不写代码，不从旧仓库回补需求。

阶段 0 书面确认之前，不切主干，不写实现，不生成 CI，不上传。

替换 `develop` 仍要走路径 B 的逐项确认。runner 上线只影响以后的验证，不影响现在写产品定义。

---

*切换策略。破坏性重构留在本分支；`develop` 不改。*
