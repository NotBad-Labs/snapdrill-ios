# 指标与埋点规范（v6.0）

**文档版本**: v6.0  
**最后更新**: 2025-09-18  
**关联文档**: [PRD v6.0](./NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0%20(Swift6.2%20+%20iOS26).md)

## 概述

本文档定义了 NotBad 错题本 App 的关键性能指标(KPI)、服务质量指标(SLA)和埋点规范，确保产品质量的可量化监控。

## 核心性能指标

### 1. 应用性能指标

#### 1.1 启动性能
- **指标**: 冷启动时间
- **定义**: 从用户点击应用图标到首屏完全渲染的时间
- **目标**: P95 < 1.2s
- **基准设备**: iPhone 12 / iPhone SE (2022) / current flagship
- **监控方式**: 
  - iOS 自带的 MetricKit
  - 自定义计时器（`DispatchTime.now()`）
- **埋点事件**: `app_launch_cold`
  ```swift
  // 埋点示例
  Analytics.track("app_launch_cold", parameters: [
      "duration_ms": duration,
      "device_model": deviceModel,
      "ios_version": iOSVersion,
      "app_version": appVersion
  ])
  ```

#### 1.2 响应性能
- **搜索首屏渲染**: P95 < 300ms
- **页面切换**: P95 < 300ms
- **OCR处理**: P95 < 2.5s
- **埋点事件**: `performance_metric`

#### 1.3 资源使用
- **内存使用（正常）**: P95 < 60MB
- **内存使用（OCR峰值）**: P95 < 300MB
- **滚动丢帧率**: P95 < 1%
- **AR渲染帧率**: P95 ≥ 60fps（支持设备）

### 2. 功能质量指标

#### 2.1 OCR 准确性
- **中文识别准确率**: P95 > 90%
- **监控方式**: 用户手动纠错统计
- **埋点事件**: `ocr_accuracy`
  ```swift
  Analytics.track("ocr_accuracy", parameters: [
      "confidence_score": confidence,
      "manual_corrections": correctionCount,
      "text_length": originalText.count,
      "language": "zh-CN"
  ])
  ```

#### 2.2 数据可靠性
- **数据完整性**: 99.9%
- **同步成功率**: >99%
- **崩溃率**: <0.05%

### 3. 用户体验指标

#### 3.1 用户参与度
- **日活跃用户**: 目标增长率 >20%/月
- **7天留存率**: >70%
- **30天留存率**: >40%
- **日均使用时长**: >15分钟/用户

#### 3.2 功能使用率
- **错题录入频率**: >3次/周/用户
- **复习完成率**: >60%
- **核心功能使用率**: >80%

## 埋点事件规范

### 1. 事件命名规范

#### 1.1 命名格式
```
{module}_{action}_{object}
```

#### 1.2 模块定义
- `app`: 应用级别事件
- `camera`: 拍照相关
- `ocr`: OCR处理相关
- `review`: 复习相关
- `sync`: 同步相关
- `user`: 用户行为相关

#### 1.3 动作定义
- `start`: 开始某个操作
- `complete`: 完成某个操作
- `fail`: 操作失败
- `cancel`: 用户取消操作

### 2. 核心埋点事件

#### 2.1 应用生命周期
```swift
// 应用启动
Analytics.track("app_launch_cold", parameters: [
    "duration_ms": Int,
    "device_model": String,
    "ios_version": String,
    "app_version": String
])

// 应用进入后台
Analytics.track("app_background", parameters: [
    "session_duration_ms": Int,
    "actions_count": Int
])

// 应用崩溃
Analytics.track("app_crash", parameters: [
    "crash_reason": String,
    "stack_trace": String,
    "device_info": [String: Any]
])
```

#### 2.2 错题录入流程
```swift
// 开始拍照
Analytics.track("camera_start_capture", parameters: [
    "entry_point": String, // "tab_bar", "quick_action", etc.
    "camera_permission": Bool
])

// 拍照完成
Analytics.track("camera_complete_capture", parameters: [
    "image_size_kb": Int,
    "image_resolution": String,
    "duration_ms": Int
])

// OCR 开始
Analytics.track("ocr_start_processing", parameters: [
    "image_size_kb": Int,
    "text_regions_detected": Int
])

// OCR 完成
Analytics.track("ocr_complete_processing", parameters: [
    "duration_ms": Int,
    "confidence_score": Float,
    "text_length": Int,
    "success": Bool
])

// 错题保存
Analytics.track("review_item_save", parameters: [
    "source": String, // "ocr", "manual", "import"
    "subject": String,
    "difficulty": String,
    "tags_count": Int
])
```

