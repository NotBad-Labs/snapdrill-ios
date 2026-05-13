"""docaudit self-test — 覆盖 Codex Review 修复（Critical 1/2 + High 1/2/3）+ 原 DoD。"""

from __future__ import annotations

import io
import stat
import sys
import unittest
from contextlib import redirect_stdout, redirect_stderr
from datetime import date, timedelta
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import yaml

SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
import docaudit  # noqa: E402


def _base_policy() -> dict:
    return {
        "version": 1,
        "scan": {
            "include": ["docs/", ".claude/", "Scripts/", "STATUS.md", "CLAUDE.md", "README.md"],
            "exclude": [".claude/worktrees/", "docs/archive/", "Scripts/audit/tests/fixtures/"],
        },
        "checks": {
            "links": {"level": "error", "description": ""},
            "archived-refs": {
                "level": "error",
                "description": "",
                "archived_sources": ["docs/research/study.md"],
            },
            "orphans": {
                "level": "warning",
                "description": "",
                "whitelist": ["docs/product/**", "docs/archive/**"],
            },
            "home-path-refs": {
                "level": "warning",
                "description": "",
                "allowed_contexts": ["docs/standards/memory-routing.md"],
            },
            "rule-pointer-sync": {
                "level": "error",
                "description": "",
                "allowlist_rules": [".claude/rules/README.md"],
            },
            "rule-usage": {
                "level": "info",
                "description": "",
                "min_references": 1,
            },
        },
        "output": {"tsv_dir": "reports/", "summary_stdout": True, "verbose_default": False},
    }


def _write_policy(tmp: Path, overrides: dict | None = None) -> Path:
    policy = _base_policy()
    if overrides:
        for k, v in overrides.items():
            if k in policy and isinstance(policy[k], dict) and isinstance(v, dict):
                policy[k] = {**policy[k], **v}
            else:
                policy[k] = v
    path = tmp / "policy.yaml"
    with path.open("w", encoding="utf-8") as fp:
        yaml.safe_dump(policy, fp, sort_keys=False)
    return path


