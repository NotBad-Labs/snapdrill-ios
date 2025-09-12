# ADR-003: OCR引擎选型

## 状态
已接受 (Accepted) - 2025-09-12

## 决策者
技术团队

## 背景
NotBad错题本应用的核心功能是通过拍照快速录入错题内容。OCR(光学字符识别)技术是实现这一功能的关键。根据PRD v4.0要求，OCR识别率需要达到85%以上，识别时间应控制在3秒内。

## 决策
采用 **Apple Vision框架作为主要OCR引擎**，同时集成**离线CoreML模型**作为备选方案。

## 考虑的选项

### 选项1: Apple Vision框架
**优点:**
- iOS原生支持，性能优化良好
- 支持中英文混合识别
- 自动文本检测和边界框识别
- 隐私友好，本地处理
- 持续更新，识别精度不断提升
- 与iOS Camera集成良好

**缺点:**
- 仅限iOS平台
- 对手写文字识别精度有限
- 复杂数学公式识别能力较弱
- 无法定制化训练

### 选项2: 第三方云端OCR (腾讯/百度/Google)
**优点:**
- 识别精度高，特别是中文
- 支持复杂场景（手写、公式）
- 持续训练优化
- 跨平台支持

**缺点:**
- 需要网络连接
- 隐私和安全风险
- API调用成本
- 响应延迟
- 依赖第三方服务稳定性

### 选项3: 开源OCR (Tesseract/PaddleOCR)
**优点:**
- 免费开源
- 可定制化训练
- 支持多种语言

**缺点:**
- 集成复杂度高
- 需要大量优化工作
- 模型体积大
- 识别精度需要调优

### 选项4: 混合方案
**优点:**
- 结合多种引擎优势
- 可根据场景选择最优方案
- 降低单点故障风险

**缺点:**
- 实现复杂度高
- 增加应用体积
- 维护成本高

## 决策理由

1. **隐私优先**: Vision框架本地处理，符合COPPA合规要求
2. **性能稳定**: 苹果优化的本地识别，响应时间可控
3. **成本控制**: 避免第三方API调用费用
4. **用户体验**: 离线可用，不依赖网络连接
5. **开发效率**: 原生集成，开发周期短

## 实现策略

### 核心架构
```swift
protocol OCRServiceProtocol {
    func recognizeText(from image: Data) async throws -> OCRResult
    func reprocess(image: Data) async throws -> [OCRResult]
    func validateResult(_ result: OCRResult) -> Bool
}

class VisionOCRService: OCRServiceProtocol {
    private let visionEngine = VisionTextRecognizer()
    private let coreMLFallback = CoreMLOCREngine()
    
    func recognizeText(from image: Data) async throws -> OCRResult {
        // 主要使用Vision框架
        let result = try await visionEngine.recognize(image)
        
        // 如果置信度低，使用CoreML备选
        if result.confidence < 0.7 {
            return try await coreMLFallback.recognize(image)
        }
        
        return result
    }
}
```

### 质量保证策略
1. **置信度阈值**: 设置多级置信度阈值(0.9/0.7/0.5)
2. **结果验证**: 自动检测明显错误(乱码、异常字符)
3. **用户反馈**: 提供"重新识别"功能
4. **渐进增强**: 低置信度时提示用户手动调整

### 性能优化
```swift
class OCRPerformanceOptimizer {
    func preprocessImage(_ image: UIImage) -> UIImage {
        // 图像预处理：去噪、增强对比度、纠正倾斜
    }
    
    func optimizeForMath(_ image: UIImage) -> UIImage {
        // 数学公式特殊处理
    }
    
    func cacheFrequentResults() {
        // 缓存常见识别结果
    }
}
```

## 性能指标

### 目标指标
- **识别准确率**: >85% (PRD要求)
- **识别速度**: <3秒 (PRD要求)
- **置信度阈值**: >70%为可接受结果
- **离线可用性**: 100%

### 监控指标
- 识别成功率
- 平均识别时间
- 用户满意度评分
- 重新识别请求率

## 风险和缓解措施

### 风险1: 手写文字识别精度不足
**缓解措施:**
- 在拍照界面提供"清晰度指南"
- 集成手写专用CoreML模型
- 提供手动编辑功能

### 风险2: 数学公式识别困难
**缓解措施:**
- 针对数学符号训练专用模型
- 与第三方数学OCR API集成(Pro功能)
- 提供公式模板选择

### 风险3: 复杂背景干扰
**缓解措施:**
- 实现智能边界检测
- 提供手动框选功能
- 图像预处理优化

## 扩展计划

### 短期(3个月内)
- 实现基础Vision OCR集成
- 添加图像预处理优化
- 实现置信度评估系统

### 中期(6个月内)
- 集成手写识别CoreML模型
- 添加数学公式专用处理
- 实现用户反馈学习机制

### 长期(1年内)
- 评估第三方高精度OCR集成(Pro功能)
- 自训练定制化模型
- 实现实时OCR预览

## 测试策略

### 功能测试
- 不同光照条件下的识别测试
- 各种字体和手写风格测试
- 中英文混合内容测试
- 数学公式和特殊符号测试

### 性能测试
- 大量图片识别速度测试
- 内存使用和电池消耗测试
- 不同设备型号兼容性测试

### 用户体验测试
- A/B测试不同置信度阈值
- 用户满意度调研
- 错误处理流程测试

## 相关文档
- [PRD v4.0](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v4.0.md)
- [TDD v4.0](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v4.0.md)
- [技术术语表](../glossary/NotBad%20App%20-%20技术术语表%20v1.1.md)

## 审查计划
3个月后重新评估：
1. Vision框架识别精度是否达标
2. 用户对识别质量的反馈
3. 是否需要引入第三方OCR增强
4. CoreML模型的效果评估
