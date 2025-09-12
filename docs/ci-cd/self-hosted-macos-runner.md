## 自托管 macOS Runner（Mac mini）搭建清单 v1.0

本清单用于在本地或机房的 Mac mini 上部署 GitHub Actions 自托管 runner，以降低 iOS CI/CD 的托管运行成本，并提升可控性与稳定性。

### 一、硬件与系统建议
- 最小推荐：Mac mini M2，内存 ≥ 16GB，SSD ≥ 512GB，有线网络与稳定供电。
- 关闭睡眠：系统设置 → 节能 → 关闭睡眠/硬盘睡眠，允许显示器关闭时保持运行。
- 创建专用 runner 用户，避免与日常账号混用。

### 二、基础软件与工具
- 安装最新稳定版 macOS。
- 安装 Xcode 16.4，并预装所需 iOS 模拟器运行时（建议 iOS 18.6）。首次启动 Xcode 接受许可。
- 安装 Command Line Tools：`xcode-select --install`
- 安装 Homebrew 及常用依赖（按需）：`brew install git python swiftlint`

### 三、注册自托管 Runner
1. GitHub 仓库/组织 → Settings → Actions → Runners → New self-hosted runner（macOS）。
2. 按页面指引在机器上下载与配置 runner，可使用如下标签：
   - `self-hosted`, `macos`, `xcode-16-4`, `ios-18-6`
3. 安装为服务常驻运行（脚本 `./svc install`、`./svc start` 或使用 launchctl）。

### 四、安全与权限
- 该机器能接触仓库 Secrets。务必放在可信网络，限制物理与远程访问，runner 使用最小权限专用用户。
- Secrets 仅配置必要项（证书、描述文件、AppleID 等），定期轮换。

### 五、缓存与预置
- 预构建一次以填充缓存：
  - SPM：`~/.cache/org.swift.swiftpm`
  - DerivedData：`~/Library/Developer/Xcode/DerivedData`
- 预装目标模拟器（iOS 18.6），避免 CI 过程中下载运行时。

### 六、工作流（ci.yml）改造要点
- 将相关作业 `runs-on` 改为：`runs-on: [self-hosted, macos, xcode-16-4]`
- 可移除 `setup-xcode` 步骤或改为仅做版本校验。
- 去掉 `xcodebuild -downloadPlatform iOS`（已预装），保留 `xcrun simctl list devices` 诊断。
- 目的地统一为已安装设备：例如 `iPhone 16 Pro, OS=18.6`。
- 保留缓存步骤，确保缓存目录在自托管机器上持久化。

### 七、运维与保洁
- 定期清理：旧的 DerivedData、`~/Library/Developer/CoreSimulator/Devices` 中失效设备、日志与临时文件。
- Runner 监控：GitHub Runners 页面查看心跳；异常时 `./svc restart` 重启服务。
- 系统与 Xcode 更新：择机更新，注意与流水线的版本固定策略同步。

### 八、并发与扩展
- 单机建议 1 并发（UI/性能测试对资源较敏感）。需要更高并发时横向增加机器。
- 可混合架构：单测使用 GitHub 托管 runner，重作业（UI/性能/归档）走自托管。

### 九、成本粗算（示例）
- 设备一次性：Mac mini M2/16GB/512GB ~ 5k–8k RMB。
- 24 个月摊销 + 电费/维护：约 200–350 RMB/月（粗略估算）。
- 当托管 macOS 分钟账单长期高于该水平，自托管通常更划算。

### 十、风险提示
- 安全：自托管 runner 持有 Secrets，务必限制访问范围并做好账号与网络隔离。
- 稳定：需要你自行维护硬件、系统与工具链更新，以及磁盘空间与可用性。

附：示例 runs-on 片段（自托管）

```yaml
runs-on: [self-hosted, macos, xcode-16-4]
```

附：示例目的地（固定已装设备）

```bash
-destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'
```

如需迁移示例或一键脚本，请在 issue/PR 中 @ 我，我会补充对应自动化脚本与校验步骤。