def _make_fixture(repo: Path, fake_validator: bool = True) -> None:
    (repo / "docs").mkdir(parents=True)
    (repo / "docs" / "memory").mkdir()
    (repo / "docs" / "principles").mkdir()
    (repo / "docs" / "research").mkdir()
    (repo / ".claude" / "rules").mkdir(parents=True)
    (repo / "Scripts").mkdir()
    (repo / "docs" / "memory" / "feedback.md").write_text(
        "## F-001\nrule 1\n\n## F-002\nrule 2\n", encoding="utf-8"
    )
    if fake_validator:
        vf = repo / "Scripts" / "validate_frontmatter.py"
        vf.write_text(
            "#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n",
            encoding="utf-8",
        )
        vf.chmod(vf.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


class DocauditTestCase(unittest.TestCase):
    """端到端测试：每子命令构造 fixture + 运行 + 断言 exit + findings。"""

    def setUp(self) -> None:
        self._tmp_ctx = TemporaryDirectory()
        self.tmp = Path(self._tmp_ctx.name)
        self.repo = self.tmp / "repo"
        self.repo.mkdir()
        _make_fixture(self.repo)
        self._repo_patch = patch.object(docaudit, "REPO_ROOT", self.repo)
        self._repo_patch.start()

    def tearDown(self) -> None:
        self._repo_patch.stop()
        self._tmp_ctx.cleanup()

    def _run(self, argv: list[str]) -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            try:
                code = docaudit.main(argv)
            except SystemExit as exc:
                code = int(exc.code or 0)
        return code, stdout.getvalue(), stderr.getvalue()

    # ---------- links ----------

    def test_links_clean(self) -> None:
        (self.repo / "docs" / "ok.md").write_text("# ok\n", encoding="utf-8")
        (self.repo / "docs" / "index.md").write_text("see [ok](ok.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "links"])
        self.assertEqual(code, 0, out)

    def test_links_broken(self) -> None:
        (self.repo / "docs" / "index.md").write_text("see [missing](gone.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, err = self._run(["--policy", str(policy), "links"])
        self.assertEqual(code, 1, out)
        self.assertIn("error", out)
        self.assertIn("docaudit exit 1", err)  # stderr 镜像

    # ---------- archived-refs ----------

    def test_archived_refs_clean(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text(
            "---\nstatus: archived\n---\n# study\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "archived-refs"])
        self.assertEqual(code, 0, out)

    def test_archived_refs_NOT_matching_basename_only(self) -> None:
        """Phase C PR-α2 修 Issue #710 High 3：basename 匹配已移除，完整路径才命中。
        归档后新路径（docs/archive/research/<name>.md）不应因为共享 basename 而被误判。
        """
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        # 同 basename 的新归档路径
        (self.repo / "docs" / "archive").mkdir(exist_ok=True)
        (self.repo / "docs" / "archive" / "research").mkdir()
        (self.repo / "docs" / "archive" / "research" / "study.md").write_text("# archived\n", encoding="utf-8")
        # 叙述引用新路径
        (self.repo / "docs" / "narrative.md").write_text(
            "see docs/archive/research/study.md for the archived study\n",
            encoding="utf-8",
        )
        policy = _write_policy(self.tmp)  # archived_sources = ["docs/research/study.md"]
        code, out, _ = self._run(["--policy", str(policy), "archived-refs"])
        # 关键：docs/narrative.md 引用新路径（完整路径不同）应不命中
        # 只有 docs/research/study.md 自身路径被引用时才命中
        self.assertEqual(code, 0, out)

    def test_archived_refs_hit(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md for details\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, err = self._run(["--policy", str(policy), "archived-refs"])
        self.assertEqual(code, 1, out)
        self.assertIn("1 error", out)
        self.assertIn("docaudit exit 1", err)

    def test_archived_refs_suppressed_by_path(self) -> None:
        """Critical 1 修复：whitelist 按 path 匹配 → suppressed → exit 0，但 finding 仍在报告里可见。"""
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md\n", encoding="utf-8"
        )
        tomorrow = (date.today() + timedelta(days=30)).isoformat()
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "reason": "legacy baseline",
                "expires_on": tomorrow,
                "paths": ["docs/active.md"],
            }],
        })
        code, out, _ = self._run(["--policy", str(policy), "archived-refs", "--baseline"])
        self.assertEqual(code, 0, out)
        self.assertIn("1 suppressed", out)

    def test_archived_refs_new_file_NOT_suppressed(self) -> None:
        """Critical 1 关键：新增违规（path 不在 whitelist）仍然 error，防回归。"""
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        # 白名单只覆盖 old.md，新增 new.md 违规不被豁免
        (self.repo / "docs" / "old.md").write_text("see docs/research/study.md\n", encoding="utf-8")
        (self.repo / "docs" / "new.md").write_text("see docs/research/study.md\n", encoding="utf-8")
        tomorrow = (date.today() + timedelta(days=30)).isoformat()
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "reason": "only old.md is baselined",
                "expires_on": tomorrow,
                "paths": ["docs/old.md"],
            }],
        })
        code, out, _ = self._run(["--policy", str(policy), "archived-refs", "--baseline"])
        self.assertEqual(code, 1, out)         # new.md 仍然 error
        self.assertIn("1 error", out)
        self.assertIn("1 suppressed", out)     # old.md 被豁免

    def test_archived_refs_expired_whitelist_no_suppression(self) -> None:
        """过期规则不生效（fail-closed）。"""
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md\n", encoding="utf-8"
        )
        yesterday = (date.today() - timedelta(days=1)).isoformat()
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "reason": "expired",
                "expires_on": yesterday,
                "paths": ["docs/active.md"],
            }],
        })
        code, out, _ = self._run(["--policy", str(policy), "archived-refs", "--baseline"])
        self.assertEqual(code, 1, out)
        self.assertNotIn("suppressed", out)

    # ---------- whitelist schema edge cases (Critical 2 + fail-closed) ----------

    def test_whitelist_invalid_expires_on_exit_2(self) -> None:
        """Critical 2 修复：无效日期不再 fail-open，而是 exit 2 + stderr 告警。"""
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "reason": "r",
                "expires_on": "not-a-date",
            }],
        })
        code, _, err = self._run(["--policy", str(policy), "archived-refs", "--baseline"])
        self.assertEqual(code, 2)
        self.assertIn("expires_on", err)

    def test_whitelist_missing_reason_exit_2(self) -> None:
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "expires_on": "2099-12-31",
            }],
        })
        code, _, err = self._run(["--policy", str(policy), "archived-refs"])
        self.assertEqual(code, 2)
        self.assertIn("reason", err)

    def test_whitelist_unknown_check_exit_2(self) -> None:
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "not-a-check",
                "reason": "r",
                "expires_on": "2099-12-31",
            }],
        })
        code, _, err = self._run(["--policy", str(policy), "archived-refs"])
        self.assertEqual(code, 2)
        self.assertIn("unknown", err.lower())

    def test_whitelist_not_applied_without_baseline_flag(self) -> None:
        """--baseline 未启用时 whitelist 不生效。"""
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md\n", encoding="utf-8"
        )
        tomorrow = (date.today() + timedelta(days=30)).isoformat()
        policy = _write_policy(self.tmp, overrides={
            "legacy_whitelist": [{
                "check": "archived-refs",
                "reason": "r",
                "expires_on": tomorrow,
                "paths": ["docs/active.md"],
            }],
        })
        code, out, _ = self._run(["--policy", str(policy), "archived-refs"])
        self.assertEqual(code, 1, out)

    # ---------- orphans ----------

    def test_orphans_clean(self) -> None:
        (self.repo / "docs" / "a.md").write_text("# a\n", encoding="utf-8")
        (self.repo / "docs" / "b.md").write_text("see [a](a.md)\n", encoding="utf-8")
        (self.repo / "docs" / "index.md").write_text("see [b](b.md)\n", encoding="utf-8")
        (self.repo / "STATUS.md").write_text("entry: docs/index.md\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "orphans"])
        self.assertEqual(code, 0, out)

    def test_orphans_hit_warning_does_not_fail(self) -> None:
        (self.repo / "docs" / "lonely.md").write_text("# lonely\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, err = self._run(["--policy", str(policy), "orphans"])
        self.assertEqual(code, 0, out)
        self.assertIn("warning", out)
        # High 2: warning 镜像到 stderr
        self.assertIn("warning", err)

    def test_orphans_strict_escalates(self) -> None:
        (self.repo / "docs" / "lonely.md").write_text("# lonely\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, err = self._run(["--policy", str(policy), "orphans", "--strict"])
        self.assertEqual(code, 1)
        # High 1: --strict 下 summary 应明确反映 exit 非 0
        self.assertIn("Exit: 1", out)
        self.assertIn("strict", out)

    # ---------- home-path-refs ----------

    def test_home_path_refs_clean(self) -> None:
        (self.repo / "docs" / "clean.md").write_text("no private path\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "home-path-refs"])
        self.assertEqual(code, 0, out)

    def test_home_path_refs_hit(self) -> None:
        (self.repo / "docs" / "dirty.md").write_text(
            "see ~/.claude/plans/foo.md\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, err = self._run(["--policy", str(policy), "home-path-refs"])
        self.assertEqual(code, 0, out)
        self.assertIn("warning", out)
        self.assertIn("warning", err)

    def test_home_path_refs_allowed_context(self) -> None:
        mr = self.repo / "docs" / "principles" / "memory-routing.md"
        mr.write_text("discuss ~/.claude/plans/ here\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "home-path-refs"])
        self.assertEqual(code, 0, out)

    # ---------- rule-pointer-sync ----------

    def test_rule_pointer_sync_clean(self) -> None:
        (self.repo / "docs" / "principles" / "coding.md").write_text("# coding\n", encoding="utf-8")
        (self.repo / ".claude" / "rules" / "coding.md").write_text(
            "Read and follow docs/standards/coding.md for rules.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "rule-pointer-sync"])
        self.assertEqual(code, 0, out)

    def test_rule_pointer_sync_broken(self) -> None:
        (self.repo / ".claude" / "rules" / "coding.md").write_text(
            "Read and follow docs/standards/missing.md for rules.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "rule-pointer-sync"])
        self.assertEqual(code, 1, out)
        self.assertIn("error", out)

    def test_rule_pointer_sync_missing_pointer(self) -> None:
        (self.repo / ".claude" / "rules" / "orphan.md").write_text(
            "This rule has no pointer.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, _, _ = self._run(["--policy", str(policy), "rule-pointer-sync"])
        self.assertEqual(code, 1)

    # ---------- rule-usage ----------

    def test_rule_usage_info_only(self) -> None:
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "rule-usage"])
        self.assertEqual(code, 0, out)
        self.assertIn("info", out)

    def test_rule_usage_referenced(self) -> None:
        (self.repo / "docs" / "workflow.md").write_text(
            "remember F-001 applies\nalso F-002\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "rule-usage"])
        self.assertEqual(code, 0, out)
        self.assertIn("clean", out)

    # ---------- all (含 frontmatter subprocess) ----------

    def test_all_runs_every_check_with_fake_validator(self) -> None:
        """High 3 修复：`all` 子命令包含 frontmatter via subprocess。"""
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "all"])
        self.assertIn("[frontmatter]", out)
        for name in docaudit.CHECK_NAMES:
            self.assertIn(f"[{name}]", out)

    def test_all_missing_validator_reports_error(self) -> None:
        """validate_frontmatter.py 缺失 → frontmatter CheckResult 报 error。"""
        (self.repo / "Scripts" / "validate_frontmatter.py").unlink()
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--policy", str(policy), "all"])
        self.assertEqual(code, 1, out)
        self.assertIn("[frontmatter]", out)
        self.assertIn("error", out)

    # ---------- TSV report ----------

    def test_report_writes_tsv(self) -> None:
        (self.repo / "docs" / "index.md").write_text("[bad](nope.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, _, _ = self._run(["--policy", str(policy), "links", "--report"])
        tsv = self.repo / "reports" / "links.tsv"
        self.assertTrue(tsv.is_file())
        content = tsv.read_text(encoding="utf-8")
        self.assertIn("check\tpath", content)
        self.assertIn("status", content)  # 新字段
        self.assertIn("broken_link", content)

    # ---------- 独立 help（High 4 修复） ----------

    def test_subcommand_help_is_independent(self) -> None:
        """High 4 修复：每个子命令 --help 有独立 description + epilog。"""
        parser = docaudit.build_parser()
        # 找到 links 子 parser
        actions = [a for a in parser._actions if isinstance(a, __import__("argparse")._SubParsersAction)]
        self.assertTrue(actions)
        choices = actions[0].choices
        self.assertIn("links", choices)
        self.assertIn("all", choices)
        links_parser = choices["links"]
        self.assertIn("broken_link", links_parser.description or "" + (links_parser.epilog or ""))


class PolicyEdgeCaseTests(unittest.TestCase):

    def test_missing_policy_exits_2(self) -> None:
        with TemporaryDirectory() as td:
            missing = Path(td) / "no.yaml"
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                try:
                    docaudit.main(["--policy", str(missing), "links"])
                except SystemExit as exc:
                    self.assertEqual(exc.code, 2)
                    self.assertIn("policy.yaml not found", stderr.getvalue())
                    return
                self.fail("expected SystemExit")

    def test_invalid_version_exits_2(self) -> None:
        with TemporaryDirectory() as td:
            path = Path(td) / "policy.yaml"
            with path.open("w") as fp:
                yaml.safe_dump({"version": 99}, fp)
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                try:
                    docaudit.main(["--policy", str(path), "links"])
                except SystemExit as exc:
                    self.assertEqual(exc.code, 2)
                    return
                self.fail("expected SystemExit")


if __name__ == "__main__":
    unittest.main()
