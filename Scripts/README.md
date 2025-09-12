# GitHub Actions 自托管运行器脚本集合

本目录包含了在M4 Mac mini上设置GitHub Actions自托管运行器的完整脚本集合，专为配合群晖NAS存储优化而设计。

## 🚀 快速开始

### 一键安装

```bash
# 运行快速安装脚本（推荐）
sudo ./Scripts/quick_setup.sh
```

这个脚本会引导您完成所有必要的配置和安装步骤。

## 📁 脚本说明

### 核心安装脚本

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `quick_setup.sh` | 一键安装脚本 | 交互式完成所有安装步骤 |
| `install_self_hosted_runner.sh` | 主安装脚本 | 安装GitHub Actions运行器 |
| `setup_cron_jobs.sh` | 定时任务配置 | 设置自动监控和维护任务 |

### 存储管理脚本

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `runner_mount_smb.sh` | SMB挂载脚本 | 挂载群晖SMB共享 |
| `runner_setup.sh` | 存储配置 | 设置缓存目录和符号链接 |
| `runner_bootstrap.sh` | 系统初始化 | 基础系统配置 |

### 监控和维护脚本

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `runner_monitor.sh` | 监控脚本 | 检查运行器状态和系统健康 |
| `runner_maintenance.sh` | 维护脚本 | 清理缓存、优化系统 |
| `runner_keepawake.sh` | 防睡眠脚本 | 防止系统进入睡眠 |

### 辅助脚本

| 脚本文件 | 用途 | 说明 |
|---------|------|------|
| `setup_ci.sh` | CI环境设置 | 设置CI/CD环境 |
| `check_coverage.py` | 覆盖率检查 | Python覆盖率检查脚本 |
| `check_performance_regression.py` | 性能回归检查 | 性能测试结果分析 |
| `extract_performance_metrics.py` | 性能指标提取 | 从测试结果中提取性能数据 |

## 🔧 手动安装步骤

如果您想手动执行安装步骤，请按以下顺序运行：

### 1. 系统初始化

```bash
sudo ./Scripts/runner_bootstrap.sh
```

### 2. 挂载群晖存储

```bash
./Scripts/runner_mount_smb.sh <群晖IP> <共享名称> <用户名>
```

### 3. 配置存储目录

```bash
./Scripts/runner_setup.sh
```

### 4. 安装运行器

```bash
sudo ./Scripts/install_self_hosted_runner.sh
```

### 5. 设置定时任务

```bash
sudo ./Scripts/setup_cron_jobs.sh
```

## 📊 监控和维护

### 实时监控

```bash
# 检查运行器状态
sudo ./Scripts/runner_monitor.sh

# 生成监控报告
sudo ./Scripts/runner_monitor.sh --report

# 自动重启（如果异常）
sudo ./Scripts/runner_monitor.sh --auto-restart
```

### 定期维护

```bash
# 日常维护
sudo ./Scripts/runner_maintenance.sh daily

# 周度维护
sudo ./Scripts/runner_maintenance.sh weekly

# 月度维护
sudo ./Scripts/runner_maintenance.sh monthly

# 深度维护
sudo ./Scripts/runner_maintenance.sh deep
```

## 🔍 故障排查

### 常见问题

1. **运行器离线**
   ```bash
   # 检查服务状态
   sudo -u runner /Users/runner/actions-runner/svc.sh status
   
   # 重启服务
   sudo /Users/runner/actions-runner/svc.sh restart
   ```

2. **存储未挂载**
   ```bash
   # 手动挂载
   sudo /usr/local/bin/automount_runner_data.sh
   
   # 检查挂载状态
   mount | grep runner_data
   ```

3. **构建失败**
   ```bash
   # 清理缓存
   sudo ./Scripts/runner_maintenance.sh deep
   
   # 检查Xcode版本
   xcodebuild -version
   ```

### 日志文件

| 日志文件 | 用途 |
|---------|------|
| `/var/log/runner_monitor.log` | 监控日志 |
| `/var/log/runner_maintenance.log` | 维护日志 |
| `/var/log/runner_storage.log` | 存储日志 |
| `/var/log/runner_health.log` | 健康检查日志 |

## 📋 系统要求

- **硬件**：Mac mini M4，16GB内存，256GB SSD
- **系统**：macOS 14.0或更高版本
- **网络**：稳定的互联网连接
- **存储**：群晖NAS，通过万兆光纤连接
- **软件**：Xcode 16.4，Command Line Tools

## 🔐 安全注意事项

1. **网络安全**：确保防火墙配置正确
2. **权限管理**：使用最小权限原则
3. **Secrets管理**：定期轮换GitHub Secrets
4. **访问控制**：限制对运行器的访问

## 📚 相关文档

- [完整设置指南](../docs/ci-cd/self-hosted-runner-setup-guide.md)
- [GitHub Actions官方文档](https://docs.github.com/en/actions/hosting-your-own-runners)
- [自托管运行器最佳实践](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners)

## 🆘 技术支持

如遇到问题，请：

1. 查看相关日志文件
2. 运行诊断脚本
3. 参考完整文档
4. 联系技术支持团队

## 📝 更新日志

- **v1.0** (2024-01-XX)
  - 初始版本发布
  - 支持M4 Mac mini + 群晖存储
  - 完整的监控和维护功能
  - 自动化安装和配置

---

**注意**：运行这些脚本需要管理员权限。请确保您了解脚本的功能和潜在风险。
