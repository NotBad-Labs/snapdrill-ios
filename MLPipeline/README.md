# SnapDrill ML Pipeline

Trains the on-device handwriting segmentation model (paper / printed / handwriting) and exports it to Core ML.
Everything runs locally in an isolated `uv` environment; nothing is uploaded and nothing touches global Python.

```bash
cd MLPipeline
uv venv .venv --python 3.12
uv pip install --python .venv/bin/python torch torchvision coremltools pillow numpy opencv-python-headless

.venv/bin/python synthetic_exam_generator.py --train 1200 --val 120   # data/ + runs/synthetic_samples.png
.venv/bin/python train.py --epochs 12                                  # runs/best.pt + runs/val_preview.png
.venv/bin/python export_coreml.py                                      # exports/HandwritingRemover.mlpackage
.venv/bin/python evaluate_stage0.py /path/to/real/exam/photos          # before/after + latency
```

`data/`, `runs/`, `exports/` and `.venv/` are git-ignored (large and regenerable).

## Model contract (matches `TiledInkSegmentationEngine.swift`)

| Item | Value |
|---|---|
| Input `image` | RGB image 512×512 (`scale = 1/255`; ImageNet normalization is baked into the network) |
| Output `handwriting_prob` | float32 `[1, 3, 512, 512]`: channel 0 paper, 1 printed, 2 handwriting (softmax) |
| Runtime | overlapping 512 px tiles (64 px overlap), feathered fusion, printed-text safety guard, local paper-tone fill |

## Bundling into the app

Drag `exports/HandwritingRemover.mlpackage` into `SnapDrill/Resources/` (Xcode compiles it to
`HandwritingRemover.mlmodelc`). `CoreMLCapableInkRemover` picks it up automatically; without the model the app
keeps using the heuristic fallback. Settings → Developer Diagnostics shows which engine is active in Debug builds.

## Improving quality with real photos

The synthetic set gives pixel-exact masks, but real exam photos are the final judge. Collect Stage 0 samples
(see `Docs/STAGE0_SAMPLES.md`), run `evaluate_stage0.py`, and fine-tune on annotated real crops when needed.
