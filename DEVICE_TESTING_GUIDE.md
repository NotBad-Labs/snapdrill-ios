# 📱 真机测试配置指南

**设备检测状态**: ✅ 已识别  
**设备名称**: 一鸣的iPhone  
**系统版本**: iOS 26.1  
**设备ID**: 00008150-0001119A3E8A401C

---

## 🎯 在 Xcode 中选择真机的步骤

### 方法一：通过顶部工具栏选择

1. **打开 Xcode**
   ```
   open /Users/yimingliao/NotBad/NotBad.xcodeproj
   ```

2. **查看顶部工具栏**
   - 在 Xcode 窗口顶部，产品名称旁边
   - 应该显示当前选中的设备

3. **点击设备选择器**
   - 点击显示设备名称的下拉菜单
   - 在弹出的列表中找到 **"一鸣的iPhone"**
   - 点击选择

4. **确认选择**
   - 设备名称应该从 "iPhone 17 Simulator" 变为 "一鸣的iPhone"
   - 设备图标应该从模拟器图标变为真机图标

### 方法二：通过快捷键

1. 按 `⌘ + Shift + 2` 打开设备选择器
2. 选择 "一鸣的iPhone"

---

## 🔧 如果看不到设备，尝试以下步骤

### 1️⃣ 检查设备连接

```bash
# 运行这个命令检查设备是否连接
xcrun xctrace list devices | grep "一鸣"
```

应该显示：
```
一鸣的iPhone (26.1) (00008150-0001119A3E8A401C)
```

### 2️⃣ 信任此电脑

在你的 iPhone 上：
1. 连接 USB 线后，iPhone 会弹窗询问"信任此电脑？"
2. 点击 **"信任"**
3. 输入 iPhone 密码确认

### 3️⃣ 重启 Xcode

如果设备还是不显示：
```bash
# 关闭 Xcode
killall Xcode

# 重新打开
open /Users/yimingliao/NotBad/NotBad.xcodeproj
```

### 4️⃣ 重新插拔 USB 线

1. 拔掉 USB 线
2. 等待 5 秒
3. 重新插入
4. 在 iPhone 上点击"信任"

### 5️⃣ 清理开发者数据（终极方案）

```bash
# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 重启设备监控服务
sudo killall -9 usbmuxd
```

---

## 🚀 运行到真机

### 在 Xcode 中运行

1. 确保已选择 "一鸣的iPhone"
2. 按 `⌘ + R` 或点击 ▶️ 运行按钮
3. 首次运行会自动安装开发证书到手机

### 使用命令行运行

```bash
cd /Users/yimingliao/NotBad

# 运行到真机
xcodebuild -scheme NotBad \
  -destination 'platform=iOS,id=00008150-0001119A3E8A401C' \
  build
```

---

## ⚠️ 首次运行可能遇到的问题

### 问题 1: 未受信任的开发者

**症状**: iPhone 上 App 图标灰色，点击提示"未受信任的开发者"

**解决方案**:
1. 在 iPhone 上打开 **设置 > 通用 > VPN与设备管理**
2. 找到你的开发者账号
3. 点击 **"信任"**
4. 确认信任

### 问题 2: 签名错误

**症状**: Xcode 提示签名失败

**解决方案**:
1. 在 Xcode 中选择项目
2. 选择 NotBad target
3. 切换到 "Signing & Capabilities" 标签
4. 确保勾选 **"Automatically manage signing"**
5. 确认 Team 是你的 Apple ID

### 问题 3: 设备版本不匹配

**症状**: 提示设备版本过低或过高

**解决方案**:
- 你的 iPhone 是 iOS 26.1 ✅
- 项目最低版本是 iOS 26.0 ✅
- **版本完全匹配，无需调整！**

---

## 📸 测试相机功能

由于模拟器不支持相机，真机测试尤其重要：

### 测试流程

1. **启动 App**
   - 在真机上点击 NotBad 图标

2. **测试录入功能**
   - 点击"录入" Tab
   - 点击"拍照录入"
   - 应该会弹出相机权限请求
   - 点击"允许"
   - 相机应该正常打开

3. **测试 OCR**
   - 拍摄一张有文字的照片
   - 等待 2-3 秒 OCR 识别
   - 确认标题和笔记自动填充

4. **测试保存**
   - 点击"保存到题库"
   - 确认保存成功提示
   - 切换到"题库" Tab 查看

---

## 🎯 快速命令

### 列出所有可用设备
```bash
xcrun xctrace list devices
```

### 检查设备连接状态
```bash
instruments -s devices | grep "一鸣"
```

### 直接安装到真机
```bash
cd /Users/yimingliao/NotBad
xcodebuild -scheme NotBad \
  -destination 'platform=iOS,name=一鸣的iPhone' \
  -configuration Debug \
  build install
```

---

## ✅ 验证清单

运行前确认：
- [ ] iPhone 通过 USB 连接到 Mac
- [ ] iPhone 已解锁
- [ ] iPhone 上已点击"信任此电脑"
- [ ] Xcode 设备列表中能看到 "一鸣的iPhone"
- [ ] 项目签名配置正确（自动签名已启用）
- [ ] iPhone 系统版本 26.1 ≥ 项目要求 26.0

---

## 🆘 仍然无法识别？

如果以上所有方法都试过了，设备仍然不显示：

1. **更新 Xcode**
   - 确保使用最新版本的 Xcode

2. **更新 iOS**
   - 确保 iPhone 系统是最新版本

3. **重启设备**
   ```bash
   # 重启 iPhone
   # 重启 Mac
   ```

4. **检查 USB 线**
   - 使用原装数据线
   - 尝试其他 USB 端口

5. **检查系统日志**
   ```bash
   # 查看设备相关日志
   log show --predicate 'process == "Xcode"' --last 5m | grep device
   ```

---

**需要帮助？** 告诉我遇到了什么问题，我会进一步协助你！
