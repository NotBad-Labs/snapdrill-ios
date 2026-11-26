"""Run the exported Core ML model (with the iOS tiling + paper-fill logic) on a folder of real exam photos.

    .venv/bin/python evaluate_stage0.py /path/to/photos
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

import coremltools as ct
import numpy as np
from PIL import Image

from postprocess import composite, segment_image


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    source = Path(sys.argv[1])
    out_dir = Path("runs/stage0_eval")
    out_dir.mkdir(parents=True, exist_ok=True)
    model = ct.models.MLModel("exports/HandwritingRemover.mlpackage")

    def predict_tile(patch: np.ndarray) -> np.ndarray:
        result = model.predict({"image": Image.fromarray(patch)})["handwriting_prob"]
        return np.array(result).reshape(3, 512, 512)

    timings = []
    for path in sorted(p for p in source.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png"}):
        image = np.array(Image.open(path).convert("RGB"))
        started = time.perf_counter()
        printed, handwriting = segment_image(predict_tile, image)
        cleaned, erase = composite(image, printed, handwriting)
        elapsed = (time.perf_counter() - started) * 1000
        timings.append(elapsed)
        Image.fromarray(np.concatenate([image, cleaned], axis=1)).save(out_dir / f"{path.stem}_before_after.jpg", quality=90)
        print(f"{path.name}: {elapsed:.0f} ms, erased {erase.mean() * 100:.2f}% of pixels")

    if timings:
        timings.sort()
        print(f"P50={timings[len(timings) // 2]:.0f} ms  P95={timings[int(len(timings) * 0.95) - 1]:.0f} ms over {len(timings)} images")


if __name__ == "__main__":
    main()