#### 2.3 复习流程
```swift
// 开始复习
Analytics.track("review_start_session", parameters: [
    "items_count": Int,
    "review_type": String, // "scheduled", "manual", "random"
    "trigger": String // "notification", "manual", "proactive"
])

// 复习完成
Analytics.track("review_complete_session", parameters: [
    "duration_ms": Int,
    "items_reviewed": Int,
    "items_mastered": Int,
    "accuracy_rate": Float
])

// 单题复习结果
Analytics.track("review_item_result", parameters: [
    "item_id": String,
    "result": String, // "correct", "incorrect", "skip"
    "time_spent_ms": Int,
    "difficulty_rating": Int
])
```

#### 2.4 同步相关
```swift
// 同步开始
Analytics.track("sync_start", parameters: [
    "sync_type": String, // "manual", "automatic", "background"
    "items_to_sync": Int
])

// 同步完成
Analytics.track("sync_complete", parameters: [
    "duration_ms": Int,
    "items_synced": Int,
    "success": Bool,
    "error_code": String?
])
```

### 3. 性能监控埋点

#### 3.1 内存监控
```swift
// 定期内存使用报告
Analytics.track("performance_memory", parameters: [
    "memory_used_mb": Float,
    "memory_available_mb": Float,
    "memory_pressure": String, // "normal", "warning", "critical"
    "active_features": [String]
])
```

#### 3.2 网络监控
```swift
// 网络请求性能
Analytics.track("performance_network", parameters: [
    "request_type": String,
    "duration_ms": Int,
    "response_size_kb": Int,
    "success": Bool,
    "error_code": String?
])
```

### 4. 用户行为分析

#### 4.1 功能使用统计
```swift
// 功能访问
Analytics.track("feature_usage", parameters: [
    "feature_name": String,
    "access_method": String, // "tab", "shortcut", "search", etc.
    "session_id": String
])

// 搜索行为
Analytics.track("search_query", parameters: [
    "query_text": String.sha256, // 隐私保护：哈希处理
    "results_count": Int,
    "filter_applied": [String],
    "result_clicked": Bool
])
```

### 5. 错误监控

#### 5.1 错误分类
```swift
// 一般错误
Analytics.track("error_occurred", parameters: [
    "error_type": String, // "network", "parsing", "permission", etc.
    "error_code": String,
    "error_message": String,
    "user_action": String, // 用户当时执行的操作
    "recovery_action": String? // 系统恢复操作
])

// OCR 错误
Analytics.track("ocr_error", parameters: [
    "error_type": String, // "timeout", "format_unsupported", "processing_failed"
    "image_characteristics": [String: Any],
    "retry_count": Int
])
```

## 隐私与合规

### 1. 数据脱敏规则
- 所有用户输入内容进行 SHA-256 哈希处理
- 不收集用户真实姓名、学校等敏感信息
- 设备标识符使用应用级别 UUID

### 2. 未成年人保护
- 13岁以下用户数据自动匿名化
- 家长同意机制集成
- 数据最小化收集原则

### 3. 数据保留策略
- 埋点数据保留期：90天
- 性能数据保留期：30天
- 错误日志保留期：7天
- 用户可随时申请数据删除

## 监控告警

### 1. 实时告警阈值
- 崩溃率 > 0.1%
- 启动时间 P95 > 2.0s
- 内存使用 > 100MB（正常场景）
- OCR 成功率 < 85%

### 2. 趋势告警
- 日活用户下降 > 10%
- 留存率下降 > 5%
- 错误率上升 > 50%

## 报告与分析

### 1. 日报指标
- 新增用户数
- 活跃用户数
- 错题录入量
- 复习完成率
- 关键性能指标

### 2. 周报分析
- 用户留存分析
- 功能使用趋势
- 性能优化建议
- 错误修复优先级

### 3. 月报总结
- 产品健康度评估
- 用户反馈汇总
- 技术债务评估
- 下个版本规划建议

---

**实施说明**: 
1. 埋点实施采用渐进式部署，优先核心流程
2. 所有埋点事件必须经过隐私审查
3. 监控系统采用实时 + 批处理双轨制
4. 数据分析结果定期更新产品决策