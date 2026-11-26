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
            final_start = length - tile
            if not starts or starts[-1] != final_start:
                starts.append(final_start)
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


def estimate_pad_paper_rgb(image_rgb: np.ndarray) -> tuple[int, int, int]:
    """Matches Swift TiledCoreMLSegmentationRunner.estimatePadPaperRGB (85th-percentile luma sample)."""
    height, width = image_rgb.shape[:2]
    step_x = max(1, width // 48)
    step_y = max(1, height // 48)
    sampled = image_rgb[::step_y, ::step_x].reshape(-1, 3)
    if len(sampled) == 0:
        return (245, 243, 238)
    luma = (299 * sampled[:, 0].astype(np.int32) + 587 * sampled[:, 1].astype(np.int32) + 114 * sampled[:, 2].astype(np.int32)) // 1000
    order = np.argsort(luma, kind="mergesort")
    pick = sampled[order[min(len(order) - 1, int((len(order) - 1) * 0.85))]]
    return (int(pick[0]), int(pick[1]), int(pick[2]))


def segment_image(predict_tile: Callable[[np.ndarray], np.ndarray], image_rgb: np.ndarray):
    """predict_tile: (512,512,3) uint8 RGB -> (3,512,512) float probabilities.

    Returns (printed_prob, handwriting_prob) at full image resolution.
    """
    height, width = image_rgb.shape[:2]
    xs, ys = axis_starts(width), axis_starts(height)
    tile_w, tile_h = min(TILE, width), min(TILE, height)
    pad_x = (TILE - tile_w) // 2
    pad_y = (TILE - tile_h) // 2
    pad_rgb = estimate_pad_paper_rgb(image_rgb)

    printed = np.zeros((height, width), dtype=np.float32)
    handwriting = np.zeros_like(printed)
    weights = np.zeros_like(printed)

    for yi, y in enumerate(ys):
        for xi, x in enumerate(xs):
            patch = np.full((TILE, TILE, 3), pad_rgb, dtype=np.uint8)
            patch[pad_y : pad_y + tile_h, pad_x : pad_x + tile_w] = image_rgb[y : y + tile_h, x : x + tile_w]
            probs = predict_tile(patch)
            wx = feather(tile_w, OVERLAP, xi == 0, xi == len(xs) - 1)
            wy = feather(tile_h, OVERLAP, yi == 0, yi == len(ys) - 1)
            w = wy[:, None] * wx[None, :]
            printed[y : y + tile_h, x : x + tile_w] += w * probs[1, pad_y : pad_y + tile_h, pad_x : pad_x + tile_w]
            handwriting[y : y + tile_h, x : x + tile_w] += w * probs[2, pad_y : pad_y + tile_h, pad_x : pad_x + tile_w]
            weights[y : y + tile_h, x : x + tile_w] += w

    weights = np.maximum(weights, 1e-6)
    return printed / weights, handwriting / weights


def composite(image_rgb: np.ndarray, printed: np.ndarray, handwriting: np.ndarray, threshold: float = 0.55):
    """Erase handwriting while preserving printed pixels. Mirrors Swift SegmentationMaskCompositor exactly."""
    erase = (handwriting >= threshold) & (handwriting > printed * 1.15)
    strong = erase & (handwriting >= 0.70)
    grown = cv2.dilate(strong.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool)
    erase = erase | (grown & (printed < 0.35))
    if not erase.any():
        return image_rgb.copy(), erase

    height, width = erase.shape
    cell = 32
    cols, rows = max(1, -(-width // cell)), max(1, -(-height // cell))
    luma = (
        299 * image_rgb[..., 0].astype(np.int32)
        + 587 * image_rgb[..., 1].astype(np.int32)
        + 114 * image_rgb[..., 2].astype(np.int32)
    ) // 1000
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
            order = np.argsort(lum, kind="mergesort")
            pick = values[order[min(len(order) - 1, int((len(order) - 1) * 0.85))]]
            grid[gy, gx] = pick
    fallback = np.nanmean(grid.reshape(-1, 3), axis=0) if np.isfinite(grid).any() else np.array([245.0, 243.0, 238.0], dtype=np.float32)
    grid = np.where(np.isnan(grid), fallback, grid).astype(np.float32)

    # Exact cell-center bilinear interpolation matching Swift SegmentationMaskCompositor.paperColor(x:y:)
    fx = np.clip((np.arange(width, dtype=np.float32) + 0.5) / cell - 0.5, 0.0, float(cols - 1))
    fy = np.clip((np.arange(height, dtype=np.float32) + 0.5) / cell - 0.5, 0.0, float(rows - 1))
    x0 = fx.astype(np.int32)
    y0 = fy.astype(np.int32)
    x1 = np.minimum(cols - 1, x0 + 1)
    y1 = np.minimum(rows - 1, y0 + 1)
    tx = (fx - x0)[None, :, None]
    ty = (fy - y0)[:, None, None]

    p00 = grid[y0[:, None], x0[None, :]]
    p10 = grid[y0[:, None], x1[None, :]]
    p01 = grid[y1[:, None], x0[None, :]]
    p11 = grid[y1[:, None], x1[None, :]]
    paper = (p00 * (1.0 - tx) + p10 * tx) * (1.0 - ty) + (p01 * (1.0 - tx) + p11 * tx) * ty

    out = image_rgb.copy()
    # Match Swift Float.rounded() (.toNearestOrAwayFromZero) on non-negative [0, 255] paper RGB values.
    out[erase] = np.clip(np.floor(paper[erase] + 0.5), 0, 255).astype(np.uint8)
    return out, erase
