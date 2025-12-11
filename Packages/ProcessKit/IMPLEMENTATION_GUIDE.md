# ProcessKit 实施指南

**目标**：从零实现 Core ML 手写擦除功能

---

## 📋 前置条件

- ✅ Xcode 15+
- ✅ Python 3.8+ (用于模型转换)
- ✅ 基础 PyTorch/TensorFlow 知识（可选）

---

## 🚀 Phase 1: 快速启动（1-2 天）

### 步骤 1：寻找开源模型

**推荐来源**：

1. **Hugging Face**
   ```bash
   # 搜索关键词
   document denoising
   handwriting removal
   document cleaning
   ```

2. **GitHub**
   ```bash
   # 热门仓库
   - cyclegan-pix2pix (PyTorch)
   - U-Net-PyTorch
   - document-enhancement
   ```

3. **Papers with Code**
   - 论文: "Document Image Binarization"
   - 数据集: DIBCO, Palm Leaf Manuscript

### 步骤 2：转换为 Core ML

**安装工具**：
```bash
pip install coremltools torch torchvision
```

**转换脚本** (`convert.py`)：
```python
import coremltools as ct
import torch
from model import UNet  # 假设您下载的模型

# 1. 加载 PyTorch 模型
model = UNet(in_channels=3, out_channels=1)
model.load_state_dict(torch.load('pretrained.pth'))
model.eval()

# 2. 追踪模型
example_input = torch.rand(1, 3, 512, 512)
traced_model = torch.jit.trace(model, example_input)

# 3. 转换为 Core ML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.ImageType(name="input", shape=(1, 3, 512, 512))],
    outputs=[ct.TensorType(name="output")],
    minimum_deployment_target=ct.target.iOS17
)

# 4. 保存
mlmodel.save("HandwritingRemoval.mlmodel")
```

### 步骤 3：集成到 ProcessKit

**放置模型**：
```
Packages/ProcessKit/Sources/ProcessKit/Resources/
└── HandwritingRemoval.mlmodel
```

**Swift 代码** (在 `ImageProcessor.swift` 中)：
```swift
private func loadModel() async throws {
    guard let modelURL = Bundle.module.url(
        forResource: "HandwritingRemoval",
        withExtension: "mlmodel"
    ) else {
        throw ProcessError.modelNotFound("HandwritingRemoval")
    }
    
    let config = MLModelConfiguration()
    config.computeUnits = .all  // 使用 Neural Engine
    
    self.mlModel = try await MLModel.load(
        contentsOf: modelURL,
        configuration: config
    )
}

private func performInference(_ image: PlatformImage) async throws -> CIImage {
    guard let model = mlModel else {
        try await loadModel()
        return try await performInference(image)
    }
    
    // 1. 转换输入
    let pixelBuffer = try imageToPixelBuffer(image, size: CGSize(width: 512, height: 512))
    
    // 2. 推理
    let input = try MLDictionaryFeatureProvider(dictionary: ["input": pixelBuffer])
    let output = try model.prediction(from: input)
    
    // 3. 提取输出
    guard let outputFeature = output.featureValue(for: "output"),
          let multiArray = outputFeature.multiArrayValue else {
        throw ProcessError.imageProcessingFailed
    }
    
    // 4. 转回图片
    return try multiArrayToCIImage(multiArray)
}
```

---

## ⚡ Phase 2: 优化体积（1 周后）

### Int8 量化

**量化脚本** (`quantize.py`)：
```python
import coremltools as ct

# 加载原始模型
model = ct.models.MLModel('HandwritingRemoval.mlmodel')

# 量化为 Int8
from coremltools.models.neural_network import quantization_utils
quantized_model = quantization_utils.quantize_weights(model, nbits=8)

# 保存量化模型
quantized_model.save('HandwritingRemoval_int8.mlmodel')
```

**体积对比**：
```bash
ls -lh *.mlmodel
# HandwritingRemoval.mlmodel        → 80MB
# HandwritingRemoval_int8.mlmodel   → 20MB  (缩小 75%)
```

**精度验证**：
```swift
// 对比量化前后的输出差异
let originalOutput = try await originalModel.predict(...)
let quantizedOutput = try await quantizedModel.predict(...)
let mse = calculateMSE(originalOutput, quantizedOutput)
print("精度损失: \(mse)")  // 通常 < 0.05
```

---

## 🎓 Phase 3: 自研训练（用户反馈后）

### 数据准备

**合成方法**（避免手动标注）：

