# GitHub Actions 自托管运行器完整设置指南

## 概述

本指南将帮助您在M4 Mac mini上设置GitHub Actions自托管运行器，利用群晖存储来优化iOS CI/CD流程，显著降低GitHub Actions的使用成本。

## 硬件配置要求

- **Mac mini M4**：16GB内存，256GB SSD
- **群晖NAS**：通过万兆光纤连接，约10TB存储空间
- **网络**：稳定的互联网连接和本地网络

## 系统架构

```
GitHub Actions (云端)
    ↓
GitHub Repository
    ↓
Self-hosted Runner (Mac mini M4)
    ↓
群晖NAS存储 (缓存、构建产物、日志)
```

## 安装步骤

### 1. 准备工作

#### 1.1 创建GitHub Personal Access Token

1. 访问GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击"Generate new token (classic)"
3. 选择以下权限：
   - `repo` (完整仓库访问权限)
   - `admin:org` (组织管理权限，如果是组织仓库)
   - `admin:repo_hook` (仓库钩子管理权限)
4. 保存Token，稍后安装脚本会用到

#### 1.2 配置群晖SMB共享

1. 在群晖DSM中创建共享文件夹：
   - 文件夹名称：`runner_data`
   - 权限：读写权限给CI用户
2. 启用SMB服务
3. 记录以下信息：
   - 群晖IP地址
   - SMB共享名称
   - 用户名和密码

### 2. 运行安装脚本

#### 2.1 下载并执行安装脚本

```bash
# 进入项目目录
cd /Users/runner/Developer/NotBad

# 设置脚本权限
chmod +x Scripts/install_self_hosted_runner.sh

# 运行安装脚本
sudo ./Scripts/install_self_hosted_runner.sh
```

#### 2.2 按提示输入信息

脚本会要求您输入：
- GitHub仓库地址（格式：username/repository）
- GitHub Personal Access Token
- 群晖SMB主机地址
- SMB共享名称
- SMB用户名

### 3. 验证安装

#### 3.1 检查运行器状态

```bash
# 检查运行器服务状态
sudo -u runner /Users/runner/actions-runner/svc.sh status

# 查看运行器日志
sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log
```

#### 3.2 在GitHub中验证

1. 访问GitHub仓库 → Settings → Actions → Runners
2. 确认看到名为`mac-mini-m4-[hostname]`的运行器
3. 状态应显示为"Online"

## 配置GitHub Actions工作流

### 使用自托管运行器

将工作流中的`runs-on`配置修改为：

```yaml
jobs:
  test:
    runs-on: [self-hosted, macos, m4, xcode-16-4]
```

### 完整的工作流示例

参考 `/.github/workflows/ci-selfhosted.yml` 文件，该文件已经针对自托管运行器进行了优化。

## 存储优化配置

### 缓存目录映射

安装脚本会自动创建以下符号链接：

```bash
# Swift Package Manager缓存
~/.cache/org.swift.swiftpm → /Volumes/runner_data/swiftpm

# Xcode DerivedData
~/Library/Developer/Xcode/DerivedData → /Volumes/runner_data/DerivedData
```

### 构建产物存储

所有构建产物、测试结果和日志都会存储在群晖NAS上：

```
/Volumes/runner_data/
├── artifacts/          # 当前构建产物
├── test-results/       # 测试结果历史
├── performance-results/ # 性能测试结果
├── ui-test-results/    # UI测试结果
├── build-artifacts/    # 构建产物历史
├── swiftpm/           # SPM缓存
├── DerivedData/       # Xcode缓存
└── logs/             # 系统日志
```

## 监控和维护

### 自动监控

系统已配置以下自动监控任务：

- **每15分钟**：检查运行器状态，异常时自动重启
- **每6小时**：检查存储空间，不足时触发清理
- **每小时**：系统健康检查
- **每天凌晨2点**：日常维护清理
- **每周日凌晨3点**：周度维护（包含备份）
- **每月1号凌晨4点**：月度维护（包含优化）

