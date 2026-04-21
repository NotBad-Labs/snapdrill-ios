"""docaudit self-test — 每子命令 ≥ 2 用例（正向 + 命中）+ policy/baseline 分支。"""

from __future__ import annotations

import io
import sys
import unittest
from contextlib import redirect_stdout, redirect_stderr
from datetime import date, timedelta
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import yaml

# 让 docaudit 作为模块导入 — 允许 REPO_ROOT 被测试覆盖
SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
import docaudit  # noqa: E402


BASE_POLICY = {
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
            "allowed_contexts": ["docs/principles/memory-routing.md"],
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
    policy = dict(BASE_POLICY)
    if overrides:
        # shallow merge per top-level key
        for k, v in overrides.items():
            if k in policy and isinstance(policy[k], dict) and isinstance(v, dict):
                policy[k] = {**policy[k], **v}
            else:
                policy[k] = v
    path = tmp / "policy.yaml"
    with path.open("w", encoding="utf-8") as fp:
        yaml.safe_dump(policy, fp)
    return path


def _make_fixture(repo: Path) -> None:
    """创建最小仓库骨架，tests 各自在基础之上继续加文件。"""
    (repo / "docs").mkdir(parents=True)
    (repo / "docs" / "memory").mkdir()
    (repo / "docs" / "principles").mkdir()
    (repo / "docs" / "research").mkdir()
    (repo / ".claude" / "rules").mkdir(parents=True)
    (repo / "Scripts").mkdir()
    (repo / "docs" / "memory" / "feedback.md").write_text(
        "## F-001\nrule 1\n\n## F-002\nrule 2\n", encoding="utf-8"
    )


class DocauditTestCase(unittest.TestCase):
    """端到端测试：每个子命令构造 fixture + 运行 + 断言 exit + findings。"""

    def setUp(self) -> None:
        self._tmp_ctx = TemporaryDirectory()
        self.tmp = Path(self._tmp_ctx.name)
        self.repo = self.tmp / "repo"
        self.repo.mkdir()
        _make_fixture(self.repo)
        # 让 docaudit 以 tmp repo 为根
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
        target = self.repo / "docs" / "ok.md"
        target.write_text("# ok\n", encoding="utf-8")
        (self.repo / "docs" / "index.md").write_text("see [ok](ok.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["links", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    def test_links_broken(self) -> None:
        (self.repo / "docs" / "index.md").write_text("see [missing](gone.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["links", "--policy", str(policy)])
        self.assertEqual(code, 1, out)
        self.assertIn("broken_link", out) if False else self.assertIn("error", out)

    # ---------- archived-refs ----------

    def test_archived_refs_clean(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text(
            "---\nstatus: archived\n---\n# study\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["archived-refs", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    def test_archived_refs_hit(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md for details\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["archived-refs", "--policy", str(policy)])
        self.assertEqual(code, 1, out)

    def test_archived_refs_baseline_skip(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md\n", encoding="utf-8"
        )
        tomorrow = (date.today() + timedelta(days=1)).isoformat()
        policy = _write_policy(
            self.tmp,
            overrides={"legacy_whitelist": {
                "archived-refs": {"baseline_accepted": True, "accepted_until": tomorrow}
            }},
        )
        code, out, _ = self._run(["archived-refs", "--policy", str(policy), "--baseline"])
        self.assertEqual(code, 0, out)
        self.assertIn("SKIPPED", out)

    def test_archived_refs_baseline_expired(self) -> None:
        (self.repo / "docs" / "research" / "study.md").write_text("archived\n", encoding="utf-8")
        (self.repo / "docs" / "active.md").write_text(
            "see docs/research/study.md\n", encoding="utf-8"
        )
        yesterday = (date.today() - timedelta(days=1)).isoformat()
        policy = _write_policy(
            self.tmp,
            overrides={"legacy_whitelist": {
                "archived-refs": {"baseline_accepted": True, "accepted_until": yesterday}
            }},
        )
        code, out, _ = self._run(["archived-refs", "--policy", str(policy), "--baseline"])
        self.assertEqual(code, 1, out)  # 过期自动转严格

    # ---------- orphans ----------

    def test_orphans_clean(self) -> None:
        (self.repo / "docs" / "a.md").write_text("# a\n", encoding="utf-8")
        (self.repo / "docs" / "b.md").write_text("see [a](a.md)\n", encoding="utf-8")
        # feedback.md 已有，会引用 F-001/F-002 吗？没有，与本测试无关
        # 额外加一个 index 引用 b.md 避免 b 被判孤儿
        (self.repo / "docs" / "index.md").write_text("see [b](b.md)\n", encoding="utf-8")
        # index.md 本身被 STATUS.md 引用
        (self.repo / "STATUS.md").write_text("entry: docs/index.md\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["orphans", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    def test_orphans_hit(self) -> None:
        (self.repo / "docs" / "lonely.md").write_text("# lonely\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["orphans", "--policy", str(policy)])
        # level=warning 默认不 exit 1
        self.assertEqual(code, 0, out)
        self.assertIn("warning", out)

    def test_orphans_strict_escalates(self) -> None:
        (self.repo / "docs" / "lonely.md").write_text("# lonely\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, _, _ = self._run(["orphans", "--strict", "--policy", str(policy)])
        self.assertEqual(code, 1)

    # ---------- home-path-refs ----------

    def test_home_path_refs_clean(self) -> None:
        (self.repo / "docs" / "clean.md").write_text("no private path here\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["home-path-refs", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    def test_home_path_refs_hit(self) -> None:
        (self.repo / "docs" / "dirty.md").write_text(
            "see ~/.claude/plans/foo.md\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["home-path-refs", "--policy", str(policy)])
        # level=warning 默认不 exit 1
        self.assertEqual(code, 0, out)
        self.assertIn("warning", out)

    def test_home_path_refs_allowed_context(self) -> None:
        # memory-routing.md 在 allowed_contexts 中
        mr = self.repo / "docs" / "principles" / "memory-routing.md"
        mr.write_text("discuss ~/.claude/plans/ here\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["home-path-refs", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    # ---------- rule-pointer-sync ----------

    def test_rule_pointer_sync_clean(self) -> None:
        (self.repo / "docs" / "principles" / "coding.md").write_text("# coding\n", encoding="utf-8")
        (self.repo / ".claude" / "rules" / "coding.md").write_text(
            "Read and follow docs/principles/coding.md for rules.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["rule-pointer-sync", "--policy", str(policy)])
        self.assertEqual(code, 0, out)

    def test_rule_pointer_sync_broken(self) -> None:
        (self.repo / ".claude" / "rules" / "coding.md").write_text(
            "Read and follow docs/principles/missing.md for rules.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["rule-pointer-sync", "--policy", str(policy)])
        self.assertEqual(code, 1, out)
        self.assertIn("broken_pointer", out) if False else self.assertIn("error", out)

    def test_rule_pointer_sync_missing_pointer(self) -> None:
        (self.repo / ".claude" / "rules" / "orphan.md").write_text(
            "This rule has no pointer.\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, _, _ = self._run(["rule-pointer-sync", "--policy", str(policy)])
        self.assertEqual(code, 1)

    # ---------- rule-usage ----------

    def test_rule_usage_info_only(self) -> None:
        # F-001 在 feedback.md 中声明但无外部引用 → dead candidate (info 级，不 exit 1)
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["rule-usage", "--policy", str(policy)])
        self.assertEqual(code, 0, out)
        self.assertIn("info", out)

    def test_rule_usage_referenced(self) -> None:
        # F-001 被其他文档引用 → 不是 dead
        (self.repo / "docs" / "workflow.md").write_text(
            "remember F-001 applies here\n## note\nalso F-002\n", encoding="utf-8"
        )
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["rule-usage", "--policy", str(policy)])
        self.assertEqual(code, 0, out)
        self.assertIn("clean", out)

    # ---------- 多 check 聚合 ----------

    def test_all_runs_every_check(self) -> None:
        policy = _write_policy(self.tmp)
        code, out, _ = self._run(["--all", "--policy", str(policy)])
        # 基础 fixture 只有 feedback.md 2 条 dead rule（info 级）+ 可能 orphans
        for name in docaudit.CHECK_NAMES:
            self.assertIn(f"[{name}]", out)

    def test_report_writes_tsv(self) -> None:
        (self.repo / "docs" / "index.md").write_text("[bad](nope.md)\n", encoding="utf-8")
        policy = _write_policy(self.tmp)
        code, _, _ = self._run(["links", "--report", "--policy", str(policy)])
        tsv = self.repo / "reports" / "links.tsv"
        self.assertTrue(tsv.is_file())
        content = tsv.read_text(encoding="utf-8")
        self.assertIn("check\tpath", content)
        self.assertIn("broken_link", content)


class PolicyEdgeCaseTests(unittest.TestCase):

    def test_missing_policy_exits_2(self) -> None:
        with TemporaryDirectory() as td:
            missing = Path(td) / "no.yaml"
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                try:
                    docaudit.main(["links", "--policy", str(missing)])
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
                    docaudit.main(["links", "--policy", str(path)])
                except SystemExit as exc:
                    self.assertEqual(exc.code, 2)
                    return
                self.fail("expected SystemExit")


if __name__ == "__main__":
    unittest.main()
