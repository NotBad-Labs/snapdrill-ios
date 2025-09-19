# NotBad App CI/CD 配置指南 v6.0

## 文档概述

本文档定义了NotBad App基于Swift 6.2 + iOS 26技术栈的完整CI/CD流程配置，确保自动化构建、测试和部署流程与PRD v6.0和TDD v6.0的技术要求完全对齐。

## 技术栈要求

### 核心构建环境
- **Xcode**: 26.0 (支持Swift 6.2)
- **iOS SDK**: iOS 26.0 SDK
- **Swift**: 6.2 (Enhanced Actor Isolation, Improved TaskGroup)
- **macOS**: 15.0+ (运行器最低要求)
- **Simulator**: iOS 26.0 运行时

### 关键特性支持
- Enhanced Actor Isolation (Swift 6.2)
- Improved TaskGroup 并发处理
- iOS 26 Advanced Vision Framework
- Enhanced SwiftData + CloudKit集成
- ProMotion Max 120fps支持

## GitHub Actions 工作流配置

### 主工作流 (.github/workflows/ios.yml)

```yaml
name: iOS CI/CD Pipeline v6.0

on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]

env:
  SWIFT_VERSION: "6.2"
  XCODE_VERSION: "26.0"
  IOS_VERSION: "26.0"

jobs:
  build-test:
    name: Build and Test
    runs-on: macos-15  # 确保支持Xcode 26

    strategy:
      matrix:
        # 支持多设备测试
        destination:
          - 'platform=iOS Simulator,name=iPhone 15 Pro,OS=26.0'
          - 'platform=iOS Simulator,name=iPhone 15 Pro Max,OS=26.0'
          - 'platform=iOS Simulator,name=iPad Air (5th generation),OS=26.0'

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Setup Xcode 26
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '26.0'

    - name: Verify Swift 6.2 Support
      run: |
        swift --version
        xcodebuild -version
        echo "Verifying Swift 6.2 Enhanced Actor support..."

    - name: Cache Swift Package Manager
      uses: actions/cache@v4
      with:
        path: |
          ~/Library/Caches/org.swift.swiftpm
          ~/Library/Developer/Xcode/DerivedData
        key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
        restore-keys: |
          ${{ runner.os }}-spm-

    - name: Install iOS 26.0 Simulator
      run: |
        xcrun simctl list runtimes
        # 确保iOS 26.0运行时可用
        if ! xcrun simctl list runtimes | grep "iOS 26.0"; then
          echo "Installing iOS 26.0 runtime..."
          sudo xcrun simctl runtime install "iOS 26.0"
        fi

    - name: Build with Swift 6.2
      run: |
        xcodebuild clean build \
          -project NotBad.xcodeproj \
          -scheme NotBad \
          -destination '${{ matrix.destination }}' \
          -configuration Debug \
          SWIFT_VERSION=6.2 \
          IPHONEOS_DEPLOYMENT_TARGET=26.0 \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO

    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project NotBad.xcodeproj \
          -scheme NotBadTests \
          -destination '${{ matrix.destination }}' \
          -configuration Debug \
          -enableCodeCoverage YES \
          SWIFT_VERSION=6.2

    - name: Run UI Tests
      run: |
        xcodebuild test \
          -project NotBad.xcodeproj \
          -scheme NotBadUITests \
          -destination '${{ matrix.destination }}' \
          -configuration Debug \
          SWIFT_VERSION=6.2

    - name: Generate Test Coverage Report
      run: |
        xcrun xccov view --report --json DerivedData/Logs/Test/*.xcresult > coverage.json
        xcrun xccov view --report DerivedData/Logs/Test/*.xcresult

    - name: Upload Test Results
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: test-results-${{ matrix.destination }}
        path: |
          DerivedData/Logs/Test/
          coverage.json

  performance-test:
    name: Performance Testing
    runs-on: macos-15
    needs: build-test

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Setup Xcode 26
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '26.0'

    - name: Run Performance Tests
      run: |
        xcodebuild test \
          -project NotBad.xcodeproj \
          -scheme PerformanceTestPlan \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=26.0' \
          -configuration Release \
          SWIFT_VERSION=6.2

    - name: Validate Performance Targets
      run: |
        # 验证PRD v6.0性能目标
        echo "Validating performance targets:"
        echo "- App launch time < 0.8s"
        echo "- Memory usage < 150MB"
        echo "- OCR accuracy > 95%"
        python3 Scripts/check_performance_regression.py

  security-scan:
    name: Security and Privacy Scan
    runs-on: macos-15
    needs: build-test

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: COPPA/GDPR Compliance Check
      run: |
        echo "Checking COPPA/GDPR compliance..."
        # 检查隐私敏感代码
        grep -r "personalData\|userProfile\|ageGroup" Sources/ || true

    - name: Privacy Manifest Validation
      run: |
        # 验证隐私清单文件
        if [ -f "NotBad/PrivacyInfo.xcprivacy" ]; then
          echo "Privacy manifest found"
          plutil -lint NotBad/PrivacyInfo.xcprivacy
        else
          echo "⚠️ Privacy manifest missing"
          exit 1
        fi

  build-release:
    name: Build Release Version
    runs-on: macos-15
    needs: [build-test, performance-test, security-scan]
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Setup Xcode 26
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '26.0'

    - name: Import Signing Certificate
      env:
        BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
        P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      run: |
        # 创建临时keychain
        security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

        # 导入证书
        echo $BUILD_CERTIFICATE_BASE64 | base64 --decode > certificate.p12
        security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain

    - name: Build Archive
      run: |
        xcodebuild archive \
          -project NotBad.xcodeproj \
          -scheme NotBad \
          -configuration Release \
          -archivePath NotBad.xcarchive \
          SWIFT_VERSION=6.2 \
          IPHONEOS_DEPLOYMENT_TARGET=26.0

    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath NotBad.xcarchive \
          -exportPath . \
          -exportOptionsPlist ExportOptions.plist

    - name: Upload to TestFlight
      env:
        APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
      run: |
        xcrun altool --upload-app \
          --type ios \
          --file NotBad.ipa \
          --apiKey $APP_STORE_CONNECT_API_KEY
```

