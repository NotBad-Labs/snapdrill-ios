# SnapDrill 部署与运维

> App Store 发布流程、版本管理、CI/CD、监控。
> DevOps 详细 checklist 见 `../../.claude/skills/devops/references/release-checklist.md`。

---

## 版本管理

### 版本号单一来源

```
Configs/Shared.xcconfig
├── MARKETING_VERSION = 1.1.0    ← App Store 显示版本
└── CURRENT_PROJECT_VERSION = 5  ← Build 号（每次提交递增）
```

**铁律**：只改 `Shared.xcconfig`，不在 Xcode Target 设置中改版本号。

### 语义版本规则

- **Major**（x.0.0）：重大功能变更或破坏性改动
- **Minor**（1.x.0）：新功能
- **Build**（递增整数）：每次 TestFlight/App Store 提交递增

---

## CI/CD

### GitHub Actions

```yaml
# .github/workflows/ci.yml
触发条件：PR → develop/main，或手动触发
Runner：Mac mini 自托管（self-hosted, macOS）
步骤：
  1. Select Xcode（自动检测最新版本）
  2. SwiftLint --strict
  3. xcodebuild build-for-testing（编译 + 测试 target）
  4. xcodebuild test -scheme SnapDrillFeaturesTests（运行测试）
```

### Mac mini Runner

- 地址：`ssh admin@192.168.1.224`
- 离线时任务排队等待
- Xcode 版本：26.2 / 26.3 / 26.4（自动选最新）

---

## 发布流程

### TestFlight（内部测试）

```
1. Shared.xcconfig 递增 CURRENT_PROJECT_VERSION
2. Xcode → Product → Archive
3. Organizer → Distribute App → TestFlight Internal
4. 等待 Apple 处理（通常 < 30 分钟）
5. TestFlight App 自动收到更新
```

### App Store（正式发布）

```
1. TestFlight 验证通过
2. App Store Connect 填写发布信息
   - 截图（iPhone 6.7"/6.1"，iPad 12.9"）
   - ASO 文案（标题/副标题/关键词/描述，中英双语）
   - 隐私政策 URL + 服务条款 URL
   - 审核备注
3. 提交审核（通常 24-48 小时）
4. 审核通过后手动发布或定时发布
```

### 审核注意事项

- 年龄分级 4+（无不当内容）
- 不进入 Kids Category
- 隐私清单与实际一致
- 避免 "children" "kids" 等触发审查的措辞
- 首次提交附审核备注说明 App 功能

---

## 监控

### Firebase Crashlytics

- 崩溃自动上报（用户可关闭）
- 按版本号分组
- 优先修复 S0/S1 级崩溃

### Firebase Analytics

- 匿名事件：录入/复习/导出/导出等核心操作
- 用户留存：DAU/WAU/MAU
- 用户可在设置中关闭

### 紧急修复流程

```
1. Crashlytics 发现高频崩溃
2. 创建 hotfix 分支 → 修复 → PR → 快速 Review
3. TestFlight 验证 → App Store 加急审核（Expedited Review）
4. Apple 通常 24 小时内处理加急请求
```

---

## 环境配置

| 环境 | 用途 | Firebase 配置 |
|---|---|---|
| Debug | 本地开发 + Simulator | GoogleService-Info.plist（dev） |
| Release | TestFlight + App Store | GoogleService-Info.plist（prod） |

**注意**：`GoogleService-Info.plist` 在 `.gitignore` 中，不提交到 Git。
