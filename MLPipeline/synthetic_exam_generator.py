"""Synthetic exam-crop generator for 3-class handwriting segmentation.

Classes: 0 = paper, 1 = printed text/diagrams, 2 = handwriting (any pen, including black).
Printed and handwriting layers are rendered separately, so the masks are pixel-exact.
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 512

FONT_CANDIDATES_LATIN = [
    "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/System/Library/Fonts/Menlo.ttc",
]
FONT_CANDIDATES_ZH = [
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/System/Library/Fonts/STHeiti Light.ttc",
    "/System/Library/Fonts/Supplemental/Songti.ttc",
]
FONT_CANDIDATES_JA = [
    "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/System/Library/Fonts/PingFang.ttc",
]
FONT_CANDIDATES_KO = [
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",
    "/System/Library/Fonts/PingFang.ttc",
]
FONT_CANDIDATES_HAND = [
    "/System/Library/Fonts/Supplemental/Bradley Hand Bold.ttf",
    "/System/Library/Fonts/Supplemental/Chalkduster.ttf",
    "/System/Library/Fonts/Supplemental/Noteworthy.ttc",
    "/System/Library/Fonts/Supplemental/Marker Felt.ttc",
    "/System/Library/Fonts/Supplemental/SnellRoundhand.ttc",
]
FONT_CANDIDATES_HAND_CJK = [
    "/System/Library/Fonts/Supplemental/Kaiti.ttc",
    "/System/Library/Fonts/Supplemental/Xingkai.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/STHeiti Light.ttc",
]

QUESTIONS_ZH = [
    ("zh", "已知函数 f(x) = x² - 2ax + 3，求其在区间 [0, 2] 上的最小值。"),
    ("zh", "如图，在△ABC中，AB = AC，D 为 BC 中点，求证：AD ⊥ BC。"),
    ("zh", "解方程组：2x + y = 7，x - y = 2，并检验所得的解。"),
    ("zh", "下列说法正确的是：A. 质量大的物体惯性大  B. 速度大的物体惯性大"),
    ("zh", "用化学方程式表示铁在氧气中燃烧的反应，并注明反应条件。"),
    ("zh", "閱讀下列短文，說明作者為何反覆強調「時間是最好的尺」。"),
    ("zh", "若等差數列 {aₙ} 滿足 a₂ + a₆ = 14，則前 7 項和 S₇ 為多少？"),
]
QUESTIONS_EN = [
    ("en", "14. Find the minimum value of f(x) = x^2 - 2ax + 3 on the interval [0, 2]."),
    ("en", "Q5. Choose the best option: Hardly had she arrived (   ) the train left."),
    ("en", "8. A block of mass m rests on a rough 30 degree incline; find the friction force."),
    ("en", "Solve the system: x + y = 7 and 2x - y = 2, then verify your answer."),
    ("en", "Which of the following is a prime number? A. 21  B. 27  C. 29  D. 33"),
    ("en", "Simplify (3x + 2)(x - 5) - 2x(x + 1) and factor the result completely."),
]
QUESTIONS_JA = [
    ("ja", "二次関数 y = x² - 4ax + 3a² + 2 (0 ≤ x ≤ 2) の最小値を求めよ。"),
    ("ja", "次の文の（　）に入る最も適切な語を選びなさい。"),
    ("ja", "三角形ABCにおいて、AB = AC のとき、角B = 角C を証明せよ。"),
]
QUESTIONS_KO = [
    ("ko", "이차함수 y = x² - 4ax + 3a² + 2 의 최솟값을 구하시오."),
    ("ko", "다음 중 옳은 것을 고르시오. ① 2x+1  ② 3x-2  ③ x²+4"),
    ("ko", "삼각형 ABC에서 AB = AC 일 때, 각 B = 각 C 임을 증명하시오."),
]
ALL_QUESTIONS = QUESTIONS_ZH * 2 + QUESTIONS_EN * 2 + QUESTIONS_JA * 2 + QUESTIONS_KO * 2

HANDWRITTEN_SNIPPETS = [
    "x = 4, y = 3", "a < 0 时 g(a) = 3", "= 7 - 4a", "答: B", "(x-1)(x-3)", "f(a) = 3 - a²",
    "Ans: C", "2a < 0", "∴ x = -2", "forgot case!", "把 N = mg cosθ", "≈ 12.5", "①②③", "= 0",
    "sin θ = 1/2", "B", "x² = 9", "c = 5", "so a ≥ √2", "ok", "?", "解：原式 = 2x - 1",
]


def pick_font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    shuffled = list(candidates)
    random.shuffle(shuffled)
    for path in shuffled:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def font_pool_for_script(script: str) -> list[str]:
    if script == "zh":
        return FONT_CANDIDATES_ZH
    if script == "ja":
        return FONT_CANDIDATES_JA
    if script == "ko":
        return FONT_CANDIDATES_KO
    return FONT_CANDIDATES_LATIN


def paper_background(rng: random.Random) -> Image.Image:
    base = np.array(
        [rng.randint(232, 252), rng.randint(230, 250), rng.randint(218, 248)], dtype=np.float32
    )
    canvas = np.tile(base, (SIZE, SIZE, 1))
    # Directional shadow gradient
    angle = rng.uniform(0, 2 * math.pi)
    xs, ys = np.meshgrid(np.linspace(-1, 1, SIZE), np.linspace(-1, 1, SIZE))
    gradient = (xs * math.cos(angle) + ys * math.sin(angle)) * rng.uniform(0, 0.16)
    canvas *= (1.0 - gradient[..., None] - rng.uniform(0, 0.06))
    # Occasional soft crease / fold shadow band
    if rng.random() < 0.35:
        cx = rng.uniform(-0.6, 0.6)
        crease = np.exp(-((xs - cx) ** 2) / rng.uniform(0.008, 0.04)) * rng.uniform(0.04, 0.12)
        canvas *= (1.0 - crease[..., None])
    # Paper grain
    canvas += np.random.default_rng(rng.randint(0, 10**6)).normal(0, rng.uniform(0.8, 3.0), canvas.shape)
    return Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8), "RGB")


def draw_printed(rng: random.Random) -> Image.Image:
    """Returns an L-mode layer: 255 where printed ink exists."""
    layer = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(layer)
    y = rng.randint(14, 40)
    questions = rng.sample(ALL_QUESTIONS, k=rng.randint(2, 4))
    for script, text in questions:
        font = pick_font(font_pool_for_script(script), rng.randint(17, 24))
        x = rng.randint(14, 36)
        # naive wrap
        line = ""
        for ch in text:
            probe = line + ch
            if draw.textlength(probe, font=font) > SIZE - x - 18:
                draw.text((x, y), line, fill=255, font=font)
                y += int(font.size * 1.35)
                line = ch
            else:
                line = probe
        if line:
            draw.text((x, y), line, fill=255, font=font)
            y += int(font.size * 1.35)
        y += rng.randint(14, 54)
        if y > SIZE - 60:
            break

    # printed diagrams / tables / rules
    for _ in range(rng.randint(0, 3)):
        kind = rng.choice(["triangle", "axes", "circle", "box", "table", "underline"])
        x0, y0 = rng.randint(200, 380), rng.randint(60, 360)
        w = rng.randint(50, 115)
        if kind == "triangle":
            draw.polygon([(x0, y0 + w), (x0 + w, y0 + w), (x0 + w // 2, y0)], outline=255, width=2)
        elif kind == "axes":
            draw.line([(x0, y0 + w), (x0 + w, y0 + w)], fill=255, width=2)
            draw.line([(x0 + 10, y0 + w + 8), (x0 + 10, y0 - 6)], fill=255, width=2)
            draw.arc([x0 + 10, y0, x0 + w, y0 + w * 2], 190, 340, fill=255, width=2)
        elif kind == "circle":
            draw.ellipse([x0, y0, x0 + w, y0 + w], outline=255, width=2)
        elif kind == "box":
            draw.rectangle([x0, y0, x0 + w, y0 + w // 2], outline=255, width=2)
        elif kind == "table":
            rows_n, cols_n = 2, 3
            ch, cw = 24, w // cols_n
            for r in range(rows_n + 1):
                draw.line([(x0, y0 + r * ch), (x0 + cols_n * cw, y0 + r * ch)], fill=255, width=1)
            for c in range(cols_n + 1):
                draw.line([(x0 + c * cw, y0), (x0 + c * cw, y0 + rows_n * ch)], fill=255, width=1)
        else:
            draw.line([(x0 - 100, y0), (x0 + w, y0)], fill=255, width=1)
    return layer


def bezier_stroke(draw: ImageDraw.ImageDraw, points, width: int, fill=255) -> None:
    steps = 18
    prev = None
    for i in range(steps + 1):
        t = i / steps
        # quadratic through 3 points
        (x0, y0), (x1, y1), (x2, y2) = points
        x = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * x1 + t**2 * x2
        y = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * y1 + t**2 * y2
        if prev is not None:
            draw.line([prev, (x, y)], fill=fill, width=width)
        prev = (x, y)


def draw_handwriting(rng: random.Random, printed: Image.Image):
    """Returns (list of (pen_color, L-layer)), combined L-layer mask of all handwriting."""
    pens = {
        "black_gel": (rng.randint(8, 30), rng.randint(8, 30), rng.randint(8, 36)),
        "pencil": (rng.randint(70, 105),) * 3,
        "blue": (rng.randint(20, 50), rng.randint(60, 100), rng.randint(170, 225)),
        "red": (rng.randint(190, 225), rng.randint(25, 55), rng.randint(25, 55)),
    }
    weights = [0.50, 0.22, 0.16, 0.12]
    layers = []
    combined = Image.new("L", (SIZE, SIZE), 0)
    pen_pool = list(pens.keys())
    chosen = rng.choices(pen_pool, weights=weights, k=rng.randint(1, 3))
    for pen_name in chosen:
        layer = Image.new("L", (SIZE, SIZE), 0)
        draw = ImageDraw.Draw(layer)
        width = {"black_gel": rng.choice([2, 2, 3]), "pencil": rng.choice([2, 3]), "blue": 2, "red": rng.choice([2, 3, 4])}[pen_name]
        for _ in range(rng.randint(3, 8)):
            kind = rng.choice(["text", "text", "text", "underline", "circle", "check", "cross", "scratch"])
            x = rng.randint(20, SIZE - 160)
            y = rng.randint(20, SIZE - 60)
            if kind == "text":
                snippet = rng.choice(HANDWRITTEN_SNIPPETS)
                needs_cjk = any(ord(ch) > 0x2000 for ch in snippet)
                pool = FONT_CANDIDATES_HAND_CJK if needs_cjk else FONT_CANDIDATES_HAND
                font = pick_font(pool, rng.randint(20, 32))
                draw.text((x, y), snippet, fill=255, font=font)
            elif kind == "underline":
                bezier_stroke(draw, [(x, y), (x + 60, y + rng.randint(-6, 6)), (x + rng.randint(100, 180), y + rng.randint(-4, 8))], width)
            elif kind == "circle":
                r = rng.randint(14, 30)
                draw.ellipse([x, y, x + 2 * r, y + int(1.4 * r)], outline=255, width=width)
            elif kind == "check":
                bezier_stroke(draw, [(x, y + 12), (x + 8, y + 24), (x + 30, y - 6)], width + 1)
            elif kind == "cross":
                draw.line([(x, y), (x + 26, y + 26)], fill=255, width=width + 1)
                draw.line([(x + 26, y), (x, y + 26)], fill=255, width=width + 1)
            else:
                for k in range(rng.randint(3, 6)):
                    draw.line([(x, y + k * 5), (x + rng.randint(60, 120), y + k * 5 + rng.randint(-4, 4))], fill=255, width=width)
        layer = layer.filter(ImageFilter.GaussianBlur(rng.uniform(0.2, 0.6)))
        layers.append((pens[pen_name], pen_name, layer))
        combined = Image.fromarray(np.maximum(np.array(combined), np.array(layer)))
    return layers, combined


def multiply_ink(canvas: np.ndarray, layer: Image.Image, color: tuple[int, int, int], opacity: float, grain: bool = False):
    alpha = np.array(layer, dtype=np.float32) / 255.0 * opacity
    if grain:
        alpha *= np.clip(np.random.default_rng().normal(0.85, 0.25, alpha.shape), 0.25, 1.0)
    ink = np.array(color, dtype=np.float32) / 255.0
    for c in range(3):
        canvas[..., c] = canvas[..., c] * (1 - alpha) + canvas[..., c] * ink[c] * alpha


def generate_sample(seed: int):
    rng = random.Random(seed)
    np.random.seed(seed)
    paper = paper_background(rng)
    canvas = np.array(paper, dtype=np.float32) / 255.0

    printed = draw_printed(rng).filter(ImageFilter.GaussianBlur(rng.uniform(0.0, 0.5)))
    multiply_ink(canvas, printed, (rng.randint(8, 34),) * 3, rng.uniform(0.88, 1.0))

    layers, handwriting_mask = draw_handwriting(rng, printed)
    for color, pen_name, layer in layers:
        multiply_ink(canvas, layer, color, rng.uniform(0.78, 1.0) if pen_name != "pencil" else rng.uniform(0.55, 0.85), grain=pen_name == "pencil")

    image = Image.fromarray(np.clip(canvas * 255, 0, 255).astype(np.uint8), "RGB")
    if rng.random() < 0.5:
        image = image.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 0.9)))

    printed_arr = np.array(printed) > 90
    hand_arr = np.array(handwriting_mask) > 70
    mask = np.zeros((SIZE, SIZE), dtype=np.uint8)
    mask[printed_arr] = 1
    mask[hand_arr] = 2  # handwriting wins on overlap so the erase target stays learnable
    return image, Image.fromarray(mask, "L")


def generate_dataset(root: Path, split: str, count: int, start_seed: int) -> None:
    img_dir = root / split / "images"
    mask_dir = root / split / "masks"
    img_dir.mkdir(parents=True, exist_ok=True)
    mask_dir.mkdir(parents=True, exist_ok=True)
    for i in range(count):
        image, mask = generate_sample(start_seed + i)
        quality = random.Random(start_seed + i).randint(70, 95)
        image.save(img_dir / f"{i:05d}.jpg", quality=quality)
        mask.save(mask_dir / f"{i:05d}.png")


def save_preview(root: Path, runs: Path, n: int = 4) -> None:
    runs.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGB", (SIZE * 2, SIZE * n), "white")
    palette = {0: (255, 255, 255), 1: (40, 90, 200), 2: (220, 60, 60)}
    for row in range(n):
        image = Image.open(root / "train" / "images" / f"{row:05d}.jpg").convert("RGB")
        mask = np.array(Image.open(root / "train" / "masks" / f"{row:05d}.png"))
        color = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)
        for cls, rgb in palette.items():
            color[mask == cls] = rgb
        sheet.paste(image, (0, row * SIZE))
        sheet.paste(Image.fromarray(color), (SIZE, row * SIZE))
    sheet.resize((SIZE, SIZE * n // 2)).save(runs / "synthetic_samples.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="data")
    parser.add_argument("--train", type=int, default=1200)
    parser.add_argument("--val", type=int, default=120)
    args = parser.parse_args()
    root = Path(args.out)
    generate_dataset(root, "train", args.train, start_seed=1000)
    generate_dataset(root, "val", args.val, start_seed=900000)
    save_preview(root, Path("runs"))
    print(f"generated {args.train} train / {args.val} val samples in {root}")
