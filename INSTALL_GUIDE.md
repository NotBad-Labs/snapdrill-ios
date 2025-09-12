# GitHub Actions 自托管运行器安装指南

## 🚀 快速安装

### 步骤1：准备GitHub Token

1. 访问 [GitHub Personal Access Tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 选择以下权限：
   - `repo` (完整仓库访问权限)
   - `admin:org` (如果是组织仓库)
4. 复制生成的Token

### 步骤2：设置环境变量并安装

```bash
# 设置GitHub配置（请替换为您的实际信息）
export GITHUB_REPO="your-username/your-repository"
export GITHUB_TOKEN="ghp_your_token_here"

# 可选：配置群晖存储
export SMB_HOST="192.168.1.100"  # 群晖IP地址
export SMB_USER="your-username"   # SMB用户名
export SHARE_NAME="runner_data"   # 共享名称

# 运行安装脚本
sudo ./Scripts/install_runner.sh
```

### 步骤3：验证安装

1. 访问您的GitHub仓库
2. 进入 Settings → Actions → Runners
3. 确认看到名为 `mac-mini-m4` 的运行器
4. 状态应显示为 "Online"

## 📝 配置示例

### 基本配置（不使用群晖存储）

```bash
export GITHUB_REPO="yimingliao/NotBad"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
sudo ./Scripts/install_runner.sh
```

### 完整配置（使用群晖存储）

```bash
export GITHUB_REPO="yimingliao/NotBad"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export SMB_HOST="192.168.1.100"
export SMB_USER="ci-user"
export SHARE_NAME="runner_data"
sudo ./Scripts/install_runner.sh
```

## 🔧 安装后配置

### 配置GitHub Actions工作流

在您的 `.github/workflows/ci.yml` 中，将 `runs-on` 修改为：

```yaml
jobs:
  test:
    runs-on: [self-hosted, macos, m4, xcode-16-4]
```

### 配置GitHub Secrets（如需要）

在GitHub仓库设置中添加以下Secrets：

- `BUILD_CERTIFICATE_BASE64` - 构建证书
- `P12_PASSWORD` - 证书密码
- `KEYCHAIN_PASSWORD` - 钥匙串密码
- `PROVISIONING_PROFILE_BASE64` - 描述文件
- `APPLEID_USERNAME` - Apple ID用户名
- `APPLEID_PASSWORD` - Apple ID密码

## 🛠️ 常用命令

### 运行器管理

```bash
# 查看运行器状态
sudo -u runner /Users/runner/actions-runner/svc.sh status

# 重启运行器服务
sudo /Users/runner/actions-runner/svc.sh restart

# 停止运行器服务
sudo /Users/runner/actions-runner/svc.sh stop

# 查看运行器日志
sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log
```

### 监控和维护

```bash
# 运行环境测试
./Scripts/quick_test.sh

# 运行详细监控
sudo ./Scripts/runner_monitor.sh

# 执行系统维护
sudo ./Scripts/runner_maintenance.sh daily
```

## 🔍 故障排查

### 运行器离线

```bash
# 检查服务状态
sudo -u runner /Users/runner/actions-runner/svc.sh status

# 重启服务
sudo /Users/runner/actions-runner/svc.sh restart

# 查看日志
sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log
```

### 存储问题

```bash
# 检查挂载状态
mount | grep runner_data

# 手动挂载（如果配置了群晖）
sudo mount_smbfs //username@192.168.1.100/runner_data /Volumes/runner_data
```

### 构建失败

```bash
# 检查Xcode版本
xcodebuild -version

# 检查模拟器
xcrun simctl list devices

# 清理缓存
sudo ./Scripts/runner_maintenance.sh deep
```

## 📊 性能优化

### 存储优化

- 使用群晖存储扩展缓存空间
- 定期清理旧的构建产物
- 监控存储使用情况

### 构建优化

- 利用持久化缓存减少重复下载
- 并行执行测试任务
- 优化构建脚本

## 🔐 安全注意事项

1. **Token安全**：定期轮换GitHub Token
2. **权限管理**：使用最小权限原则
3. **网络安全**：配置防火墙规则
4. **数据保护**：定期备份重要配置

## 📞 技术支持

如遇到问题，请：

1. 查看相关日志文件
2. 运行诊断脚本
3. 参考完整文档
4. 联系技术支持团队

---

**开始您的自托管CI/CD之旅！** 🚀
