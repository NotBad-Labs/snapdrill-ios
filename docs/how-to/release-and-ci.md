---
last_verified: 2026-05-25
layer: pattern
freshness:
  max_age_days: 60
  decay_trigger: [ci_change, distribution_change]
---
# SnapDrill 部署与运维

> App Store 发布流程、版本管理、CI/CD、监控。
> DevOps 详细 checklist 见下文 §发版检查清单（已合并入本文件）。

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
触发条件：PR → develop/main，push → develop/main，或手动触发
Runner：Docs Audit 使用 ubuntu-latest；Build & Test 使用 Mac mini 自托管（self-hosted, macOS）
步骤：
  1. Docs Audit（并行）：docaudit self-test + docaudit all --strict --baseline
  2. Select Xcode（优先 Xcode_26.4.app；要求 Xcode 26.4+ / Swift 6.3）
  3. SwiftLint --strict
  4. validate_frontmatter.py --check --strict
  5. Check Package Dependencies（包依赖方向 + Share Extension import 约束）
  6. Clean Simulator（erase iPhone 17，避免 SwiftData 残留）
  7. Validate AllTests.xctestplan JSON
  8. xcodebuild build-for-testing -scheme AllTests -testPlan AllTests
     -derivedDataPath $GITHUB_WORKSPACE/DerivedData
     -destination 'platform=iOS Simulator,name=iPhone 17'
     CODE_SIGNING_ALLOWED=NO
  9. xcodebuild test-without-building
     -xctestrun $(find ... AllTests_*.xctestrun)
     -only-test-configuration CI
     -parallel-testing-enabled NO
     -resultBundlePath TestResults.xcresult
  10. Upload xcresult on failure