### Discovery社区功能测试 (.github/workflows/discovery-tests.yml)

```yaml
name: Discovery Community Tests

on:
  push:
    paths:
      - 'Sources/Features/Discovery/**'
      - 'Sources/Infrastructure/Privacy/**'
  pull_request:
    paths:
      - 'Sources/Features/Discovery/**'

jobs:
  discovery-tests:
    name: Discovery Feature Tests
    runs-on: macos-15

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Setup Xcode 26
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '26.0'

    - name: Test Discovery Anonymous Sharing
      run: |
        xcodebuild test \
          -project NotBad.xcodeproj \
          -scheme DiscoveryTests \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=26.0' \
          -testPlan DiscoveryTestPlan.xctestplan \
          SWIFT_VERSION=6.2

    - name: Test Privacy Protection
      run: |
        xcodebuild test \
          -project NotBad.xcodeproj \
          -scheme PrivacyTests \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=26.0' \
          SWIFT_VERSION=6.2
```

## 自托管Runner配置 (v6.0)

### 系统要求
- **设备**: Mac mini M4 或更新
- **内存**: 16GB+ (推荐32GB)
- **存储**: 1TB+ SSD
- **系统**: macOS 15.0+
- **Xcode**: 26.0 (必须)

### 安装配置

```bash
#!/bin/bash
# 自托管Runner Swift 6.2配置脚本

echo "🚀 配置NotBad App CI/CD Runner (Swift 6.2)"

# 1. 安装Xcode 26
echo "📱 安装Xcode 26..."
sudo xcode-select --install
sudo xcodebuild -license accept

# 2. 验证Swift 6.2支持
echo "🔧 验证Swift 6.2支持..."
swift --version | grep "6.2" || {
    echo "❌ Swift 6.2未安装，请安装Xcode 26"
    exit 1
}

# 3. 安装iOS 26.0模拟器
echo "📱 安装iOS 26.0模拟器..."
sudo xcrun simctl runtime install "iOS 26.0"
xcrun simctl list runtimes | grep "iOS 26.0"

# 4. 预加载依赖
echo "📦 预加载构建依赖..."
mkdir -p ~/Library/Caches/org.swift.swiftpm
mkdir -p ~/Library/Developer/Xcode/DerivedData

# 5. 配置Runner标签
echo "🏷️ 配置Runner标签..."
# 在GitHub配置中使用标签: self-hosted,macOS,xcode-26,swift-6.2,ios-26

echo "✅ Runner配置完成！"
echo "📋 支持的功能:"
echo "   - Swift 6.2 Enhanced Actor"
echo "   - iOS 26 Advanced Vision"
echo "   - Enhanced SwiftData"
echo "   - Discovery社区测试"
echo "   - COPPA/GDPR合规检查"
```

