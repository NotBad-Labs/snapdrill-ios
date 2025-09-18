# 隐私与合规清单（K12 场景）

**文档版本**: v6.0  
**最后更新**: 2025-09-18  
**关联文档**: [PRD v6.0](./NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0%20(Swift6.2%20+%20iOS26).md)

## 概述

本文档定义了 NotBad 错题本 App 在 K12 教育场景下的隐私保护和合规要求，确保完全符合相关法律法规，保护未成年人的数字权益。

## 法律法规合规

### 1. 国际法规

#### 1.1 COPPA（儿童在线隐私保护法）- 美国
- **适用对象**: 13岁以下儿童
- **要求**:
  - 获得家长明确同意
  - 限制信息收集范围
  - 允许家长查看和删除信息
  - 不得将儿童信息用于商业目的

#### 1.2 GDPR（通用数据保护条例）- 欧盟
- **适用对象**: 所有欧盟用户，特别是16岁以下
- **要求**:
  - 数据最小化原则
  - 明确的同意机制
  - 数据可携带权
  - 被遗忘权

### 2. 国内法规

#### 2.1 《个人信息保护法》
- **适用对象**: 所有中国境内用户
- **要求**:
  - 个人信息处理的合法性基础
  - 告知同意规则
  - 个人信息跨境传输规范
  - 未成年人信息特殊保护

#### 2.2 《网络安全法》
- **数据安全要求**
- **网络运营者义务**
- **数据本地化要求**

#### 2.3 《数据安全法》
- **数据分类分级保护**
- **重要数据处理规范**

## 隐私保护原则

### 1. 数据最小化
#### 收集原则
- **仅收集必要数据**: 只收集实现功能必需的最少信息
- **目的限制**: 数据使用严格限定在声明的目的范围内
- **保留期限**: 设定明确的数据保留期限

#### 实施措施
```swift
struct DataCollectionPolicy {
    // 允许收集的数据类型
    enum AllowedDataType {
        case reviewContent      // 错题内容
        case studyProgress     // 学习进度
        case userPreferences   // 用户偏好
        case performanceMetrics // 性能指标（匿名）
        
        // 禁止收集的数据类型
        // - 真实姓名
        // - 学校信息
        // - 家庭住址
        // - 联系方式
        // - 社交关系
    }
    
    static func isDataCollectionAllowed(for dataType: AllowedDataType, userAge: Int) -> Bool {
        if userAge < 13 {
            // COPPA 严格限制
            return [.reviewContent, .studyProgress].contains(dataType)
        } else if userAge < 18 {
            // 一般未成年人保护
            return dataType != .performanceMetrics
        } else {
            return true
        }
    }
}
```

### 2. 透明度原则
#### 隐私政策要求
- **简明易懂**: 使用通俗语言，避免法律术语
- **分层展示**: 核心信息突出，详细信息分层
- **定期更新**: 功能变更时及时更新隐私政策

#### 数据处理透明
```swift
class PrivacyDashboard {
    // 用户可查看的数据处理信息
    func getDataProcessingInfo() -> DataProcessingInfo {
        return DataProcessingInfo(
            dataCollected: getCollectedDataTypes(),
            processingPurpose: getProcessingPurposes(),
            retentionPeriod: getRetentionPeriods(),
            sharingPartners: getSharingPartners(),
            userRights: getUserRights()
        )
    }
}
```

### 3. 用户控制
#### 同意管理
- **细粒度同意**: 不同功能分别获得同意
- **同意撤回**: 用户可随时撤回同意
- **无同意降级**: 拒绝非必要数据收集时功能正常运行

```swift
class ConsentManager {
    enum ConsentType {
        case essential      // 必要功能，不需要同意
        case analytics      // 分析功能，需要同意
        case personalization // 个性化功能，需要同意
        case marketing      // 市场推广，需要同意（本应用不涉及）
    }
    
    func requestConsent(for type: ConsentType, userAge: Int) async -> Bool {
        if userAge < 13 {
            // 需要家长同意
            return await requestParentalConsent(for: type)
        } else {
            return await requestUserConsent(for: type)
        }
    }
}
```

## 技术实现规范

### 1. 数据加密

#### 1.1 本地存储加密
```swift
class SecureDataStore {
    // 启用最高级别文件保护
    static let fileProtectionLevel = FileProtectionType.complete
    
    // 敏感数据加密存储
    func encryptAndStore<T: Codable>(_ data: T, key: String) throws {
        let encryptedData = try AES256.encrypt(data, using: getEncryptionKey())
        let url = getSecureStorageURL(for: key)
        try encryptedData.write(to: url, options: [.completeFileProtection])
    }
    
    // 密钥管理
    private func getEncryptionKey() -> Data {
        // 使用 Keychain 存储密钥
        return KeychainManager.shared.getOrCreateKey(for: "app_encryption_key")
    }
}
```

