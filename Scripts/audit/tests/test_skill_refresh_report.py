from __future__ import annotations

import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
import skill_refresh_report  # noqa: E402


class SkillRefreshReportTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = TemporaryDirectory()
        self.tmp = Path(self.tmpdir.name)
        self.repo = self.tmp / "repo"
        self.upstream = self.tmp / "upstream"
        self.repo.mkdir()
        self.upstream.mkdir()
        self.lockfile = self.repo / "skills-lock.json"
        self.patcher = patch.object(skill_refresh_report, "REPO_ROOT", self.repo)
        self.patcher.start()

    def tearDown(self) -> None:
        self.patcher.stop()
        self.tmpdir.cleanup()

    def _write(self, root: Path, path: str, text: str) -> Path:
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
        return target

    def _write_lock(self, local_blob: str, upstream_blob: str, support: dict[str, str] | None = None) -> None:
        entry: dict[str, object] = {
            "kind": "vendored",
            "source": "owner/repo",
            "sourceType": "github",
            "upstreamCommit": "0123456789abcdef0123456789abcdef01234567",
            "upstreamPath": "skills/example/SKILL.md",
            "upstreamBlob": upstream_blob,
            "localPath": ".agents/skills/example/SKILL.md",
            "localBlob": local_blob,
            "patchStatus": "frontmatter-adapter-only",
        }
        if support is not None:
            entry["supportFiles"] = [support]
        self.lockfile.write_text(
            json.dumps({"version": 1, "skills": {"example": entry}}, indent=2) + "\n",
            encoding="utf-8",
        )

    def test_clean_report_is_zero_in_strict_mode(self) -> None:
        local = self._write(self.repo, ".agents/skills/example/SKILL.md", "# Local\n")
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        self._write_lock(
            skill_refresh_report.git_blob_sha(local),
            skill_refresh_report.git_blob_sha(upstream),
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 0, out.getvalue())
        self.assertIn("skill-local", out.getvalue())
        self.assertIn("\tok", out.getvalue())
        self.assertIn("local_vs_upstream", out.getvalue().splitlines()[0])

    def test_changed_local_blob_fails_strict_mode(self) -> None:
        self._write(self.repo, ".agents/skills/example/SKILL.md", "# Changed\n")
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        self._write_lock(
            "fedcba9876543210fedcba9876543210fedcba98",
            skill_refresh_report.git_blob_sha(upstream),
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 1, out.getvalue())
        self.assertIn("\tchanged", out.getvalue())

    def test_frontmatter_only_relation_is_reported(self) -> None:
        local = self._write(
            self.repo,
            ".agents/skills/example/SKILL.md",
            "---\nname: example\n---\n# Body\n",
        )
        upstream = self._write(
            self.upstream,
            "skills/example/SKILL.md",
            "---\nname: example\nallowed-tools: Read\n---\n# Body\n",
        )
        self._write_lock(
            skill_refresh_report.git_blob_sha(local),
            skill_refresh_report.git_blob_sha(upstream),
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 0, out.getvalue())
        self.assertIn("\tfrontmatter-only", out.getvalue())

    def test_wrong_upstream_git_head_fails_strict_mode(self) -> None:
        local = self._write(self.repo, ".agents/skills/example/SKILL.md", "# Local\n")
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        self._write_lock(
            skill_refresh_report.git_blob_sha(local),
            skill_refresh_report.git_blob_sha(upstream),
        )

        out = io.StringIO()
        with patch.object(skill_refresh_report, "git_head", return_value="fedcba9876543210fedcba9876543210fedcba98"):
            with redirect_stdout(out):
                code = skill_refresh_report.main([
                    "--upstream-root",
                    str(self.upstream),
                    "--lockfile",
                    str(self.lockfile),
                    "--strict",
                ])

        self.assertEqual(code, 1, out.getvalue())
        self.assertIn("\twrong-commit", out.getvalue())

    def test_missing_file_fails_strict_mode(self) -> None:
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        self._write_lock(
            "fedcba9876543210fedcba9876543210fedcba98",
            skill_refresh_report.git_blob_sha(upstream),
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 1, out.getvalue())
        self.assertIn("\tmissing", out.getvalue())

    def test_out_of_scope_path_fails_strict_mode(self) -> None:
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        self.lockfile.write_text(
            json.dumps({
                "version": 1,
                "skills": {
                    "example": {
                        "kind": "vendored",
                        "upstreamPath": "skills/example/SKILL.md",
                        "upstreamBlob": skill_refresh_report.git_blob_sha(upstream),
                        "localPath": "/etc/passwd",
                        "localBlob": "fedcba9876543210fedcba9876543210fedcba98",
                    },
                },
            }) + "\n",
            encoding="utf-8",
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 1, out.getvalue())
        self.assertIn("\tout-of-scope", out.getvalue())

    def test_invalid_lockfile_schema_exits_2(self) -> None:
        self.lockfile.write_text('{"version": 1, "skills": []}\n', encoding="utf-8")

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 2, out.getvalue())

    def test_support_files_are_reported(self) -> None:
        local = self._write(self.repo, ".agents/skills/example/SKILL.md", "# Local\n")
        upstream = self._write(self.upstream, "skills/example/SKILL.md", "# Upstream\n")
        support_local = self._write(self.repo, ".agents/skills/example/support.md", "# Support\n")
        support_upstream = self._write(self.upstream, "skills/example/support.md", "# Support\n")
        self._write_lock(
            skill_refresh_report.git_blob_sha(local),
            skill_refresh_report.git_blob_sha(upstream),
            support={
                "localPath": ".agents/skills/example/support.md",
                "localBlob": skill_refresh_report.git_blob_sha(support_local),
                "upstreamPath": "skills/example/support.md",
                "upstreamBlob": skill_refresh_report.git_blob_sha(support_upstream),
            },
        )

        out = io.StringIO()
        with redirect_stdout(out):
            code = skill_refresh_report.main([
                "--upstream-root",
                str(self.upstream),
                "--lockfile",
                str(self.lockfile),
                "--strict",
            ])

        self.assertEqual(code, 0, out.getvalue())
        self.assertIn("support-local", out.getvalue())
        self.assertIn("support-upstream", out.getvalue())


if __name__ == "__main__":
    unittest.main()