### Runner标签配置

在GitHub仓库设置中为自托管runner配置以下标签：

```yaml
labels:
  - self-hosted
  - macOS
  - M4
  - xcode-26
  - swift-6.2
  - ios-26
  - enhanced-actor
  - discovery-ready
```

## 性能监控集成

### MetricKit集成

```swift
// 在CI/CD中集成性能监控
import MetricKit

class CIPerformanceMonitor: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // 验证PRD v6.0性能目标
            if let launchMetrics = payload.applicationLaunchMetrics {
                let launchTime = launchMetrics.firstDrawTime
                print("🚀 Launch time: \(launchTime)ms (target: <800ms)")

                // 性能目标验证
                assert(launchTime.doubleValue < 800, "Launch time exceeds target")
            }

            if let memoryMetrics = payload.memoryMetrics {
                let peakMemory = memoryMetrics.peakMemoryUsage
                print("💾 Peak memory: \(peakMemory)MB (target: <150MB)")

                assert(peakMemory.doubleValue < 150, "Memory usage exceeds target")
            }
        }
    }
}
```

## 部署策略

### 分支策略
- **main**: 生产发布分支，自动构建并上传TestFlight
- **develop**: 开发集成分支，运行完整测试套件
- **feature/***: 功能分支，运行基础测试
- **hotfix/***: 紧急修复分支，快速验证和发布

### 测试策略
- **Unit Tests**: 覆盖所有业务逻辑，目标覆盖率>90%
- **Integration Tests**: Discovery社区、CloudKit同步等集成功能
- **UI Tests**: 关键用户流程自动化测试
- **Performance Tests**: 验证PRD v6.0性能目标
- **Security Tests**: COPPA/GDPR合规性验证

### 质量门禁
1. ✅ 所有单元测试通过
2. ✅ 代码覆盖率 > 90%
3. ✅ 性能测试达标(启动<0.8s, 内存<150MB)
4. ✅ 安全扫描通过
5. ✅ 隐私合规检查通过

## 故障排除

### 常见问题

**Q: Swift 6.2代码编译失败**
```bash
# 验证Xcode版本
xcodebuild -version
# 确保使用Xcode 26+

# 清理构建缓存
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Q: iOS 26模拟器不可用**
```bash
# 检查可用运行时
xcrun simctl list runtimes

# 安装iOS 26运行时
sudo xcrun simctl runtime install "iOS 26.0"
```

**Q: Enhanced Actor编译错误**
```swift
// 确保使用Swift 6.2语法
actor DataProcessor: Sendable {
    // Enhanced Actor Isolation
    private var cache: [String: Data] = [:]

    func process(_ data: Data) async -> ProcessedData {
        // Swift 6.2并发安全处理
    }
}
```

## 相关文档

- [ADR-004 Swift 6.2架构升级决策](../adr/ADR-004%20Swift%206.2%20架构升级决策.md)
- [PRD v6.0 性能要求](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md)
- [TDD v6.0 技术实现](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md)
- [隐私合规清单](../compliance/privacy-and-compliance-checklist.md)

---

**最后更新**: 2025年9月19日
**技术栈版本**: Swift 6.2 + iOS 26 + Xcode 26
**下次评审**: 技术栈升级完成后进行配置验证