#### 1.2 传输加密
```swift
class NetworkManager {
    // 强制使用 TLS 1.3
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv13
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        return URLSession(configuration: config)
    }()
    
    // 证书固定
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge, 
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 实现证书固定逻辑
    }
}
```

### 2. 匿名化处理

#### 2.1 数据脱敏
```swift
class DataAnonymizer {
    // 用户内容哈希化
    static func anonymizeUserContent(_ content: String) -> String {
        return SHA256.hash(data: content.data(using: .utf8)!).compactMap { 
            String(format: "%02x", $0) 
        }.joined()
    }
    
    // 设备标识符匿名化
    static func generateAnonymousDeviceID() -> String {
        // 使用应用级别 UUID，不使用设备硬件标识
        if let existingID = UserDefaults.standard.string(forKey: "anonymous_device_id") {
            return existingID
        }
        
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "anonymous_device_id")
        return newID
    }
}
```

#### 2.2 差分隐私
```swift
class DifferentialPrivacy {
    // 为统计数据添加噪声
    static func addNoise(to value: Double, epsilon: Double = 1.0) -> Double {
        let scale = 1.0 / epsilon
        let noise = Laplace.random(scale: scale)
        return value + noise
    }
    
    // 匿名聚合统计
    static func anonymousAggregation(data: [Double]) -> StatisticalSummary {
        let count = addNoise(to: Double(data.count))
        let mean = addNoise(to: data.reduce(0, +) / Double(data.count))
        return StatisticalSummary(count: count, mean: mean)
    }
}
```

### 3. 访问控制

#### 3.1 生物识别认证
```swift
class BiometricAuth {
    func authenticateUser() async throws -> Bool {
        let context = LAContext()
        
        var error: NSError?
        guard context.canEvaluatePolicy(.biometryAny, error: &error) else {
            throw AuthError.biometryNotAvailable
        }
        
        let reason = "验证身份以访问学习数据"
        return try await context.evaluatePolicy(.biometryAny, localizedReason: reason)
    }
}
```

#### 3.2 家长控制
```swift
class ParentalControls {
    // 家长授权机制
    func requestParentalAuthorization(for feature: AppFeature) async throws -> Bool {
        // 1. 验证家长身份
        guard try await verifyParentIdentity() else {
            throw ParentalError.identityVerificationFailed
        }
        
        // 2. 展示功能说明
        let consent = try await presentConsentDialog(for: feature)
        
        // 3. 记录授权决定
        try await recordAuthorizationDecision(feature: feature, consent: consent)
        
        return consent
    }
    
    // 家长仪表板
    func getParentalDashboard() -> ParentalDashboard {
        return ParentalDashboard(
            childActivity: getChildActivitySummary(),
            privacySettings: getCurrentPrivacySettings(),
            dataSharing: getDataSharingStatus()
        )
    }
}
```

## 未成年人保护措施

### 1. 年龄验证
```swift
class AgeVerification {
    enum AgeGroup {
        case under13        // 需要家长同意
        case teen13to17     // 简化同意
        case adult18plus    // 完整功能
    }
    
    func verifyAge() async -> AgeGroup? {
        // 不直接询问年龄，通过间接方式判断
        let context = await gatherAgeContext()
        
        // 使用机器学习模型估算年龄组
        let ageGroup = await AgeEstimationModel.predict(context: context)
        
        // 如果不确定，采用最严格的保护措施
        return ageGroup ?? .under13
    }
}
```

### 2. 内容安全
```swift
class ContentSafety {
    // 内容审核
    func moderateContent(_ content: ReviewItemContent) async -> ModerationResult {
        // 1. 自动检测不适宜内容
        let autoResult = await AutoContentModerator.check(content)
        
        // 2. 如果包含敏感内容，进行人工审核
        if autoResult.containsSensitiveContent {
            return await HumanModerator.review(content)
        }
        
        return autoResult
    }
    
    // 学习环境安全
    func ensureSafeLearningEnvironment() {
        // 禁用不适宜的分享功能
        // 限制外部链接访问
        // 内容过滤和监控
    }
}
```

### 3. 时间管理
```swift
class ScreenTimeManager {
    // 学习时间监控
    func trackStudyTime(session: StudySession) {
        let duration = session.duration
        let currentDate = Date()
        
        // 记录今日学习时间
        let todayStudyTime = getTodayStudyTime() + duration
        saveTodayStudyTime(todayStudyTime)
        
        // 健康提醒
        if todayStudyTime > recommendedDailyLimit {
            showHealthReminder()
        }
    }
    
    // 护眼提醒
    func scheduleEyeCareReminders() {
        // 每20分钟提醒休息
        Timer.scheduledTimer(withTimeInterval: 20 * 60, repeats: true) { _ in
            showEyeCareReminder()
        }
    }
}
```

## 数据权利保障

