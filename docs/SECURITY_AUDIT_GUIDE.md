# 安全审计指南

> 本文档定义 NotBad 项目的安全规范和审计标准  
> 最后更新: 2025年11月27日

---

## 📊 安全概览

| 安全维度 | 当前状态 | 风险等级 |
|---------|---------|---------|
| 数据存储 | SwiftData 本地存储 | 🟢 低 |
| 网络通信 | 暂无网络功能 | 🟢 低 |
| 敏感信息 | 无用户账户系统 | 🟢 低 |
| 第三方 SDK | 无 | 🟢 低 |
| 权限使用 | 相机、相册 | 🟢 低 |

---

## 一、数据安全

### 1.1 数据分类

| 数据类型 | 敏感级别 | 存储位置 | 加密要求 |
|---------|---------|---------|---------|
| 错题图片 | 中 | Documents/ | 可选 |
| 学习元数据 | 低 | SwiftData | 无 |
| 用户偏好 | 低 | UserDefaults | 无 |
| iCloud 数据 | 中 | CloudKit | 系统加密 |

### 1.2 本地数据存储规范

```swift
// ✅ 正确 - 使用 SwiftData 存储业务数据
@Model
final class ReviewItem {
    // SwiftData 自动处理数据持久化
}

// ✅ 正确 - 用户偏好使用 UserDefaults
@AppStorage("theme") private var theme: String = "system"

// ✅ 正确 - 敏感数据使用 Keychain
func storeAPIKey(_ key: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "api_key",
        kSecValueData as String: key.data(using: .utf8)!
    ]
    SecItemAdd(query as CFDictionary, nil)
}

// ❌ 错误 - 敏感数据存入 UserDefaults
UserDefaults.standard.set(password, forKey: "user_password")
```

### 1.3 图片数据安全

```swift
// 图片存储策略
struct ImageSecurityPolicy {
    /// 图片存储在 Documents 目录（iTunes 备份包含）
    static let storageLocation = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    /// 可选：使用 Data Protection
    static func saveSecurely(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.completeFileProtection])
    }
}

// 建议：启用 Data Protection
// 在 Entitlements 中添加：
// com.apple.developer.default-data-protection: NSFileProtectionComplete
```

---

## 二、代码安全

### 2.1 调试代码清理

```swift
// ✅ 正确 - 条件编译包裹调试代码
#if DEBUG
print("🔍 Debug: \(sensitiveData)")
#endif

// ❌ 错误 - 发布版本包含调试日志
print("Password: \(password)")

// ✅ 使用统一日志框架
import os

private let logger = Logger(subsystem: "com.notbad", category: "security")

func logSecureEvent(_ event: String) {
    #if DEBUG
    logger.debug("Security event: \(event)")
    #endif
}
```

### 2.2 硬编码检查

在代码审计时检查以下敏感硬编码：

```swift
// ❌ 禁止硬编码
let apiKey = "sk-xxxxxxxxxxxx"           // API 密钥
let password = "admin123"                 // 密码
let secretToken = "Bearer xxxxx"          // 令牌
let privateKey = "-----BEGIN RSA-----"    // 私钥

// ✅ 使用环境变量或 Keychain
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]
let token = KeychainManager.shared.retrieve("auth_token")
```

**自动检查脚本：**

```bash
#!/bin/bash
# Scripts/security_check.sh

echo "🔍 检查硬编码敏感信息..."

# 检查可能的 API 密钥
grep -rn "sk-\|api_key\|apiKey\|API_KEY" --include="*.swift" NotBad/

# 检查可能的密码
grep -rn "password\|Password\|SECRET\|secret" --include="*.swift" NotBad/

# 检查可能的令牌
grep -rn "Bearer \|token\|Token" --include="*.swift" NotBad/

echo "✅ 检查完成"
```

### 2.3 私有 API 检查

确保没有使用 Apple 私有 API：

```swift
// ❌ 私有 API 示例（会被拒审）
UIApplication.shared.perform(Selector("_setStatusBarHidden:"))
UIDevice.current.perform(Selector("_deviceName"))

// ✅ 使用公开 API
UIApplication.shared.isStatusBarHidden  // 公开属性
UIDevice.current.name                    // 公开属性
```

---

## 三、网络安全

> 当前版本暂无网络功能，以下为未来版本预留规范

### 3.1 App Transport Security (ATS)

```xml
<!-- Info.plist - 默认启用 ATS（推荐） -->
<!-- 无需添加任何 ATS 例外 -->

<!-- ❌ 避免禁用 ATS -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>  <!-- 不推荐 -->
</dict>
```

### 3.2 网络请求安全

```swift
// ✅ 正确 - 强制 HTTPS
let url = URL(string: "https://api.example.com/data")!

// ✅ 正确 - 证书固定（高安全场景）
class PinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // 验证证书指纹
        let serverCertificateData = SecCertificateCopyData(certificate) as Data
        let pinnedCertificateData = loadPinnedCertificate()
        
        if serverCertificateData == pinnedCertificateData {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// ❌ 错误 - 使用 HTTP
let url = URL(string: "http://api.example.com/data")!  // 不安全
```

---

## 四、权限安全

### 4.1 最小权限原则

只申请必需的权限：

