---
last_verified: 2026-06-13
layer: product-policy
derived_from:
  - vision.md#产品定位
  - vision.md#p5-冷静清晰成人生产力工具
---
# 产品定位与受众

> 本文件把 Vision 的通用受众定位转成 UI、营销和合规可执行约束。它记录产品目标和风险控制，不构成执业律师对具体司法辖区的最终法律意见。

## 已决定位

**SnapDrill 是面向通用受众的效率工具：扫描、归档、整理任何题目与文档。**

题目、试卷和学习资料是产品擅长处理的内容类型，不等于产品以儿童为目标受众。职业证书资料、培训材料、竞赛题、票据和普通文档属于同一套采集与归档工作流。

## 产品边界

- 不建立儿童独立账户、儿童模式或儿童专属入口。
- 不使用卡通角色、宠物养成、积分、勋章、闯关、签到、虚拟货币、童声或低龄化文案吸引儿童。
- 回顾功能使用“回顾、复盘、查漏”等生产力语言，不包装为儿童练习或游戏。
- App Store 类目优先 Productivity / Utilities，不以 Education 为主要类目叙事。
- 营销用例先展示成年人管理自己的资料，再展示家庭资料场景。

这些约束不禁止产品继续优化试卷、题目和学习资料的专业工作流。

## 隐私事实基线

当前生产实现的隐私事实由代码和构建实证决定：

- 无注册，不要求姓名、手机号、学校或年级。
- 用户内容保存在设备本地；当前未启用 CloudKit 同步。
- Firebase SDK 与 `SnapDrillInfrastructure` 已删除。
- 生产注入 `NoOpAnalyticsService`；设备诊断使用端侧 MetricKit 和 Apple 聚合数据。
- 图片入库前剥离 EXIF GPS / 位置信息。

任何对外隐私声明都必须与发布构建、Privacy Manifest、App Store Privacy 标签和网络流量实证一致。

## 法律状态

`general-audience` 是 PO 选择的产品定位和一致执行目标，不是仓库可以自行宣布完成的法律结论。是否构成 `directed-to-children` 需要结合产品实际呈现、营销、受众和数据处理进行整体判断，并由对应司法辖区的执业律师终审。

下列变化必须重新进行产品与法律复核：

- 引入儿童账户、儿童模式或儿童专属营销。
- 上传用户内容、面部、声音、笔迹或其他可能关联个人的数据。
- 引入第三方分析、广告、云 AI 或开发者可访问的后端。
- 开启 CloudKit 或其他跨设备同步，并改变公开隐私声明。
- 进入 Apple Kids Category 或将 Education 作为主要发行叙事。

## 追溯关系

| 本政策 | 上游依据 | 下游承接 |
|---|---|---|
| 通用受众效率工具 | Vision 产品定位 | App Store 元数据、官网、Onboarding、UI 文案 |
| 无儿童化受众信号 | Vision P5 | SnapDrillUI、Feature View、营销素材 |
| 隐私声明服从实证 | Vision P4 | Privacy Manifest、隐私政策、发布检查 |
| 变化触发复核 | Vision P4/P6 | ADR、法律审查、release readiness |