```

注：CI 运行 `AllTests.xctestplan` 的 CI configuration，包含 4 个 test target（SnapDrillCoreTests / SnapDrillDataTests / SnapDrillFeaturesTests / SnapDrillShareTests）。`test-without-building` 复用 `build-for-testing` 产出的 DerivedData，避免重复编译。`SnapshotRecord` configuration 仅本地用（`SNAPSHOT_TESTING_RECORD=all` 重录 baseline），不参与 CI。

### GitHub Token 配置

严禁把 GitHub token 写入 `.claude/settings.local.json`、脚本、文档或任何可提交文件。`.claude/settings.local.json` 只允许保存本机权限偏好，已由 `.gitignore` 排除。

本地命令优先读取环境变量：

```bash
export GITHUB_TOKEN="<your-github-token>"
```

需要长期保存时使用 macOS 钥匙串：

```bash
security add-generic-password -a "$USER" -s snapdrill-github-token -w "$GITHUB_TOKEN" -U
export GITHUB_TOKEN="$(security find-generic-password -a "$USER" -s snapdrill-github-token -w)"
```

### Mac mini Runner

- 自托管 runner（self-hosted, macOS）
- 离线时任务排队等待

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
   - 截图（iPhone 6.9"/6.3"，iPad 12.9"）
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

### 国内版：无第三方监控（ADR-004）

- 国内 build（当前单一 build）运行时注入 `NoOpAnalyticsService`，**Firebase 不初始化**（不调 `FirebaseApp.configure()`）；OSLog 抓包实证 opt-in 前零网络出境
- 崩溃监控：Apple 原生 **Xcode Organizer / MetricKit**，无第三方 SDK 上报
- Firebase SDK 仍链接（编译层彻底剔除待 C 路径 Release-CN 拆分）

### 海外版（未来，C 路径）

- 保留 Firebase Crashlytics + Analytics，受 GDPR/CCPA 管辖，opt-in 披露

### 紧急修复流程

```
1. Xcode Organizer / MetricKit 发现高频崩溃
2. 创建 hotfix 分支 → 修复 → PR → 快速 Review
3. TestFlight 验证 → App Store 加急审核（Expedited Review）
4. Apple 通常 24 小时内处理加急请求
```

---

## 环境配置

| 环境 | 用途 | 分析配置 |
|---|---|---|
| Debug | 本地开发 + Simulator | `NoOpAnalyticsService`（国内版）|
| Release | TestFlight + App Store（国内）| `NoOpAnalyticsService`（国内版）|

**注意**：国内版不使用 `GoogleService-Info.plist`（2026-05-28 已移除，见 ADR-004）。海外版（未来 C 路径）再引入 Firebase 配置并按 Release-CN / Release-Global 分离。

## 发版检查清单
---
# TestFlight 发版前检查清单

> **上游依赖**：本文件 §发布流程（已合并发版流程）
>
> 每次 build 推送到 TestFlight 前，在真机上走完以下流程。
> 标注 ❌ 的项目必须修复后才能发版。
>
> Last verified: 2026-05-18（与 frontmatter 同步，文档治理审计 P1 刷新）

---

## 启动与首屏

- [ ] App 冷启动不崩溃
- [ ] 首次安装：Onboarding 正确显示
- [ ] Onboarding 翻页有轻触震动，点击「开始使用」有 success 震动
- [ ] 非首次安装：直接进入主界面
- [ ] 首页数据加载正常（进度环、题目数量不显示为 0 或 loading 卡死）

## 拍题流程（Capture）

- [ ] 相机权限弹窗正常出现（首次）
- [ ] 相机预览正常
- [ ] 拍照后进入裁剪器，裁剪后 OCR 识别并进入编辑界面
- [ ] OCR 识别结果可手动修正，修正后保存的是修正值
- [ ] 相册导入：选择照片后进入裁剪器，裁剪后 OCR 识别结果正确
- [ ] 手动编辑录入：不拍照，直接输入文字创建题目
- [ ] 保存后自动返回摄像头界面（连续录入）
- [ ] 保存后题库和复习界面待复习数量均更新
- [ ] 字段自动推断：第二次录入时，学科自动沿用上次选值
- [ ] 草稿恢复：录入中途退出 App，重新进入后 Dashboard 显示「恢复草稿」提示
- [ ] 选择「恢复草稿」进入编辑界面，图片和文字完整保留

## 题库（Library）

- [ ] 无题目时显示空状态（「暂无错题」+「去采集」按钮）
- [ ] 列表正常显示所有题目
- [ ] 搜索功能有效（基于 OCR 文字）
- [ ] 科目/标签过滤有效（多维组合）
- [ ] 排序切换有效（时间/学科/难度/复习状态）
- [ ] 点击题目进入详情
- [ ] 详情页可以编辑并保存（补答案、改难度、加标签）
- [ ] 删除题目后列表更新
- [ ] 过滤后 PDF 导出：预览窗口可见，PDF 可分享

## 复习（Review）

- [ ] 待复习数量显示正确
- [ ] 「开始复习」进入卡片
- [ ] 题目正面内容正常显示（文字题、图片题均测试）
- [ ] 翻转卡片显示答案
- [ ] 翻转卡片时有轻触震动反馈
- [ ] 向右滑：记住了，下一张
- [ ] 向左滑：忘了，下一张
- [ ] 点击「忘记/记得」评分按钮有 medium 震动反馈
- [ ] 点击「撤销/显示答案」按钮有 light 震动反馈
- [ ] 撤销按钮有效
- [ ] 所有卡片完成后显示完成界面，并触发 success 震动
- [ ] 退出复习后回到首页，进度更新
- [ ] 复习卡片外观设置：字号调整生效（正面/背面独立）
- [ ] VoiceOver：翻卡公告、完成摘要公告、操作按钮辅助标签可读

## 首页（Dashboard）

- [ ] 无题目时显示空状态引导（「还没有任何题目」+「去采集」按钮），不显示 0 数据仪表盘
- [ ] 「去采集」按钮可以正确跳转到采集 Tab
- [ ] 有题目时正常显示进度环、题目数量、Bento 卡片
- [ ] 进度环数值与实际复习进度一致
- [ ] 题库跳转按钮有效
- [ ] 科目管理跳转有效
- [ ] 「今日新增」显示正确数量（纯展示，不可点击跳转）
- [ ] 有草稿时显示「恢复草稿」提示
- [ ] 用户资料：昵称显示在问候语中，座右铭显示正确

## 设置（Settings）

- [ ] 字段可配置：设置中可开关学科/难度/来源/年级字段，录入界面仅显示已开启字段
- [ ] 系统字段选项管理：学科/来源/年级可新增、编辑（含颜色/图标）、删除（使用中的阻止删除）
- [ ] 用户资料编辑：昵称、座右铭、头像、每日复习目标可修改并保存
- [ ] 通知设置：提醒时间、声音开关均有效（**不使用角标**，见 ../features/active/feat-settings.md）
- [ ] 外观模式切换：跟随系统 / 浅色 / 深色 三种模式均可
- [ ] 语言设置：App 内直选语言（中文/英文），切换后提示重启生效
- [ ] 使用数据开关：Analytics + 崩溃报告开关状态持久化，重启后生效（国内版开关为架构预留，NoOp 无实际采集）
- [ ] 媒体缓存清理：点击后空间释放，不影响题目数据
- [ ] 隐私政策页面可以打开
- [ ] 服务条款页面可以打开
- [ ] 开源许可页面可以打开，且列出 Mantis、ZIPFoundation 等；Firebase SDK 国内版编译层尚未剔除（待 C 路径，ADR-004），运行时不初始化
- [ ] 帮助中心：跳转到外部网页 FAQ，链接可打开
- [ ] 生成测试数据后：题库和复习界面均刷新
- [ ] 清空数据后：题库和复习界面均清空

## 多 Profile

- [ ] Profile 创建：可创建新 Profile（如「孩子A」「孩子B」）
- [ ] Profile 切换：设置页或 Dashboard 头像区域可切换，切换后题库/统计/复习进度完全独立
- [ ] Profile 数据隔离：不同 Profile 的题目互不可见
- [ ] Profile 持久化：切换后再切回，原 Profile 数据完整保留
- [ ] Profile 备份恢复：全 Profile 备份/恢复（#531 已修复）

## 数据与同步

- [ ] 备份：点击后创建 .zip 文件，触发系统分享面板
- [ ] 恢复：点击后打开文件选择器，选择备份文件后数据和图片均完整恢复
- [ ] 恢复期间有进度提示
- [ ] JSON 导出：隐私设置页触发，文件可打开且含所有字段
- [ ] CSV 导出：隐私设置页触发，Excel 可打开且格式正确

## 引导与提醒

- [ ] 首次录入保存后：弹出字段配置引导提示
- [ ] Feature Tooltips：首次使用某功能时弹出轻量提示气泡（每个只显示一次）
- [ ] 卸载数据丢失提醒：设置页有醒目提示（免费版纯本地，卸载 = 数据永久丢失）

## 稳定性

- [ ] 连续使用 10 分钟不崩溃
- [ ] 切换 Tab 多次不崩溃
- [ ] 后台切换后回到前台状态正确恢复

---

## 发版信息核对

- [ ] Build Number 已更新（每次发版 +1，只改 `Configs/Shared.xcconfig`）
- [ ] 没有 Debug 专用 UI 暴露在外
- [ ] 没有硬编码的测试账号或假数据

## 文档健康检查（每次发版必做）

- [ ] Claude Auto Memory 行数合理（超过 150 行则审计剪枝）
- [ ] 检查是否有新内容同时存在于 Auto Memory、`.claude/skills/` 和 `docs/`（若有，保留公开权威文档或对应 SKILL.md，Memory 改为指针）
