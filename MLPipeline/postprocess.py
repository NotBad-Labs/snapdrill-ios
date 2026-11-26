"""NumPy post-processing shared by training previews and offline evaluation.

Mirrors the iOS runtime: overlapping 512 px tiles, feathered fusion, printed-text safety guard,
1 px fringe dilation, and local bilinear paper-tone fill.
"""
from __future__ import annotations

from typing import Callable

import cv2
import numpy as np

TILE = 512
OVERLAP = 64


def axis_starts(length: int, tile: int = TILE, overlap: int = OVERLAP) -> list[int]:
    if length <= tile:
        return [0]
    stride = max(1, tile - overlap)
    starts, pos = [], 0
    while True:
        if pos + tile >= length:
            starts.append(length - tile)
            break
        starts.append(pos)
        pos += stride
    return starts


def feather(size: int, overlap: int, leading_edge: bool, trailing_edge: bool) -> np.ndarray:
    w = np.ones(size, dtype=np.float32)
    if overlap <= 0:
        return w
    idx = np.arange(size, dtype=np.float32)
    if not leading_edge:
        t = np.clip(idx / overlap, 0, 1)
        w = np.minimum(w, 0.05 + 0.95 * (0.5 - 0.5 * np.cos(np.pi * t)))
    if not trailing_edge:
        t = np.clip((size - 1 - idx) / overlap, 0, 1)
        w = np.minimum(w, 0.05 + 0.95 * (0.5 - 0.5 * np.cos(np.pi * t)))
    return w


def segment_image(predict_tile: Callable[[np.ndarray], np.ndarray], image_rgb: np.ndarray):
    """predict_tile: (512,512,3) uint8 RGB -> (3,512,512) float probabilities.

    Returns (printed_prob, handwriting_prob) at full image resolution.
    """
    height, width = image_rgb.shape[:2]
    xs, ys = axis_starts(width), axis_starts(height)
    tile_w, tile_h = min(TILE, width), min(TILE, height)
    printed = np.zeros((height, width), dtype=np.float32)
    handwriting = np.zeros_like(printed)
    weights = np.zeros_like(printed)

    for yi, y in enumerate(ys):
        for xi, x in enumerate(xs):
            patch = np.full((TILE, TILE, 3), (245, 243, 238), dtype=np.uint8)
            patch[:tile_h, :tile_w] = image_rgb[y : y + tile_h, x : x + tile_w]
            probs = predict_tile(patch)
            wx = feather(tile_w, OVERLAP, xi == 0, xi == len(xs) - 1)
            wy = feather(tile_h, OVERLAP, yi == 0, yi == len(ys) - 1)
            w = wy[:, None] * wx[None, :]
            printed[y : y + tile_h, x : x + tile_w] += w * probs[1, :tile_h, :tile_w]
            handwriting[y : y + tile_h, x : x + tile_w] += w * probs[2, :tile_h, :tile_w]
            weights[y : y + tile_h, x : x + tile_w] += w

    weights = np.maximum(weights, 1e-6)
    return printed / weights, handwriting / weights


def composite(image_rgb: np.ndarray, printed: np.ndarray, handwriting: np.ndarray, threshold: float = 0.55):
    """Erase handwriting while preserving printed pixels. Returns (cleaned_rgb, erase_mask)."""
    erase = (handwriting >= threshold) & (handwriting > printed * 1.15)
    strong = erase & (handwriting >= 0.70)
    grown = cv2.dilate(strong.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool)
    erase = erase | (grown & (printed < 0.35))
    if not erase.any():
        return image_rgb.copy(), erase

    height, width = erase.shape
    cell = 32
    cols, rows = max(1, -(-width // cell)), max(1, -(-height // cell))
    luma = (0.299 * image_rgb[..., 0] + 0.587 * image_rgb[..., 1] + 0.114 * image_rgb[..., 2])
    valid = (~erase) & (printed < 0.30) & (handwriting < 0.30)

    grid = np.full((rows, cols, 3), np.nan, dtype=np.float32)
    for gy in range(rows):
        for gx in range(cols):
            sl = (slice(gy * cell, min(height, (gy + 1) * cell)), slice(gx * cell, min(width, (gx + 1) * cell)))
            mask = valid[sl]
            if mask.sum() < 4:
                continue
            values = image_rgb[sl][mask]
            lum = luma[sl][mask]
            pick = values[np.argsort(lum)[int((len(lum) - 1) * 0.85)]]
            grid[gy, gx] = pick
    fallback = np.nanmean(grid.reshape(-1, 3), axis=0) if np.isfinite(grid).any() else np.array([245, 243, 238])
    grid = np.where(np.isnan(grid), fallback, grid).astype(np.float32)

    paper = cv2.resize(grid, (width, height), interpolation=cv2.INTER_LINEAR)
    out = image_rgb.copy()
    out[erase] = np.clip(paper[erase], 0, 255).astype(np.uint8)
    return out, erase
