# Difficulty 值对象 - 快速参考

> 优化后的完整 API 参考

---

## 📌 基本信息

```swift
enum Difficulty: Int, Sendable {
    case basic = 0    // 送分题
    case easy = 1     // 简单题
    case medium = 2   // 中等题
    case hard = 3     // 困难题
    case extreme = 4  // 压轴题
}
```

**协议支持**: Identifiable, CaseIterable, Codable, Hashable, Comparable, CustomStringConvertible

---

## 🎨 显示属性 (Display Properties)

| 属性 | 类型 | 示例 | 用途 |
|-----|------|------|------|
| `displayName` | String | "中等" | 完整显示名称 |
| `shortLabel` | String | "中" | 简短标签 |
| `detailText` | String | "需要一定分析..." | 详细描述 |

```swift
let difficulty = Difficulty.medium
print(difficulty.displayName)  // "中等"
print(difficulty.shortLabel)   // "中"
print(difficulty.detailText)   // "需要一定分析，容易粗心出错"
```

---

## 🖼 视觉属性 (Visual Properties)

| 属性 | 类型 | 示例 | 用途 |
|-----|------|------|------|
| `icon` | String | "star.leadinghalf.filled" | SF Symbol 图标 |
| `color` | Color | .yellow | SwiftUI 颜色 |
| `stars` | Int | 3 | 星级评分 (1-5) |

```swift
Image(systemName: difficulty.icon)
    .foregroundStyle(difficulty.color)
Text("\(difficulty.stars) ⭐️")
```

---

## 📊 度量属性 (Metrics)

| 属性 | 类型 | 范围 | 说明 |
|-----|------|------|------|
| `coefficient` | Double | 0.0-1.0 | 归一化难度值 |
| `reviewPriority` | Int | 1-5 | 建议复习优先级 |
| `timeMultiplier` | Double | 0.5-3.0 | 预计耗时倍数 |

```swift
let coef = difficulty.coefficient       // 0.5
let priority = difficulty.reviewPriority // 3
let time = difficulty.timeMultiplier    // 1.5
```

---

## 💡 使用示例

### 1. Picker 选择器
```swift
Picker("难度", selection: $difficulty) {
    ForEach(Difficulty.allCases) { diff in
        Label(diff.displayName, systemImage: diff.icon)
            .tag(diff)
    }
}
```

### 2. List 列表
```swift
List(Difficulty.allCases) { diff in
    HStack {
        Image(systemName: diff.icon)
            .foregroundStyle(diff.color)
        VStack(alignment: .leading) {
            Text(diff.displayName)
            Text(diff.detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

### 3. 自定义徽章
```swift
struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        Label(difficulty.shortLabel, systemImage: difficulty.icon)
            .padding(8)
            .background(difficulty.color.opacity(0.2))
            .foregroundStyle(difficulty.color)
            .clipShape(Capsule())
    }
}
```

### 4. 条件渲染
```swift
if difficulty >= .hard {
    Text("这是一道难题")
        .foregroundStyle(.red)
}
```

### 5. 排序和过滤
```swift
let sortedItems = items.sorted { $0.difficulty < $1.difficulty }
let hardItems = items.filter { $0.difficulty >= .hard }
```

---

## 🔍 协议功能

### Identifiable
```swift
// 用于 ForEach, List
difficulty.id  // 返回 rawValue (0-4)
```

### CaseIterable
```swift
Difficulty.allCases  // [.basic, .easy, .medium, .hard, .extreme]
Difficulty.allCases.count  // 5
```

### Comparable
```swift
Difficulty.basic < Difficulty.hard  // true
Difficulty.extreme > Difficulty.easy  // true
```

### CustomStringConvertible
```swift
print(difficulty)  // 输出 "中等"
"\(difficulty)"    // 返回 displayName
```

### Codable
```swift
// JSON 编码/解码
let data = try JSONEncoder().encode(difficulty)
let decoded = try JSONDecoder().decode(Difficulty.self, from: data)
```

---

## 📈 值映射表

| Case | Raw | displayName | shortLabel | icon | color | stars | coefficient |
|------|-----|-------------|------------|------|-------|-------|-------------|
| basic | 0 | 送分 | 送 | gift | mint | 1 | 0.0 |
| easy | 1 | 简单 | 易 | star | green | 2 | 0.25 |
| medium | 2 | 中等 | 中 | star.leadinghalf.filled | yellow | 3 | 0.5 |
| hard | 3 | 困难 | 难 | star.fill | orange | 4 | 0.75 |
| extreme | 4 | 压轴 | 压 | flame.fill | red | 5 | 1.0 |

---

## ⚡️ 性能提示

- ✅ 枚举是值类型，栈上分配
- ✅ 计算属性会被内联优化
- ✅ switch 语句完整覆盖，编译器优化
- ✅ 只占用 1 字节内存 (Int rawValue)
- ✅ 线程安全 (Sendable)

---

## 🚨 常见模式

### ✅ 推荐
```swift
// 使用枚举
if difficulty == .hard { }

// 使用属性
Text(difficulty.displayName)

// 使用比较
if difficulty >= .medium { }
```

### ❌ 避免
```swift
// 魔法数字
if difficulty.rawValue == 3 { }

// 硬编码字符串
if difficulty.displayName == "困难" { }

// 强制解包
Difficulty(rawValue: value)!
```

---

## 📚 相关文档

- `DIFFICULTY_VALUE_OBJECT_REVIEW.md` - 详细审查报告
- `VALUE_OBJECT_BEST_PRACTICES.md` - 最佳实践指南
- `DIFFICULTY_REVIEW_SUMMARY.md` - 完成总结

---

**最后更新**: 2025年11月25日  
**版本**: 2.0 (优化后)  
**状态**: ✅ 生产就绪
