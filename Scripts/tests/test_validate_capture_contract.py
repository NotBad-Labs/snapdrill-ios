#!/usr/bin/env python3
"""Regression tests for Capture contract checks."""
from __future__ import annotations

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_capture_contract.py"


def load_validate_capture_contract():
    spec = importlib.util.spec_from_file_location("validate_capture_contract", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/validate_capture_contract.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_capture_contract = load_validate_capture_contract()


class ValidateCaptureContractTests(unittest.TestCase):
    def test_current_repo_capture_contract_passes(self) -> None:
        self.assertEqual(validate_capture_contract.run_checks(), [])

    def test_capture_localized_key_rejects_forbidden_copy(self) -> None:
        with self.temp_repo() as repo:
            path = repo / "SnapDrill/Resources/zh-Hans.lproj/Localizable.strings"
            path.write_text('"capture.camera_title" = "拍错题";\n', encoding="utf-8")

            errors = validate_capture_contract.run_checks(repo)

        self.assertTrue(any("capture.camera_title" in error for error in errors))

    def test_non_capture_localized_key_is_ignored(self) -> None:
        with self.temp_repo() as repo:
            path = repo / "SnapDrill/Resources/zh-Hans.lproj/Localizable.strings"
            path.write_text('"dashboard.empty_description" = "拍摄一道错题";\n', encoding="utf-8")

            errors = validate_capture_contract.run_checks(repo)

        self.assertEqual(errors, [])

    def test_info_plist_permission_copy_is_scanned(self) -> None:
        with self.temp_repo() as repo:
            path = repo / "SnapDrill/Resources/zh-Hans.lproj/InfoPlist.strings"
            path.write_text('"NSCameraUsageDescription" = "用于拍错题";\n', encoding="utf-8")

            errors = validate_capture_contract.run_checks(repo)

        self.assertTrue(any("NSCameraUsageDescription" in error for error in errors))

    def test_capture_swift_string_literal_is_scanned(self) -> None:
        with self.temp_repo() as repo:
            path = repo / "Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift"
            path.write_text('Text("儿童资料")\n', encoding="utf-8")

            errors = validate_capture_contract.run_checks(repo)

        self.assertTrue(any("CaptureView.swift" in error for error in errors))

    def test_capture_swift_comments_are_ignored(self) -> None:
        with self.temp_repo() as repo:
            path = repo / "Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift"
            path.write_text('// 年级已迁移，不是用户可见字串\nText("资料")\n', encoding="utf-8")

            errors = validate_capture_contract.run_checks(repo)

        self.assertEqual(errors, [])

    def temp_repo(self):
        return TemporaryCaptureRepo()


class TemporaryCaptureRepo:
    def __enter__(self) -> Path:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.copy_required_files()
        return self.root

    def __exit__(self, exc_type, exc, tb) -> None:
        self.tmp.cleanup()

    def copy_required_files(self) -> None:
        for relative_path in validate_capture_contract.required_paths(REPO_ROOT):
            source = relative_path
            destination = self.root / source.relative_to(REPO_ROOT)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)


if __name__ == "__main__":
    unittest.main()
