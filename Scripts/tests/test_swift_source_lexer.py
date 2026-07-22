#!/usr/bin/env python3
"""Regression tests for the policy-neutral Swift source lexer."""
from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "swift_source_lexer.py"


def load_lexer():
    module_name = "test_subject_swift_source_lexer"
    spec = importlib.util.spec_from_file_location(module_name, MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/swift_source_lexer.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


lexer = load_lexer()
ConditionalState = lexer.ConditionalState
SwiftLexicalError = lexer.SwiftLexicalError
TokenKind = lexer.TokenKind


class SwiftSourceLexerTests(unittest.TestCase):
    def test_module_is_import_safe_from_unrelated_working_directory(self) -> None:
        program = f"""
import importlib.util, pathlib, sys
path = pathlib.Path({str(MODULE_PATH)!r})
spec = importlib.util.spec_from_file_location('isolated_lexer', path)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
assert module.tokenize('let value = 1')
"""
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, "-c", program],
                cwd=directory,
                capture_output=True,
                text=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_tokens_have_kind_value_position_offset_and_condition(self) -> None:
        source = "// ignored\nlet `class` = \"value\".count\n"
        tokens = lexer.tokenize(source)

        self.assertEqual(
            [(token.kind, token.value) for token in tokens],
            [
                (TokenKind.IDENTIFIER, "let"),
                (TokenKind.IDENTIFIER, "class"),
                (TokenKind.PUNCTUATION, "="),
                (TokenKind.STRING_SEGMENT, "value"),
                (TokenKind.PUNCTUATION, "."),
                (TokenKind.IDENTIFIER, "count"),
            ],
        )
        first = tokens[0]
        self.assertEqual((first.line, first.column, first.offset), (2, 1, 11))
        self.assertEqual(first.end_offset, 14)
        self.assertTrue(all(token.condition is ConditionalState.TRUE for token in tokens))

    def test_nested_block_and_line_comments_are_never_emitted(self) -> None:
        source = """
let before = 1 /* outer /* #if DEBUG */ still outer */
// #if DEBUG
let after = 2
"""
        values = [token.value for token in lexer.tokenize(source)]

        self.assertEqual(values.count("let"), 2)
        self.assertNotIn("outer", values)
        self.assertNotIn("DEBUG", values)

    def test_kleene_truth_table_and_function_like_atoms(self) -> None:
        cases = {
            "DEBUG": ConditionalState.FALSE,
            "!DEBUG": ConditionalState.TRUE,
            "feature": ConditionalState.UNKNOWN,
            "!targetEnvironment(simulator)": ConditionalState.UNKNOWN,
            "DEBUG && canImport(UIKit)": ConditionalState.FALSE,
            "canImport(UIKit) && DEBUG": ConditionalState.FALSE,
            "DEBUG || targetEnvironment(simulator)": ConditionalState.UNKNOWN,
            "(DEBUG && canImport(UIKit)) || os(iOS)": ConditionalState.UNKNOWN,
            "swift(>=6)": ConditionalState.UNKNOWN,
            "compiler(>=6) && DEBUG": ConditionalState.FALSE,
        }
        for expression, expected in cases.items():
            with self.subTest(expression=expression):
                self.assertIs(lexer.evaluate_condition(expression), expected)

    def test_cumulative_if_elseif_else_and_nested_guards(self) -> None:
        source = """
#if feature
let first = 1
#elseif DEBUG
let debugElseIf = 2
#else
let possibleElse = 3
#endif
#if feature
  #if DEBUG
  let nestedDebug = 4
  #else
  let nestedPossible = 5
  #endif
#endif
"""
        states = {
            token.value: token.condition
            for token in lexer.tokenize(source)
            if token.kind is TokenKind.IDENTIFIER and token.value.startswith(("first", "debug", "possible", "nested"))
        }

        self.assertIs(states["first"], ConditionalState.UNKNOWN)
        self.assertIs(states["debugElseIf"], ConditionalState.FALSE)
        self.assertIs(states["possibleElse"], ConditionalState.UNKNOWN)
        self.assertIs(states["nestedDebug"], ConditionalState.FALSE)
        self.assertIs(states["nestedPossible"], ConditionalState.UNKNOWN)

    def test_debug_else_is_release_possible(self) -> None:
        source = """
#if DEBUG
let debugOnly = "--uitesting"
#else
let releasePath = "--uitesting"
#endif
"""
        segments = [
            token for token in lexer.tokenize(source) if token.kind is TokenKind.STRING_SEGMENT
        ]

        self.assertEqual(len(segments), 2)
        self.assertIs(segments[0].condition, ConditionalState.FALSE)
        self.assertIs(segments[1].condition, ConditionalState.TRUE)

    def test_preview_index_and_comment_pounds_are_not_directives(self) -> None:
        source = """
#Preview("name") { Text("preview") }
#Index<Model>([\\.value])
// #if DEBUG
let live = 1
"""
        tokens = lexer.tokenize(source)
        identifiers = [token.value for token in tokens if token.kind is TokenKind.IDENTIFIER]

        self.assertIn("Preview", identifiers)
        self.assertIn("Index", identifiers)
        self.assertIn("live", identifiers)
        self.assertTrue(all(token.condition is ConditionalState.TRUE for token in tokens))

    def test_normal_multiline_raw_and_unicode_escaped_strings(self) -> None:
        source = r'''
let normal = "--uitesting"
let multiline = """first
--ui-test-multiline"""
let raw = ##"--ui-test-raw"##
let rawMultiline = #"""raw
--ui-test-raw-multiline"""#
let escaped = "\u{2d}\u{2d}uitesting"
'''
        segments = [
            token.value
            for token in lexer.tokenize(source)
            if token.kind is TokenKind.STRING_SEGMENT
        ]

        self.assertIn("--uitesting", segments)
        self.assertIn("first\n--ui-test-multiline", segments)
        self.assertIn("--ui-test-raw", segments)
        self.assertIn("raw\n--ui-test-raw-multiline", segments)
        self.assertEqual(segments.count("--uitesting"), 2)

    def test_recursive_interpolation_code_is_tokenized(self) -> None:
        source = r'let value = "before \(outer("nested \(inner)")) after"'
        tokens = lexer.tokenize(source)
        identifiers = [token.value for token in tokens if token.kind is TokenKind.IDENTIFIER]
        segments = [token.value for token in tokens if token.kind is TokenKind.STRING_SEGMENT]

        self.assertIn("outer", identifiers)
        self.assertIn("inner", identifiers)
        self.assertIn("before ", segments)
        self.assertIn("nested ", segments)
        self.assertIn(" after", segments)

    def test_raw_interpolation_requires_matching_pounds(self) -> None:
        source = r'let value = #"literal \(ignored) code \#(active)"#'
        tokens = lexer.tokenize(source)
        identifiers = [token.value for token in tokens if token.kind is TokenKind.IDENTIFIER]
        segments = [token.value for token in tokens if token.kind is TokenKind.STRING_SEGMENT]

        self.assertNotIn("ignored", identifiers)
        self.assertIn("active", identifiers)
        self.assertIn(r"literal \(ignored) code ", segments)

    def test_interpolation_inherits_enclosing_condition(self) -> None:
        source = """
#if DEBUG
let value = "\\(ProcessInfo.processInfo.arguments)"
#endif
"""
        process_info = next(
            token for token in lexer.tokenize(source) if token.value == "ProcessInfo"
        )
        self.assertIs(process_info.condition, ConditionalState.FALSE)

    def test_directive_comments_are_accepted(self) -> None:
        source = """
#if DEBUG /* nested /* comment */ done */
let debug = 1
#else // release
let release = 2
#endif /* done */
"""
        states = {
            token.value: token.condition
            for token in lexer.tokenize(source)
            if token.value in ("debug", "release")
        }
        self.assertIs(states["debug"], ConditionalState.FALSE)
        self.assertIs(states["release"], ConditionalState.TRUE)

    def test_structural_errors_are_deterministic(self) -> None:
        cases = {
            "unterminated comment": "/* open",
            "unexpected comment close": "*/",
            "unterminated normal string": 'let x = "open',
            "newline in normal string": 'let x = "open\nclose"',
            "unterminated raw string": 'let x = ##"open"#',
            "unterminated interpolation": 'let x = "\\(call("',
            "unterminated backtick": "let `class = 1",
            "missing endif": "#if DEBUG\nlet x = 1",
            "orphan elseif": "#elseif DEBUG\nlet x = 1",
            "orphan else": "#else\nlet x = 1",
            "orphan endif": "#endif",
            "duplicate else": "#if DEBUG\n#else\n#else\n#endif",
            "elseif after else": "#if DEBUG\n#else\n#elseif feature\n#endif",
            "trailing else junk": "#if DEBUG\n#else junk\n#endif",
            "trailing endif junk": "#if DEBUG\n#endif junk",
            "missing atom": "#if DEBUG &&\n#endif",
            "empty invocation": "#if os()\n#endif",
            "unbalanced invocation": "#if canImport(UIKit\n#endif",
            "trailing condition": "#if DEBUG unknown\n#endif",
        }
        for name, source in cases.items():
            with self.subTest(name=name):
                with self.assertRaises(SwiftLexicalError) as first:
                    lexer.tokenize(source)
                with self.assertRaises(SwiftLexicalError) as second:
                    lexer.tokenize(source)
                self.assertEqual(str(first.exception), str(second.exception))
                self.assertGreaterEqual(first.exception.line, 1)
                self.assertGreaterEqual(first.exception.column, 1)


if __name__ == "__main__":
    unittest.main()
