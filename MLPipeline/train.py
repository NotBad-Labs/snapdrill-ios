"""Train the handwriting segmentation model on Apple Silicon (MPS)."""
from __future__ import annotations

import argparse
import random
import time
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from torch.utils.data import DataLoader, Dataset

from model import MobileNetV3LargeUNet
from postprocess import composite

CLASS_WEIGHTS = [0.3, 2.2, 2.5]
PALETTE = np.array([[255, 255, 255], [40, 90, 200], [220, 60, 60]], dtype=np.uint8)


class ExamDataset(Dataset):
    def __init__(self, root: Path, split: str, crop: int | None, augment: bool):
        self.images = sorted((root / split / "images").glob("*.jpg"))
        self.mask_dir = root / split / "masks"
        self.crop = crop
        self.augment = augment

    def __len__(self) -> int:
        return len(self.images)

    def __getitem__(self, index: int):
        path = self.images[index]
        image = np.array(Image.open(path).convert("RGB"))
        mask = np.array(Image.open(self.mask_dir / f"{path.stem}.png"))
        if self.crop:
            h, w = mask.shape
            y = random.randint(0, h - self.crop)
            x = random.randint(0, w - self.crop)
            image = image[y : y + self.crop, x : x + self.crop]
            mask = mask[y : y + self.crop, x : x + self.crop]
        if self.augment:
            image = image.astype(np.float32)
            image = image * random.uniform(0.85, 1.12) + random.uniform(-12, 12)
            image = np.clip(image, 0, 255).astype(np.uint8)
        tensor = torch.from_numpy(image).permute(2, 0, 1).float() / 255.0
        return tensor, torch.from_numpy(mask).long()


