"""Export the trained model to Core ML (mlprogram, FP16 compute, FP32 probability output)."""
from __future__ import annotations

import time
from pathlib import Path

import coremltools as ct
import numpy as np
import torch
from PIL import Image

from model import MobileNetV3LargeUNet, SoftmaxWrapper


def main():
    runs = Path("runs")
    exports = Path("exports")
    exports.mkdir(exist_ok=True)

    network = MobileNetV3LargeUNet(pretrained=False)
    network.load_state_dict(torch.load(runs / "best.pt", map_location="cpu"))
    wrapper = SoftmaxWrapper(network).eval()

    example = torch.rand(1, 3, 512, 512)
    traced = torch.jit.trace(wrapper, example)

    mlmodel = ct.convert(
        traced,
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.iOS18,
        inputs=[
            ct.ImageType(
                name="image",
                shape=(1, 3, 512, 512),
                scale=1.0 / 255.0,
                color_layout=ct.colorlayout.RGB,
            )
        ],
        outputs=[ct.TensorType(name="handwriting_prob", dtype=np.float32)],
    )
    mlmodel.short_description = "SnapDrill handwriting segmentation (paper / printed / handwriting)"
    package = exports / "HandwritingRemover.mlpackage"
    mlmodel.save(str(package))

    size_mb = sum(f.stat().st_size for f in package.rglob("*") if f.is_file()) / 1e6
    print(f"saved {package} ({size_mb:.1f} MB)")

    # Native macOS prediction + parity check against PyTorch
    sample_path = sorted(Path("data/val/images").glob("*.jpg"))[0]
    image = Image.open(sample_path).convert("RGB").resize((512, 512))
    loaded = ct.models.MLModel(str(package))
    prediction = np.array(loaded.predict({"image": image})["handwriting_prob"])
    tensor = torch.from_numpy(np.array(image)).permute(2, 0, 1).float().unsqueeze(0) / 255.0
    with torch.no_grad():
        reference = wrapper(tensor).numpy()
    diff = float(np.abs(prediction.reshape(reference.shape) - reference).max())
    print(f"output shape {prediction.shape}, max |coreml - torch| = {diff:.4f}")

    timings = []
    for _ in range(12):
        started = time.perf_counter()
        loaded.predict({"image": image})
        timings.append((time.perf_counter() - started) * 1000)
    timings = sorted(timings[2:])
    print(f"macOS Core ML per-tile latency: P50={timings[len(timings) // 2]:.0f} ms, max={timings[-1]:.0f} ms")


if __name__ == "__main__":
    main()
