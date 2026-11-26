"""Lightweight 3-class (paper / printed / handwriting) segmentation network.

Encoder: torchvision MobileNetV3-Large (BSD-3-Clause). Decoder: small UNet with skip connections.
The network takes RGB in [0, 1] and normalizes internally, so the exported Core ML model can use a plain
`scale = 1/255` image input.
"""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.models import MobileNet_V3_Large_Weights, mobilenet_v3_large


class ConvBNReLU(nn.Sequential):
    def __init__(self, in_ch: int, out_ch: int, kernel: int = 3, dilation: int = 1):
        padding = dilation * (kernel - 1) // 2
        super().__init__(
            nn.Conv2d(in_ch, out_ch, kernel, padding=padding, dilation=dilation, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
        )


class UpBlock(nn.Module):
    def __init__(self, in_ch: int, skip_ch: int, out_ch: int):
        super().__init__()
        self.fuse = nn.Sequential(ConvBNReLU(in_ch + skip_ch, out_ch), ConvBNReLU(out_ch, out_ch))

    def forward(self, x: torch.Tensor, skip: torch.Tensor) -> torch.Tensor:
        x = F.interpolate(x, size=skip.shape[-2:], mode="bilinear", align_corners=False)
        return self.fuse(torch.cat([x, skip], dim=1))


class MobileNetV3LargeUNet(nn.Module):
    MEAN = (0.485, 0.456, 0.406)
    STD = (0.229, 0.224, 0.225)

    def __init__(self, num_classes: int = 3, pretrained: bool = True):
        super().__init__()
        weights = MobileNet_V3_Large_Weights.DEFAULT if pretrained else None
        try:
            features = mobilenet_v3_large(weights=weights).features
        except Exception as error:  # offline: fall back to random init
            print(f"[model] could not load pretrained weights ({error}); using random init")
            features = mobilenet_v3_large(weights=None).features

        # Stage taps: stride 2 (16ch), 4 (24ch), 8 (40ch), 16 (112ch)
        self.stage_s2 = features[0:2]
        self.stage_s4 = features[2:4]
        self.stage_s8 = features[4:7]
        self.stage_s16 = features[7:13]

        self.context = nn.Sequential(ConvBNReLU(112, 128), ConvBNReLU(128, 128, dilation=2))
        self.up8 = UpBlock(128, 40, 72)
        self.up4 = UpBlock(72, 24, 48)
        self.up2 = UpBlock(48, 16, 32)
        self.refine = nn.Sequential(ConvBNReLU(32 + 3, 24), ConvBNReLU(24, 24))
        self.head = nn.Conv2d(24, num_classes, kernel_size=1)

        self.register_buffer("mean", torch.tensor(self.MEAN).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor(self.STD).view(1, 3, 1, 1))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        normalized = (x - self.mean) / self.std
        s2 = self.stage_s2(normalized)
        s4 = self.stage_s4(s2)
        s8 = self.stage_s8(s4)
        s16 = self.stage_s16(s8)

        y = self.context(s16)
        y = self.up8(y, s8)
        y = self.up4(y, s4)
        y = self.up2(y, s2)
        y = F.interpolate(y, size=x.shape[-2:], mode="bilinear", align_corners=False)
        y = self.refine(torch.cat([y, x], dim=1))
        return self.head(y)


class SoftmaxWrapper(nn.Module):
    """Export wrapper: logits -> per-class probabilities [B, 3, H, W]."""

    def __init__(self, network: nn.Module):
        super().__init__()
        self.network = network

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return torch.softmax(self.network(x), dim=1)


if __name__ == "__main__":
    net = MobileNetV3LargeUNet(pretrained=False)
    params = sum(p.numel() for p in net.parameters())
    out = net(torch.rand(1, 3, 512, 512))
    print(f"params={params / 1e6:.2f}M output={tuple(out.shape)}")