### 1. 查看权
```swift
class DataPortability {
    // 数据导出
    func exportUserData() async throws -> UserDataExport {
        let userData = UserDataExport(
            reviewItems: await getReviewItems(),
            studyProgress: await getStudyProgress(),
            preferences: getUserPreferences(),
            metadata: getDataMetadata()
        )
        
        // 生成人类可读的报告
        let report = generateHumanReadableReport(userData)
        
        return userData
    }
}
```

### 2. 删除权
```swift
class DataDeletion {
    // 完全删除用户数据
    func deleteAllUserData() async throws {
        // 1. 删除本地数据
        try await LocalDataStore.deleteAll()
        
        // 2. 删除云端数据
        try await CloudDataStore.deleteAll()
        
        // 3. 删除分析数据
        try await AnalyticsDataStore.anonymizeAndDelete()
        
        // 4. 撤销所有授权
        await ConsentManager.revokeAllConsents()
        
        // 5. 清除缓存
        clearAllCaches()
        
        // 6. 记录删除操作（用于合规审计）
        await AuditLogger.logDataDeletion()
    }
}
```

### 3. 更正权
```swift
class DataCorrection {
    // 数据更正
    func correctUserData(_ corrections: [DataCorrection]) async throws {
        for correction in corrections {
            try await applyCorrection(correction)
            await AuditLogger.logDataCorrection(correction)
        }
    }
}
```

## 第三方服务合规

### 1. 服务提供商选择标准
- **隐私政策**: 符合 GDPR/COPPA 要求
- **数据处理协议**: 签署数据处理协议 (DPA)
- **安全认证**: SOC 2, ISO 27001 等认证
- **数据本地化**: 支持数据本地化要求

### 2. 当前集成服务
```swift
enum ThirdPartyService {
    case cloudKit           // Apple CloudKit - 符合隐私标准
    case coreML            // Apple Core ML - 本地处理
    case vision            // Apple Vision - 本地处理
    
    // 明确禁止的服务类型
    // - 广告网络
    // - 社交媒体 SDK
    // - 用户行为追踪 SDK
    // - 第三方分析服务（除非符合严格的隐私标准）
}
```

### 3. 数据传输限制
```swift
class DataTransferPolicy {
    // 禁止的数据传输
    static let prohibitedTransfers: [DataType] = [
        .personalInfo,      // 个人信息
        .studyContent,     // 学习内容
        .behaviorData      // 行为数据
    ]
    
    // 允许的匿名统计
    static let allowedAnonymousData: [DataType] = [
        .performanceMetrics,    // 性能指标
        .crashReports,         // 崩溃报告（去标识化）
        .usageStatistics       // 使用统计（聚合）
    ]
}
```

## 合规审计与监控

### 1. 定期审计
```swift
class ComplianceAudit {
    // 季度合规审计
    func quarterlyAudit() async -> ComplianceReport {
        return ComplianceReport(
            dataMinimizationCompliance: auditDataMinimization(),
            consentManagementCompliance: auditConsentManagement(),
            securityImplementation: auditSecurityMeasures(),
            userRightsImplementation: auditUserRights(),
            thirdPartyCompliance: auditThirdPartyServices()
        )
    }
}
```

### 2. 实时监控
```swift
class PrivacyMonitoring {
    // 隐私违规检测
    func detectPrivacyViolations() {
        // 监控异常数据访问
        // 检测未授权数据传输
        // 验证加密状态
        // 审计用户权限行使
    }
}
```

## 用户教育与支持

### 1. 隐私教育
- **交互式隐私指南**: 帮助用户理解隐私设置
- **定期隐私提醒**: 提醒用户检查隐私设置
- **家长指导**: 帮助家长理解和配置儿童保护设置

### 2. 支持渠道
- **隐私相关咨询**: 专门的隐私问题咨询渠道
- **数据权利行使**: 便捷的数据权利行使流程
- **投诉处理**: 快速响应隐私投诉

## 应急响应

### 1. 数据泄露响应
```swift
class DataBreachResponse {
    func handleDataBreach(incident: SecurityIncident) async {
        // 1. 立即遏制
        await containBreach(incident)
        
        // 2. 评估影响
        let impact = await assessBreachImpact(incident)
        
        // 3. 通知相关方
        if impact.requiresNotification {
            await notifyAffectedUsers(impact.affectedUsers)
            await notifyRegulators(impact)
        }
        
        // 4. 修复和改进
        await implementFixes(incident.vulnerabilities)
    }
}
```

### 2. 合规问题响应
- **24小时响应**: 对合规问题的快速响应
- **问题升级**: 严重合规问题的升级机制
- **外部专家**: 必要时聘请外部隐私专家

---

**重要提醒**:
1. 隐私保护是持续过程，需要定期评估和改进
2. 法律法规可能变化，需要及时跟进和调整
3. 技术实现必须与法律要求保持一致
4. 用户体验和隐私保护需要平衡，但隐私保护优先
5. 所有团队成员都需要接受隐私保护培训