```python
import cv2
import numpy as np

def synthesize_training_pair(blank_paper, handwriting_overlay):
    """
    blank_paper: 空白试卷 (干净图)
    handwriting_overlay: 手写字PNG (带透明度)
    """
    # 1. 叠加手写
    paper_with_writing = cv2.addWeighted(
        blank_paper, 0.7,
        handwriting_overlay, 0.3,
        0
    )
    
    # 2. 添加噪声（模拟扫描）
    noise = np.random.normal(0, 5, paper_with_writing.shape)
    noisy_paper = np.clip(paper_with_writing + noise, 0, 255)
    
    return {
        'input': noisy_paper,    # 带手写的（输入）
        'target': blank_paper    # 干净的（目标输出）
    }

# 批量生成
for i in range(1000):
    pair = synthesize_training_pair(blank, random_handwriting())
    save_pair(f'data/{i}_input.png', f'data/{i}_target.png', pair)
```

### 训练 U-Net

**PyTorch 代码** (`train.py`)：
```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

# U-Net 模型（简化版）
class UNet(nn.Module):
    def __init__(self):
        super().__init__()
        # 编码器
        self.enc1 = nn.Conv2d(3, 64, 3, padding=1)
        self.enc2 = nn.Conv2d(64, 128, 3, padding=1)
        
        # 解码器
        self.dec1 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.dec2 = nn.ConvTranspose2d(64, 3, 2, stride=2)
        
    def forward(self, x):
        e1 = self.enc1(x)
        e2 = self.enc2(e1)
        d1 = self.dec1(e2)
        d2 = self.dec2(d1)
        return d2

# 训练循环
model = UNet().cuda()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-4)
criterion = nn.L1Loss()

for epoch in range(100):
    for batch in dataloader:
        input_img, target_img = batch
        
        # 前向传播
        output = model(input_img.cuda())
        loss = criterion(output, target_img.cuda())
        
        # 反向传播
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
    print(f"Epoch {epoch}, Loss: {loss.item()}")

# 保存模型
torch.save(model.state_dict(), 'custom_model.pth')
```

---

## 📊 性能优化技巧

### 1. 输入预处理优化
```swift
// 使用 Accelerate 框架加速
import Accelerate

func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
    var sourceBuffer = vImage_Buffer()
    var destBuffer = vImage_Buffer()
    
    // vImage 比 CoreGraphics 快 3-5 倍
    vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
    
    return UIImage(buffer: destBuffer)
}
```

### 2. 批量处理
```swift
// 如果用户一次扫描多页
func batchRemoveHandwriting(_ images: [UIImage]) async throws -> [UIImage] {
    // Core ML 支持批量推理
    let inputs = images.map { imageToPixelBuffer($0) }
    let batchInput = try MLArrayBatchProvider(array: inputs)
    
    let predictions = try await model.predictions(from: batchInput)
    return predictions.map { pixelBufferToImage($0) }
}
```

### 3. 后台处理
```swift
// 避免阻塞主线程
Task.detached(priority: .userInitiated) {
    let result = try await processor.removeHandwriting(from: image)
    await MainActor.run {
        imageView.image = result.image
    }
}
```

---

## 🐛 常见问题

### Q1: 模型转换报错 "Unsupported operation"
**A**: Core ML 不支持所有 PyTorch 操作，需要简化模型：
```python
# 避免使用
- torch.nn.Upsample (改用 ConvTranspose2d)
- 动态 shape (固定输入尺寸)
- 自定义层 (用标准层组合实现)
```

### Q2: Neural Engine 没被使用
**A**: 检查模型配置：
```swift
let config = MLModelConfiguration()
config.computeUnits = .all  // 确保是 .all 不是 .cpuOnly
```

### Q3: 内存占用过高
**A**: 限制并发推理数量：
```swift
let semaphore = DispatchSemaphore(value: 2)  // 最多 2 个并发
await semaphore.wait()
defer { semaphore.signal() }
let result = try await model.prediction(...)
```

---

## 📚 推荐资源

**Core ML 官方文档**：
- [Core ML Tools](https://apple.github.io/coremltools/)
- [Converting Models](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml)

**深度学习模型**：
- [Pix2Pix 论文](https://arxiv.org/abs/1611.07004)
- [U-Net 论文](https://arxiv.org/abs/1505.04597)

**数据集**：
- DIBCO (Document Image Binarization)
- IAM Handwriting Database
- FUNSD (Form Understanding)

---

## ✅ 检查清单

开始前确认：
- [ ] Python 环境已安装 coremltools
- [ ] 已找到合适的开源模型
- [ ] 理解 U-Net 基本原理
- [ ] ProcessKit 架构已搭建完成

第一个里程碑：
- [ ] 成功转换一个模型为 .mlmodel
- [ ] 模型文件体积 < 50MB
- [ ] Swift 代码能加载模型
- [ ] 能对一张测试图片完成推理

---

**下一步**: 先在 Python 环境验证模型效果，再集成到 iOS！