def dice_loss(logits: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
    probs = torch.softmax(logits, dim=1)
    onehot = F.one_hot(target, 3).permute(0, 3, 1, 2).float()
    dims = (0, 2, 3)
    inter = (probs * onehot).sum(dims)
    union = probs.sum(dims) + onehot.sum(dims)
    dice = (2 * inter + 1) / (union + 1)
    return 1 - dice[1:].mean()


@torch.no_grad()
def evaluate(model, loader, device):
    model.eval()
    inter = np.zeros(3)
    union = np.zeros(3)
    printed_hit = printed_total = 0
    tp = fp = fn = 0  # handwriting F1 on dark-ink pixels (black pen vs black print)
    pp_hw_inter = pp_hw_union = 0
    pp_printed_hit = 0
    for images, masks in loader:
        images, masks = images.to(device), masks.to(device)
        logits = model(images)
        probs = torch.softmax(logits, dim=1)
        pred = logits.argmax(1)
        for c in range(3):
            inter[c] += ((pred == c) & (masks == c)).sum().item()
            union[c] += ((pred == c) | (masks == c)).sum().item()
        is_printed = masks == 1
        printed_total += is_printed.sum().item()
        printed_hit += ((pred != 2) & is_printed).sum().item()
        luma = (0.299 * images[:, 0] + 0.587 * images[:, 1] + 0.114 * images[:, 2])
        dark = luma < 0.35
        tp += ((pred == 2) & (masks == 2) & dark).sum().item()
        fp += ((pred == 2) & (masks != 2) & dark).sum().item()
        fn += ((pred != 2) & (masks == 2) & dark).sum().item()

        # Also evaluate the actual runtime post-processed erase mask (0.55 threshold + 1.15 printed guard + 1px dilation)
        probs_np = probs.cpu().numpy()
        masks_np = masks.cpu().numpy()
        imgs_np = (images.permute(0, 2, 3, 1).cpu().numpy() * 255).astype(np.uint8)
        for b in range(len(imgs_np)):
            _, erase = composite(imgs_np[b], probs_np[b, 1], probs_np[b, 2])
            gt_hw = masks_np[b] == 2
            gt_pr = masks_np[b] == 1
            pp_hw_inter += int((erase & gt_hw).sum())
            pp_hw_union += int((erase | gt_hw).sum())
            pp_printed_hit += int((~erase & gt_pr).sum())

    iou = inter / np.maximum(union, 1)
    f1 = 2 * tp / max(1, 2 * tp + fp + fn)
    return {
        "handwriting_iou": float(iou[2]),
        "printed_iou": float(iou[1]),
        "printed_kept": printed_hit / max(1, printed_total),
        "dark_handwriting_f1": f1,
        "pp_handwriting_iou": pp_hw_inter / max(1, pp_hw_union),
        "pp_printed_kept": pp_printed_hit / max(1, printed_total),
    }


@torch.no_grad()
def save_preview(model, root: Path, runs: Path, device, count: int = 4):
    model.eval()
    ds = ExamDataset(root, "val", crop=None, augment=False)
    rows = []
    for i in range(min(count, len(ds))):
        image, mask = ds[i]
        probs = torch.softmax(model(image.unsqueeze(0).to(device)), dim=1)[0].cpu().numpy()
        rgb = (image.permute(1, 2, 0).numpy() * 255).astype(np.uint8)
        cleaned, _ = composite(rgb, probs[1], probs[2])
        gt = PALETTE[mask.numpy()]
        pred = PALETTE[probs.argmax(0)]
        rows.append(np.concatenate([rgb, gt, pred, cleaned], axis=1))
    Image.fromarray(np.concatenate(rows, axis=0)).save(runs / "val_preview.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default="data")
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--batch", type=int, default=12)
    parser.add_argument("--crop", type=int, default=384)
    parser.add_argument("--lr", type=float, default=2e-3)
    args = parser.parse_args()

    random.seed(0)
    torch.manual_seed(0)
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print("device:", device)

    root = Path(args.data)
    runs = Path("runs")
    runs.mkdir(exist_ok=True)

    train_loader = DataLoader(ExamDataset(root, "train", args.crop, True), batch_size=args.batch, shuffle=True, num_workers=0, drop_last=True)
    val_loader = DataLoader(ExamDataset(root, "val", None, False), batch_size=4, shuffle=False, num_workers=0)

    model = MobileNetV3LargeUNet().to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    steps = args.epochs * len(train_loader)
    scheduler = torch.optim.lr_scheduler.OneCycleLR(optimizer, max_lr=args.lr, total_steps=steps, pct_start=0.15)
    weights = torch.tensor(CLASS_WEIGHTS, device=device)

    best = -1.0
    for epoch in range(1, args.epochs + 1):
        model.train()
        started = time.time()
        running = 0.0
        for images, masks in train_loader:
            images, masks = images.to(device), masks.to(device)
            logits = model(images)
            loss = F.cross_entropy(logits, masks, weight=weights) + dice_loss(logits, masks)
            optimizer.zero_grad(set_to_none=True)
            loss.backward()
            optimizer.step()
            scheduler.step()
            running += loss.item()
        metrics = evaluate(model, val_loader, device)
        score = metrics["pp_handwriting_iou"] + 0.5 * metrics["pp_printed_kept"]
        print(
            f"epoch {epoch:02d}/{args.epochs} loss={running / len(train_loader):.4f} "
            f"hw_iou={metrics['handwriting_iou']:.3f} pp_hw_iou={metrics['pp_handwriting_iou']:.3f} "
            f"printed_kept={metrics['printed_kept']:.3f} pp_printed_kept={metrics['pp_printed_kept']:.3f} "
            f"dark_hw_f1={metrics['dark_handwriting_f1']:.3f} ({time.time() - started:.0f}s)",
            flush=True,
        )
        if score > best:
            best = score
            torch.save(model.state_dict(), runs / "best.pt")

    model.load_state_dict(torch.load(runs / "best.pt", map_location=device))
    final = evaluate(model, val_loader, device)
    print("best:", final)
    save_preview(model, root, runs, device)
    print("saved runs/best.pt and runs/val_preview.png")


if __name__ == "__main__":
    main()
