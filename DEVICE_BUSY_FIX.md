# 🚨 设备连接问题解决方案

**问题**: Device is busy (Waiting to reconnect to 一鸣的iPhone)

---

## 立即解决步骤

### ⚡ 快速修复（按顺序尝试）

#### 1. 在 iPhone 上解锁屏幕
```
✅ 确保 iPhone 屏幕是亮着的
✅ 解锁到主屏幕
```

#### 2. 信任此电脑
在 iPhone 上应该看到弹窗：
```
"信任此电脑？"
├─ 点击：信任
└─ 输入密码
```

#### 3. 重启 iOS 设备监控服务
```bash
# 运行这个命令重启服务
sudo killall -9 usbmuxd

# 等待 3 秒
sleep 3

# 检查设备状态
xcrun xctrace list devices | grep "一鸣"
```

#### 4. 在 Xcode 中刷新设备
1. 打开 Xcode
2. 菜单：Window > Devices and Simulators (⌘ + Shift + 2)
3. 找到 "一鸣的iPhone"
4. 如果显示黄色感叹号，点击设备
5. 点击 "Prepare for Development"

---

## 🔧 完整修复流程

### 步骤 1: 重新建立连接

```bash
# 1. 关闭所有可能占用设备的进程
killall Xcode
killall Instruments
killall simctl

# 2. 重启 USB 守护进程
sudo killall -9 usbmuxd

# 3. 等待服务重启
sleep 5

# 4. 检查设备
xcrun xctrace list devices
```

### 步骤 2: 物理重连

1. **拔掉 USB 线**
2. **等待 10 秒**
3. **重新插入 USB 线**
4. **在 iPhone 上点击"信任"**

### 步骤 3: 准备开发环境

```bash
# 打开设备管理窗口
open -a Xcode
# 然后按 ⌘ + Shift + 2
```

在设备窗口中：
1. 选择你的 iPhone
2. 如果看到 "Preparing..."，等待完成
3. 如果看到 "Prepare for Development" 按钮，点击它

---

## 🎯 验证设备已就绪

运行这个命令检查：

```bash
# 方法 1: 使用 instruments
instruments -s devices | grep "一鸣"

# 方法 2: 使用 xctrace
xcrun xctrace list devices | grep "一鸣"

# 方法 3: 使用 idevice
xcrun devicectl list devices
```

**期望输出**:
```
一鸣的iPhone (26.1) (00008150-0001119A3E8A401C)
```

**不应该有**:
- ❌ "busy"
- ❌ "unavailable"
- ❌ "Waiting to reconnect"

---

## 🚀 准备就绪后，运行到真机

### 方法 1: 在 Xcode 中运行（推荐）

1. 确保 Xcode 已打开
2. 顶部工具栏选择 "一鸣的iPhone"
3. 按 `⌘ + R` 运行

### 方法 2: 使用命令行

```bash
cd /Users/yimingliao/NotBad

# 使用设备 ID（更可靠）
xcodebuild -scheme NotBad \
  -destination 'platform=iOS,id=00008150-0001119A3E8A401C' \
  build

# 或使用设备名称
xcodebuild -scheme NotBad \
  -destination 'platform=iOS,name=一鸣的iPhone' \
  build
```

---

## 🔍 常见错误排查

### Error: "Device is busy"

**原因**: 
- iPhone 锁屏
- 正在同步数据
- 其他进程占用设备

**解决**:
```bash
# 1. 解锁 iPhone
# 2. 关闭其他可能占用的进程
killall Xcode iTunes "iOS Console"

# 3. 重启 USB 服务
sudo killall -9 usbmuxd
```

### Error: "Waiting to reconnect"

**原因**:
- USB 连接不稳定
- 未信任此电脑
- 设备处于恢复模式

**解决**:
1. 重新插拔 USB 线
2. 确保在 iPhone 上点击"信任"
3. 重启 iPhone（如果必要）

### Error: "Device locked"

**原因**: iPhone 处于锁屏状态

**解决**:
- 解锁 iPhone
- 输入密码
- 确保屏幕保持亮着

---

## 💡 专业建议

### 保持连接稳定

1. **使用原装线**
   - USB-C 转 Lightning（或 USB-C）
   - 避免使用转接头

2. **选择好的 USB 口**
   - 优先使用 MacBook 左侧（如果有）
   - 避免使用 USB Hub

3. **保持解锁**
   - 开发时保持 iPhone 解锁
   - 或延长自动锁屏时间

4. **关闭低电量模式**
   - 低电量模式可能影响连接
   - 充电时测试更稳定

---

## 🆘 终极解决方案

如果以上都不行：

### 1. 重启所有设备
```bash
# 1. 重启 iPhone
# 2. 重启 Mac
```

### 2. 重置位置与隐私
在 iPhone 上：
1. 设置 > 通用 > 传输或还原 iPhone
2. 还原 > 还原位置与隐私
3. 重新连接并信任

### 3. 检查网络设置
```bash
# 确保没有防火墙阻止
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

### 4. 清理 Xcode 数据
```bash
# 清理派生数据
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 清理设备支持文件
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*

# 重启 Xcode
killall Xcode && open -a Xcode
```

---

## ✅ 成功标志

当一切就绪时，你应该看到：

### 在 Xcode 中
- 设备选择器显示 "一鸣的iPhone"
- 没有黄色警告图标
- 状态栏显示 "Ready"

### 在命令行中
```bash
$ xcrun xctrace list devices | grep "一鸣"
一鸣的iPhone (26.1) (00008150-0001119A3E8A401C)
# ✅ 没有 "busy" 或 "unavailable"
```

### 在 iPhone 上
- 设置 > 通用 > VPN与设备管理
- 能看到你的开发者证书
- 已信任

---

**准备好了吗？** 告诉我设备状态，我会继续帮你！
