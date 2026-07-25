#!/usr/bin/env python3
"""扫描 docs/features/**/feat-*.md 的 YAML frontmatter，自动生成实现状态索引。

B 方案（状态自动单写）：各 feature spec 的 frontmatter 是实现状态的唯一来源；
本脚本把它们汇总成只读看板。实现存在不等于 Release 1 PRD 符合、公开可达或发布就绪。

用法：
    python3 Scripts/generate_feature_status.py            # 生成 / 覆盖看板
    python3 Scripts/generate_feature_status.py --check    # 只校验看板是否最新（CI / pre-commit 用），不写
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
FEATURES_DIR = REPO_ROOT / "docs" / "features"
OUTPUT = REPO_ROOT / "docs" / "reference" / "feature-status.md"

STATUS_LABEL = {
    "implemented": "🧩 实现存在",
    "in-progress": "🛠 进行中",
    "blocked": "⛔ 阻塞",
    "poc-needed": "🔬 需 PoC",
    "backlog": "📋 Backlog",
}
TIER_LABEL = {"free": "免费", "pro": "Pro", "undecided": "未定"}
STATUS_ORDER = {"implemented": 0, "in-progress": 1, "blocked": 2, "poc-needed": 3, "backlog": 4}

REQUIRED = ("id", "title", "status", "tier", "mode", "last_updated")
MODE_LABEL = {"full": "full", "lightweight": "lightweight"}
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def parse_frontmatter(path: Path) -> dict | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    data = yaml.safe_load(parts[1]) or {}
    data["__path"] = path
    return data


def collect() -> list[dict]:
    specs: list[dict] = []
    for path in sorted(FEATURES_DIR.rglob("feat-*.md")):
        if path.name == "template.md":
            continue
        fm = parse_frontmatter(path)
        if fm is None:
            print(f"[warn] 无 frontmatter，跳过：{path.relative_to(REPO_ROOT)}", file=sys.stderr)
            continue
        missing = [k for k in REQUIRED if k not in fm]
        if missing:
            print(f"[error] {path.relative_to(REPO_ROOT)} frontmatter 缺字段：{missing}", file=sys.stderr)
            sys.exit(1)
        if fm["status"] not in STATUS_LABEL:
            print(f"[error] {path.relative_to(REPO_ROOT)} status 无效：{fm['status']}", file=sys.stderr)
            sys.exit(1)
        if fm["tier"] not in TIER_LABEL:
            print(f"[error] {path.relative_to(REPO_ROOT)} tier 无效：{fm['tier']}", file=sys.stderr)
            sys.exit(1)
        if fm["mode"] not in MODE_LABEL:
            print(f"[error] {path.relative_to(REPO_ROOT)} mode 无效：{fm['mode']}", file=sys.stderr)
            sys.exit(1)
        if not DATE_PATTERN.match(str(fm["last_updated"])):
            print(f"[error] {path.relative_to(REPO_ROOT)} last_updated 必须为 YYYY-MM-DD", file=sys.stderr)
            sys.exit(1)
        if not isinstance(fm.get("blocked_by", []), list):
            print(f"[error] {path.relative_to(REPO_ROOT)} blocked_by 必须为列表", file=sys.stderr)
            sys.exit(1)
        if fm["status"] == "blocked" and not fm.get("blocked_by"):
            print(f"[error] {path.relative_to(REPO_ROOT)} status=blocked 但 blocked_by 为空", file=sys.stderr)
            sys.exit(1)
        specs.append(fm)
    return specs


def render(specs: list[dict]) -> str:
    specs = sorted(specs, key=lambda s: (STATUS_ORDER.get(s["status"], 9), s["id"]))
    lines = [
        "# 功能实现状态总表（自动生成）",
        "",
        "> ⚠️ 本文件由 `Scripts/generate_feature_status.py` 自动生成，**禁止手动编辑**。",
        "> 实现状态唯一来源 = 各 `docs/features/**/feat-*.md` 的 frontmatter（B 方案 · 自动单写）。",
        "> `实现存在` 只表示 live code 已有对应路径；不表示符合 Release 1 PRD、公开可达或发布就绪。",
        "> 改状态 = 改对应 spec 的 frontmatter 后重跑脚本（pre-commit 自动校验是否最新）。",
        "",
        "| 功能 | 实现状态 | 层级 | 阻塞 | 模式 | 最后更新 |",
        "|---|---|---|---|---|---|",
    ]
    for s in specs:
        # reference/ 在 docs 下，feat 在 docs/features 下 → 链接以 ../ 起头
        link = "../" + s["__path"].relative_to(REPO_ROOT / "docs").as_posix()
        status = STATUS_LABEL.get(s["status"], s["status"])
        tier = TIER_LABEL.get(s["tier"], s["tier"])
        blocked = ", ".join(f"#{n}" for n in (s.get("blocked_by") or [])) or "—"
        mode = s.get("mode", "full")
        lines.append(
            f"| [{s['title']}]({link}) | {status} | {tier} | {blocked} | {mode} | {s['last_updated']} |"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(description="生成功能实现状态索引（自动单写）")
    ap.add_argument("--check", action="store_true", help="只校验看板是否最新，不写（CI / pre-commit 用）")
    args = ap.parse_args()

    content = render(collect())

    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current.strip() != content.strip():
            print(
                "[error] feature-status.md 已过期，请运行 "
                "`python3 Scripts/generate_feature_status.py` 重新生成",
                file=sys.stderr,
            )
            sys.exit(1)
        print("[ok] feature-status.md 最新")
        return

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(content, encoding="utf-8")
    print(f"[ok] 已生成 {OUTPUT.relative_to(REPO_ROOT)}（{len(collect())} 个 feature）")


if __name__ == "__main__":
    main()
