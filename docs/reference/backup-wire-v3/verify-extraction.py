#!/usr/bin/env python3

import hashlib
import pathlib
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
DATABASE = ROOT / "iOS-26.5-full-v3.sqlite"
EXTRACTOR = ROOT / "extract-trusted-fixture.sh"
EXPECTED_TREE_SHA256 = "34640c9dd1172a1893af27d8aa957bfca447a3949f47195b443d07e215effddc"
EXPECTED_FILES = {
    "backup_root.tsv",
    "category_dimension.tsv",
    "category_value.tsv",
    "header.tsv",
    "image_files.tsv",
    "images/00000000000000000000000000000022-answer.jpg",
    "images/00000000000000000000000000000022-main.jpg",
    "images/00000000000000000000000000000023-answer.jpg",
    "images/00000000000000000000000000000023-main.jpg",
    "item_category_value.tsv",
    "item_image.tsv",
    "library_item.tsv",
}
EXPECTED_IMAGES = {
    "images/00000000000000000000000000000022-answer.jpg":
        "cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414",
    "images/00000000000000000000000000000022-main.jpg":
        "3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d",
    "images/00000000000000000000000000000023-answer.jpg":
        "3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d",
    "images/00000000000000000000000000000023-main.jpg":
        "cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414",
}


def tree_sha256(root):
    digest = hashlib.sha256()
    for path in sorted(candidate for candidate in root.rglob("*") if candidate.is_file()):
        relative = path.relative_to(root).as_posix().encode("utf-8")
        data = path.read_bytes()
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        digest.update(len(data).to_bytes(8, "big"))
        digest.update(data)
    return digest.hexdigest()


with tempfile.TemporaryDirectory(prefix="snapdrill-v3-extraction-") as temporary:
    output = pathlib.Path(temporary) / "extracted"
    command = ["sh", str(EXTRACTOR), str(DATABASE), str(output)]
    subprocess.run(command, check=True)

    actual_files = {
        path.relative_to(output).as_posix()
        for path in output.rglob("*")
        if path.is_file()
    }
    assert actual_files == EXPECTED_FILES, (actual_files, EXPECTED_FILES)
    assert tree_sha256(output) == EXPECTED_TREE_SHA256

    for relative, expected in EXPECTED_IMAGES.items():
        actual = hashlib.sha256((output / relative).read_bytes()).hexdigest()
        assert actual == expected, (relative, actual, expected)

    dimensions = (output / "category_dimension.tsv").read_text(encoding="utf-8")
    items = (output / "library_item.tsv").read_text(encoding="utf-8")
    root_row = (output / "backup_root.tsv").read_text(encoding="utf-8")
    assert "436F6E7465787400E4B88AE4B88BE69687" in dimensions
    assert "410042" in items
    assert "E7AD94E6A18800416E73776572" in items
    assert "1B9A3235235FFA39F71C7BD4D11A592AE7692EF468FECD59333CA3FC62CB872F" in root_row

    second = subprocess.run(command, capture_output=True, text=True)
    assert second.returncode != 0
    assert tree_sha256(output) == EXPECTED_TREE_SHA256

print(f"PASS extraction tree_sha256={EXPECTED_TREE_SHA256} files={len(EXPECTED_FILES)}")
