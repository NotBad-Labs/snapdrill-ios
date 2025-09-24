# NotBad 发布与版本规范（简版）

> 适用分支模型：Git Flow（main ← release/* ← develop ← feature/*；hotfix/* 来自 main）

## 版本号规范

- 采用语义化版本（SemVer）：`MAJOR.MINOR.PATCH`，例如：`6.0.0`
- 适用场景
  - `MAJOR`：不兼容变更或重大里程碑
  - `MINOR`：向后兼容的新功能
  - `PATCH`：向后兼容的问题修复
- 构建号（Build Number）：写入 `Info.plist` 的 `CFBundleVersion`，用于区分同一版本的多次构建（整数自增）

## 分支与发布流程

1) Feature → Develop

- 从 `develop` 切出 `feature/<name>`，完成后提 PR 到 `develop`

1) Develop → Release → Main

- 从 `develop` 切出 `release/x.y.z`
- 在 `release/x.y.z`：冻结新特性，仅允许修复、版本号与文档变更
- 在 `release/x.y.z`：执行版本号与变更日志更新（见下文脚本）
- 提 PR：`main ← release/x.y.z`；合并后在 `main` 打标签并发布
- 回灌：将 `release/x.y.z` 合并回 `develop`

1) Hotfix → Main（→ Develop）

- 从 `main` 切出 `hotfix/x.y.z+1`
- 修复后提 PR：`main ← hotfix/x.y.z+1`；合并并打标签发布
- 回灌：将 `hotfix/x.y.z+1` 合并回 `develop`

## 必备文件

- 根目录 `VERSION`：当前应用版本（例如 `6.0.0`）
- 根目录 `CHANGELOG.md`：遵循 "Keep a Changelog" 模式

## 自动化脚本：版本与变更日志

提供脚本：`Scripts/bump_version.py`

功能：

- 读取/更新根目录 `VERSION`
- 更新 `NotBad/Info.plist` 中：
  - `CFBundleShortVersionString`（显示版本，例如 6.0.1）
  - `CFBundleVersion`（构建号，整数自增或指定）
- 更新 `CHANGELOG.md`：插入新版本节（日期为当天），包含 `Added/Changed/Fixed` 占位

用法示例：

```bash

# 1) 从当前版本按照补丁位递增（6.0.0 → 6.0.1），构建号自增

python3 Scripts/bump_version.py --part patch

# 2) 指定版本号（例如从 6.0.1 直接设置为 6.1.0），构建号自增

python3 Scripts/bump_version.py --set 6.1.0

# 3) 同时指定构建号

python3 Scripts/bump_version.py --part minor --build 42
```

执行后检查：

- `VERSION` 更新为新版本
- `NotBad/Info.plist` 的 `CFBundleShortVersionString` 与 `CFBundleVersion` 已更新
- `CHANGELOG.md` 追加了 `## [x.y.z] - YYYY-MM-DD (Build N)` 的新节（如果 `Info.plist` 已存在构建号，则会在标题追加构建号；再次执行会更新为最新构建号，具备幂等性）

### 可选：从 Git 提交生成 CHANGELOG 草稿

- 脚本：`Scripts/generate_changelog_from_git.py`
  - 根据 conventional commits（feat/fix/docs 等）在两个引用（tag/commit）之间生成分组段落
  - 示例：

  ```bash
    # 以 tag v6.0.0 之后至当前 HEAD 的提交生成草稿

    python3 Scripts/generate_changelog_from_git.py --since-tag v6.0.0 > /tmp/changelog_snippet.md
    # 粘贴到 CHANGELOG.md 对应版本节下，按需润色

  ```

  - CI 集成：在 release/hotfix PR 上，工作流会生成片段并自动插入到当前版本节；同时会在片段前加入 `Build: <构建号>` 行（来自 Info.plist 的 `CFBundleVersion`），并且会将该版本节标题更新为 `## [x.y.z] - YYYY-MM-DD (Build N)` 的形式（若已包含 Build 则覆盖为最新构建号）。此外，CI 会校验：

    - `VERSION` 与 `Info.plist` 的 `CFBundleShortVersionString` 一致
    - `CHANGELOG.md` 存在对应版本节，且标题包含 `(Build N)` 并与 `Info.plist` 的 `CFBundleVersion` 相匹配

## 发布检查清单（Release PR）

- [ ] `VERSION` 更新到目标版本
- [ ] `CHANGELOG.md` 填写了本次发布的变更条目
- [ ] `Info.plist` 版本号与构建号已更新
- [ ] CI 全绿（代码质量、测试、文档、链接检查）
- [ ] 合并后在 `main` 打 Git 标签，并产出构建（TestFlight/App Store）
