"""Run the exported Core ML model (with the iOS tiling + paper-fill logic) on a folder of real exam photos.

    .venv/bin/python evaluate_stage0.py /path/to/photos [--masks-dir /path/to/masks]

Notes per Docs/STAGE0_CHARTER.md:
- Mac timings are a fast local smoke signal only; official P50/P95 latency and blind redoable-rate
  must still be measured on the target iPhone 17 hardware over >= 80 real exam samples.
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import coremltools as ct
import numpy as np
from PIL import Image, ImageOps

from postprocess import composite, segment_image


def main():
    parser = argparse.ArgumentParser(description="Evaluate exported Core ML model with iOS-parity tiling.")
    parser.add_argument("source", help="Directory containing exam images (.jpg/.jpeg/.png)")
    parser.add_argument("--masks-dir", default=None, help="Optional ground-truth mask directory (.png with 0/1/2 classes)")
    parser.add_argument("--model", default="exports/HandwritingRemover.mlpackage")
    parser.add_argument("--out", default="runs/stage0_eval")
    args = parser.parse_args()

    source = Path(args.source)
    masks_dir = Path(args.masks_dir) if args.masks_dir else None
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    model = ct.models.MLModel(args.model)

    def predict_tile(patch: np.ndarray) -> np.ndarray:
        result = model.predict({"image": Image.fromarray(patch)})["handwriting_prob"]
        return np.array(result).reshape(3, 512, 512)

    timings: list[float] = []
    hw_inter = hw_union = 0
    printed_kept = printed_total = 0
    dark_tp = dark_fp = dark_fn = 0
    per_image = []

    image_paths = sorted(p for p in source.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png"})
    for path in image_paths:
        pil_img = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
        image = np.array(pil_img)
        started = time.perf_counter()
        printed, handwriting = segment_image(predict_tile, image)
        cleaned, erase = composite(image, printed, handwriting)
        elapsed = (time.perf_counter() - started) * 1000
        timings.append(elapsed)
        Image.fromarray(np.concatenate([image, cleaned], axis=1)).save(out_dir / f"{path.stem}_before_after.jpg", quality=90)

        entry: dict[str, object] = {
            "file": path.name,
            "width": int(image.shape[1]),
            "height": int(image.shape[0]),
            "elapsed_ms": round(elapsed, 2),
            "erased_ratio": round(float(erase.mean()), 5),
        }

        if masks_dir is not None:
            mask_path = masks_dir / f"{path.stem}.png"
            if mask_path.exists():
                gt = np.array(Image.open(mask_path))
                if gt.shape == erase.shape:
                    gt_hw = gt == 2
                    gt_pr = gt == 1
                    hw_inter += int((erase & gt_hw).sum())
                    hw_union += int((erase | gt_hw).sum())
                    printed_kept += int((~erase & gt_pr).sum())
                    printed_total += int(gt_pr.sum())
                    luma = (0.299 * image[..., 0] + 0.587 * image[..., 1] + 0.114 * image[..., 2]) / 255.0
                    dark = luma < 0.35
                    dark_tp += int((erase & gt_hw & dark).sum())
                    dark_fp += int((erase & ~gt_hw & dark).sum())
                    dark_fn += int((~erase & gt_hw & dark).sum())
                    entry["postprocessed_hw_iou"] = round(float((erase & gt_hw).sum() / max(1, (erase | gt_hw).sum())), 4)
                    entry["postprocessed_printed_kept"] = round(float((~erase & gt_pr).sum() / max(1, gt_pr.sum())), 4)

        per_image.append(entry)
        print(f"{path.name}: {elapsed:.0f} ms, erased {erase.mean() * 100:.2f}% of pixels")

    summary: dict[str, object] = {
        "image_count": len(timings),
        "images": per_image,
    }
    if timings:
        arr = np.array(timings, dtype=np.float64)
        p50 = float(np.percentile(arr, 50))
        p95 = float(np.percentile(arr, 95))
        summary["mac_p50_ms"] = round(p50, 2)
        summary["mac_p95_ms"] = round(p95, 2)
        print(f"Mac local P50={p50:.0f} ms  P95={p95:.0f} ms over {len(timings)} images")

    if printed_total > 0 or hw_union > 0:
        pp_hw_iou = hw_inter / max(1, hw_union)
        pp_printed_kept = printed_kept / max(1, printed_total)
        pp_dark_f1 = 2 * dark_tp / max(1, 2 * dark_tp + dark_fp + dark_fn)
        summary["postprocessed_hw_iou"] = round(pp_hw_iou, 4)
        summary["postprocessed_printed_kept"] = round(pp_printed_kept, 4)
        summary["postprocessed_dark_hw_f1"] = round(pp_dark_f1, 4)
        print(
            f"Runtime-mask metrics: hw_iou={pp_hw_iou:.3f} printed_kept={pp_printed_kept:.3f} "
            f"dark_hw_f1={pp_dark_f1:.3f}"
        )

    (out_dir / "stage0_metrics.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