### 手动监控命令

```bash
# 运行完整监控检查
sudo /Users/runner/Developer/NotBad/Scripts/runner_monitor.sh

# 生成监控报告
sudo /Users/runner/Developer/NotBad/Scripts/runner_monitor.sh --report

# 执行系统清理
sudo /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh daily

# 深度维护（包含重建索引）
sudo /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh deep
```

### 日志文件位置

- 监控日志：`/var/log/runner_monitor.log`
- 维护日志：`/var/log/runner_maintenance.log`
- 存储日志：`/var/log/runner_storage.log`
- 健康日志：`/var/log/runner_health.log`

## 常见问题排查

### 运行器离线

```bash
# 检查服务状态
sudo -u runner /Users/runner/actions-runner/svc.sh status

# 重启服务
sudo /Users/runner/actions-runner/svc.sh restart

# 查看日志
sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log
```

### 存储未挂载

```bash
# 手动挂载
sudo /usr/local/bin/automount_runner_data.sh

# 检查挂载状态
mount | grep runner_data
```

### 构建失败

```bash
# 检查Xcode版本
xcodebuild -version

# 检查模拟器
xcrun simctl list devices

# 清理缓存
sudo /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh deep
```

### 存储空间不足

```bash
# 检查存储使用情况
df -h /Volumes/runner_data

# 执行紧急清理
sudo /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh deep
```

## 安全注意事项

### 网络安全

1. **防火墙配置**：确保Mac mini只允许必要的网络访问
2. **VPN访问**：考虑使用VPN来保护远程访问
3. **定期更新**：保持系统和软件的最新版本

### 权限管理

1. **最小权限原则**：运行器用户只拥有必要的权限
2. **Secrets管理**：定期轮换GitHub Secrets
3. **访问控制**：限制对运行器的物理和远程访问

### 数据保护

1. **备份策略**：定期备份重要配置文件
2. **加密存储**：考虑对敏感数据进行加密
3. **日志管理**：定期清理和归档日志文件

## 成本效益分析

### 成本对比

**GitHub托管运行器**：
- macOS运行器：$0.08/分钟
- 假设每月运行100小时：$480/月

**自托管运行器**：
- 设备成本：Mac mini M4 ~$8000（一次性）
- 电费和维护：~$50/月
- 24个月摊销：~$383/月

**节省成本**：约$97/月，年节省约$1164

### 性能优势

1. **构建速度**：本地SSD和网络存储提供更快的I/O
2. **缓存效率**：持久化缓存减少重复下载
3. **并发控制**：可以根据需要调整并发数量
4. **定制化**：可以根据项目需求安装特定工具

## 扩展和维护

### 横向扩展

如需更多并发能力：

1. 添加更多Mac mini运行器
2. 使用标签区分不同用途的运行器：
   ```yaml
   runs-on: [self-hosted, macos, m4, xcode-16-4, unit-tests]
   ```

### 版本升级

1. **Xcode升级**：定期升级Xcode版本
2. **macOS升级**：谨慎升级系统版本
3. **运行器升级**：定期升级GitHub Actions运行器

### 备份和恢复

```bash
# 备份运行器配置
sudo tar -czf runner_backup_$(date +%Y%m%d).tar.gz /Users/runner/actions-runner

# 备份系统配置
sudo tar -czf system_backup_$(date +%Y%m%d).tar.gz /etc/hosts /etc/pf.conf
```

## 技术支持

如遇到问题，请：

1. 查看相关日志文件
2. 运行诊断脚本
3. 检查GitHub Actions运行器文档
4. 联系技术支持团队

## 总结

通过本指南，您已经成功设置了GitHub Actions自托管运行器，实现了：

- ✅ 显著降低CI/CD成本
- ✅ 提升构建性能和稳定性
- ✅ 实现存储空间的合理利用
- ✅ 建立完善的监控和维护机制
- ✅ 确保系统安全和数据保护

这套方案将为您的iOS开发项目提供高效、经济、可靠的CI/CD解决方案。
