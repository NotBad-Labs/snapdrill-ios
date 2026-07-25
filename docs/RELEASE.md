# SnapDrill 构建与发布

- 状态：当前发布流程与 live 配置
- 最后核实：2026-07-25

产品发布范围来自 [PRD.md](PRD.md)，数据安全要求来自 [DATA.md](DATA.md)。本文只记录当前
构建、验证、签名和发布步骤，不保存历史 CI run 或审计报告。

## 1. Live 配置

| 项目 | 当前值 | 代码 owner |
|---|---|---|
| 最低系统 | iOS 26.0 | project / package deployment targets |
| 设备 | iPhone-only | `TARGETED_DEVICE_FAMILY = 1` |
| Mac / Vision compatibility | 关闭 | Xcode project build settings |
| Team | `J58U72W335` | Xcode project |
| App Bundle ID | `com.snapdrill.global` | `Configs/Shared.xcconfig` |
| Share Bundle ID | `com.snapdrill.global.share` | Xcode project |
| App Group | `group.com.snapdrill.global` | App / Share entitlements |
| Marketing Version | `1.1.0` | `Configs/Shared.xcconfig` |
| Build | `6` | `Configs/Shared.xcconfig` |
| 语言 | 英文、简体中文 | localization resources |

表中值是 2026-07-25 的开发配置快照，不表示已经公开发布。Share target 和 App Group 是当前
实现事实，但 [PRD.md](PRD.md) 尚未批准 Share Extension 进入首版。配置文件是机器事实 owner；
两者不一致时先核实 live 配置并更新本文，不能仅凭本文修改签名或发布资源。

## 2. 本地源码门禁

候选提交在 clean checkout 运行：

```bash
bash Scripts/ci-local.sh
```

该门禁验证：

- 精确工具链；
- SwiftLint；
- 脚本和文档测试；
- Package 依赖方向；
- `AllTests` build-for-testing；
- 非 UI 的 test-without-building。

它不替代 UI / AX、真机相机、文档扫描、打印、archive、安装或隐私网络验证。

## 3. CI

GitHub Actions 必须 checkout PR 的精确 head，并使用 `Configs/Toolchain.env` 验证 runner 工具链。
Mac mini 是首选 self-hosted runner，MacBook Air 是按需备用；runner 不可用时可以继续本地开发
和 Draft PR，但不能把本地结果伪装成 GitHub CI。

CI artifact、日志和截图由对应 run 保存，不复制进 `docs/`。

## 4. 候选验证顺序

1. 冻结 source commit、版本号和 build number；
2. clean local gate；
3. GitHub CI；
4. 受影响 UI tests 与 Accessibility Audit；
5. 真机安装、启动、相机和文档扫描；
6. 真实 PDF 预览、系统分享和打印；
7. 数据故障、草稿、删除、备份和恢复路径；
8. archive 与签名检查；
9. 隐私清单、entitlements、网络行为和商店文案一致性；
10. PO 单独决定上传、测试范围和 go / no-go。

任何 source commit、版本、build、签名或可见能力变化都会产生新候选；旧候选证据不能无说明
继承。

## 5. 发布阻断

以下任一项未关闭时不得公开：

- 数据不可逆丢失、资料库假空或恢复破坏现有数据；
- 核心链路崩溃、白屏或无法完成；
- 路径穿越、恶意备份导致崩溃 / OOM 或意外文件访问；
- 未声明的内容上传、追踪、广告、IAP、账号或第三方分析；
- VoiceOver、Dynamic Type 或支持的 iPhone viewport 无法完成核心任务；
- 产品、隐私文案、entitlements、签名和 binary 行为不一致；
- 未批准功能在公开构建中可达或产生副作用。

## 6. 外部动作

PR 状态与合并授权只按 [DEVELOPMENT.md](DEVELOPMENT.md) §7 执行。以下不可逆外部动作必须逐次
取得 PO 明确授权：

- 修改生产账号、证书、标识符或密钥；
- 上传 archive；
- 向非 PO 用户开放下载；
- TestFlight / App Store go / no-go；
- 正式发布或撤回。

执行后在 PR 或发布系统中保留回执，不在仓库维护第二份运行日志。
