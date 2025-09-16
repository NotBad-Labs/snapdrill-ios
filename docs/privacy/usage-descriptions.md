# Privacy 权限用途说明 v1.0

本文档定义 NotBad App 请求的系统权限用途说明文案，确保用户理解权限使用目的并符合 App Store 审核要求。

## 1. 相机权限 (NSCameraUsageDescription)

### 用途说明
NotBad 需要使用相机来拍摄错题，以便进行文字识别和题目录入。拍摄的照片仅在您的设备上处理，不会上传到第三方服务器。

### 技术文案 (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>NotBad 需要访问相机来拍摄错题，以便进行文字识别和题目录入。所有照片处理均在您的设备上完成，保护您的隐私安全。</string>
```

### 英文版本
```xml
<key>NSCameraUsageDescription</key>
<string>NotBad needs camera access to capture images of your study materials for text recognition and note creation. All image processing is done locally on your device to protect your privacy.</string>
```

## 2. 相册权限 (NSPhotoLibraryUsageDescription)

### 用途说明
NotBad 需要访问您的相册来选择已有的错题照片进行识别和录入。您可以选择特定照片，我们不会访问您相册中的其他内容。

### 技术文案 (Info.plist)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>NotBad 需要访问相册来选择错题照片进行识别录入。您可以选择特定照片，我们只处理您选择的内容，保护您的隐私。</string>
```

### 英文版本
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>NotBad needs photo library access to let you select existing images for text recognition. You can choose specific photos, and we only process the content you select.</string>
```

## 3. 限制式相册权限 (NSPhotoLibraryAddUsageDescription)

### 用途说明
NotBad 可以将处理后的学习笔记保存到您的相册，方便您分享或备份。此功能完全可选，只在您明确要求时使用。

### 技术文案 (Info.plist)
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>NotBad 可以将您的学习笔记保存到相册，方便分享和备份。此功能仅在您主动选择时使用。</string>
```

### 英文版本
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>NotBad can save your study notes to the photo library for easy sharing and backup. This feature is only used when you actively choose to save.</string>
```

## 4. 推送通知权限

### 用途说明
NotBad 可以发送学习提醒通知，帮助您保持良好的复习习惯。所有通知都在您的设备上生成，不涉及个人数据传输。

### 申请时机
- 完成首次创建复习项后
- 用户设置学习目标时
- 可在设置中随时开启/关闭

## 5. iCloud 同步权限

### 用途说明
NotBad 使用 iCloud 的私有数据库来同步您的学习数据到多个设备。数据通过 Apple 的端到端加密保护，我们无法访问您的具体内容。

### 数据类型
- 复习项元数据（不含原始图片）
- 学习进度和统计
- 应用设置偏好

## 6. 权限申请最佳实践

### 6.1 申请时机
- **相机权限**：用户首次点击"拍照"按钮时
- **相册权限**：用户首次点击"从相册选择"时
- **保存权限**：用户首次尝试保存到相册时
- **推送权限**：完成首个复习项后适时引导

### 6.2 用户教育
- 在权限弹窗前显示解释界面
- 明确说明数据不会上传到第三方
- 提供"稍后设置"选项，不强制要求
- 在设置页面提供重新申请入口

### 6.3 降级方案
- 拒绝相机权限：提供从相册导入的替代方案
- 拒绝相册权限：提供拍照录入的替代方案
- 拒绝推送权限：应用内提醒替代系统通知
- 拒绝 iCloud：本地存储，提供手动导出功能

## 7. 数据处理承诺

### 本地优先
- OCR 文字识别在设备上完成
- 学习数据默认本地存储
- 图片处理不依赖云服务

### 最小化原则
- 只申请必需的权限
- 只处理用户主动选择的内容
- 不收集与功能无关的数据

### 透明度
- 在隐私政策中详细说明数据使用
- 提供数据导出和删除功能
- 允许用户查看和管理权限设置

---

**版本历史**
| 版本 | 日期 | 变更说明 | 作者 |
| :-- | :-- | :-- | :-- |
| v1.0 | 2025-09-16 | 初版权限用途说明，对齐 PRD v4.1 隐私策略 | chramboliao |

**注意**：实际 App Store 提交前需要根据最新审核指南和实际功能实现对文案进行最终调整。