| 权限 | 必要性 | 说明 |
|------|--------|------|
| 相机 | ✅ 必需 | 拍摄错题 |
| 相册 | ✅ 必需 | 选择错题图片 |
| 推送 | ✅ 必需 | 复习提醒 |
| 位置 | ❌ 不需要 | 不申请 |
| 通讯录 | ❌ 不需要 | 不申请 |
| 麦克风 | ❌ 不需要 | 不申请 |

### 4.2 权限请求时机

```swift
// ✅ 正确 - 在需要时才请求权限
func capturePhoto() async {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .notDetermined:
        // 首次请求，显示说明
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if granted {
            showCamera()
        } else {
            showPermissionDeniedAlert()
        }
    case .authorized:
        showCamera()
    case .denied, .restricted:
        showPermissionDeniedAlert()
    @unknown default:
        break
    }
}

// ❌ 错误 - 应用启动时立即请求所有权限
func applicationDidFinishLaunching() {
    AVCaptureDevice.requestAccess(for: .video) { _ in }
    PHPhotoLibrary.requestAuthorization { _ in }
    UNUserNotificationCenter.current().requestAuthorization { _, _ in }
}
```

---

## 五、第三方依赖安全

### 5.1 当前依赖状态

| 依赖类型 | 当前状态 | 风险 |
|---------|---------|------|
| CocoaPods | 未使用 | 无 |
| SPM | 未使用 | 无 |
| 手动集成 | 未使用 | 无 |

✅ 当前项目无第三方依赖，安全风险最低。

### 5.2 未来添加依赖时的审计规范

```swift
// Package.swift 依赖审计清单

// 添加任何依赖前检查：
// 1. [ ] 来源可信（官方/知名开发者）
// 2. [ ] 活跃维护（最近6个月有更新）
// 3. [ ] 开源且可审计
// 4. [ ] 无已知安全漏洞
// 5. [ ] 权限需求合理
// 6. [ ] 遵守隐私规范

// 示例：添加依赖时的审计记录
/*
依赖名称: Alamofire
版本: 5.8.0
审计日期: 2025-XX-XX
审计人: [name]
来源: https://github.com/Alamofire/Alamofire
安全评估: ✅ 通过
备注: 广泛使用的网络库，社区活跃
*/
```

---

## 六、数据备份与恢复安全

### 6.1 iTunes/Finder 备份

```xml
<!-- 当前配置：允许备份用户数据 -->
<!-- 如需排除特定文件，使用以下代码 -->
```

```swift
// 排除临时文件不参与备份
func excludeFromBackup(_ url: URL) throws {
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    var mutableURL = url
    try mutableURL.setResourceValues(resourceValues)
}
```

### 6.2 iCloud 备份安全

当前 Entitlements 配置：

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array/>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

✅ 使用 CloudKit，数据在传输和存储时自动加密

---

## 七、发布前安全检查清单

### 7.1 代码审计

- [ ] 无硬编码敏感信息
- [ ] 所有 `print` 包裹在 `#if DEBUG`
- [ ] 无私有 API 调用
- [ ] 无测试账户/密码残留
- [ ] 无调试用的后门代码

### 7.2 配置审计

- [ ] `aps-environment` 设为 `production`
- [ ] 关闭所有调试开关
- [ ] 移除测试用的 URL Scheme
- [ ] 检查 Entitlements 配置正确

### 7.3 二进制审计

```bash
# 检查 Release 包中是否包含调试符号
dwarfdump --uuid NotBad.app/NotBad

# 检查是否链接调试框架
otool -L NotBad.app/NotBad | grep -i debug

# 检查字符串中是否有敏感信息
strings NotBad.app/NotBad | grep -i "password\|secret\|key"
```

---

## 八、安全事件响应

### 8.1 漏洞报告流程

1. 发现漏洞 → 记录详情
2. 评估风险等级
3. 制定修复方案
4. 发布热修复更新
5. 通知受影响用户（如必要）

### 8.2 风险等级定义

| 等级 | 定义 | 响应时间 |
|------|------|---------|
| 🔴 严重 | 数据泄露、远程代码执行 | 24小时内 |
| 🟠 高 | 本地提权、敏感信息暴露 | 72小时内 |
| 🟡 中 | 功能绕过、信息泄露 | 1周内 |
| 🟢 低 | 界面问题、日志过量 | 下一版本 |

---

## 📋 审计检查清单总览

```markdown
### 数据安全 ✓
- [ ] 敏感数据使用 Keychain
- [ ] 图片启用 Data Protection
- [ ] 无明文存储密码/令牌

### 代码安全 ✓
- [ ] 调试代码条件编译
- [ ] 无硬编码密钥
- [ ] 无私有 API

### 网络安全 ✓
- [ ] 强制 HTTPS
- [ ] ATS 未禁用
- [ ] 证书验证正确

### 权限安全 ✓
- [ ] 最小权限原则
- [ ] 权限说明清晰
- [ ] 按需请求权限

### 依赖安全 ✓
- [ ] 依赖来源可信
- [ ] 无已知漏洞
- [ ] 定期更新

### 发布安全 ✓
- [ ] aps-environment = production
- [ ] 移除调试代码
- [ ] 二进制无敏感字符串
```

---

*文档创建：2025年11月27日*  
*适用版本：NotBad v1.0*  
*技术栈：Swift 6.2 / iOS 26 / Xcode 26.1.1*
