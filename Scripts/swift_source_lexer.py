#!/usr/bin/env python3
"""Bounded, policy-neutral Swift source lexer with conditional-compilation facts.

This is deliberately not a Swift parser. It removes comments and whitespace,
emits the lexical facts needed by repository policy checks, and fails closed on
malformed strings, interpolation, comments, or conditional directives.
"""
from __future__ import annotations

import bisect
from enum import Enum
from typing import List, NamedTuple, Optional, Sequence


class ConditionalState(Enum):
    """Three-valued reachability under a Release build where DEBUG is false."""

    TRUE = "true"
    FALSE = "false"
    UNKNOWN = "unknown"


class TokenKind(Enum):
    IDENTIFIER = "identifier"
    STRING_SEGMENT = "string-segment"
    PUNCTUATION = "punctuation"


class SourceToken(NamedTuple):
    kind: TokenKind
    value: str
    offset: int
    end_offset: int
    line: int
    column: int
    condition: ConditionalState


class SwiftLexicalError(ValueError):
    """A deterministic structural error carrying its source location."""

    def __init__(self, message: str, offset: int, line: int, column: int) -> None:
        super().__init__(f"{message} at {line}:{column} (offset {offset})")
        self.message = message
        self.offset = offset
        self.line = line
        self.column = column


def condition_not(value: ConditionalState) -> ConditionalState:
    if value is ConditionalState.TRUE:
        return ConditionalState.FALSE
    if value is ConditionalState.FALSE:
        return ConditionalState.TRUE
    return ConditionalState.UNKNOWN


def condition_and(left: ConditionalState, right: ConditionalState) -> ConditionalState:
    if left is ConditionalState.FALSE or right is ConditionalState.FALSE:
        return ConditionalState.FALSE
    if left is ConditionalState.TRUE and right is ConditionalState.TRUE:
        return ConditionalState.TRUE
    return ConditionalState.UNKNOWN


def condition_or(left: ConditionalState, right: ConditionalState) -> ConditionalState:
    if left is ConditionalState.TRUE or right is ConditionalState.TRUE:
        return ConditionalState.TRUE
    if left is ConditionalState.FALSE and right is ConditionalState.FALSE:
        return ConditionalState.FALSE
    return ConditionalState.UNKNOWN


class _ConditionToken(NamedTuple):
    value: str
    offset: int


def _is_identifier_start(character: str) -> bool:
    return character == "_" or character.isalpha()


def _is_identifier_continue(character: str) -> bool:
    return character == "_" or character.isalnum()


def _tokenize_condition(expression: str) -> List[_ConditionToken]:
    tokens: List[_ConditionToken] = []
    index = 0
    while index < len(expression):
        character = expression[index]
        if character.isspace():
            index += 1
            continue
        if expression.startswith("&&", index) or expression.startswith("||", index):
            tokens.append(_ConditionToken(expression[index : index + 2], index))
            index += 2
            continue
        if character in "!()":
            tokens.append(_ConditionToken(character, index))
            index += 1
            continue
        if _is_identifier_start(character):
            end = index + 1
            while end < len(expression) and _is_identifier_continue(expression[end]):
                end += 1
            tokens.append(_ConditionToken(expression[index:end], index))
            index = end
            continue
        tokens.append(_ConditionToken(character, index))
        index += 1
    return tokens


class _ConditionParser:
    def __init__(self, expression: str) -> None:
        self.expression = expression
        self.tokens = _tokenize_condition(expression)
        self.index = 0

    def parse(self) -> ConditionalState:
        if not self.tokens:
            raise ValueError("missing conditional-compilation expression")
        result = self._parse_or()
        if self.index != len(self.tokens):
            token = self.tokens[self.index]
            raise ValueError(
                f"trailing conditional-compilation token {token.value!r} "
                f"at expression offset {token.offset}"
            )
        return result

    def _parse_or(self) -> ConditionalState:
        result = self._parse_and()
        while self._accept("||"):
            result = condition_or(result, self._parse_and())
        return result

    def _parse_and(self) -> ConditionalState:
        result = self._parse_unary()
        while self._accept("&&"):
            result = condition_and(result, self._parse_unary())
        return result

    def _parse_unary(self) -> ConditionalState:
        if self._accept("!"):
            return condition_not(self._parse_unary())
        if self._accept("("):
            result = self._parse_or()
            self._expect(")")
            return result
        return self._parse_atom()

    def _parse_atom(self) -> ConditionalState:
        token = self._peek()
        if token is None or not _is_identifier_start(token.value[0]):
            value = "end of expression" if token is None else repr(token.value)
            raise ValueError(f"expected condition atom, found {value}")
        self.index += 1
        has_invocation = False
        if self._accept("("):
            has_invocation = True
            depth = 1
            payload_count = 0
            while self.index < len(self.tokens) and depth:
                current = self.tokens[self.index]
                self.index += 1
                if current.value == "(":
                    depth += 1
                elif current.value == ")":
                    depth -= 1
                if depth:
                    payload_count += 1
            if depth:
                raise ValueError(f"unterminated invocation for condition atom {token.value!r}")
            if payload_count == 0:
                raise ValueError(f"empty invocation for condition atom {token.value!r}")
        if token.value == "DEBUG" and not has_invocation:
            return ConditionalState.FALSE
        return ConditionalState.UNKNOWN

    def _peek(self) -> Optional[_ConditionToken]:
        if self.index >= len(self.tokens):
            return None
        return self.tokens[self.index]

    def _accept(self, value: str) -> bool:
        token = self._peek()
        if token is None or token.value != value:
            return False
        self.index += 1
        return True

    def _expect(self, value: str) -> None:
        if not self._accept(value):
            token = self._peek()
            found = "end of expression" if token is None else repr(token.value)
            raise ValueError(f"expected {value!r}, found {found}")


def evaluate_condition(expression: str) -> ConditionalState:
    """Evaluate one Swift compilation condition for a Release proof."""

    return _ConditionParser(expression).parse()


class _ConditionalFrame(NamedTuple):
    parent: ConditionalState
    prior_branches: ConditionalState
    saw_else: bool
    offset: int


class _Lexer:
    _DIRECTIVES = ("#elseif", "#endif", "#else", "#if")

    def __init__(self, source: str) -> None:
        self.source = source
        self.index = 0
        self.tokens: List[SourceToken] = []
        self.condition = ConditionalState.TRUE
        self.frames: List[_ConditionalFrame] = []
        self.line_starts = [0]
        self.line_starts.extend(index + 1 for index, char in enumerate(source) if char == "\n")

    def tokenize(self) -> List[SourceToken]:
        self._scan_code(interpolation_depth=None)
        if self.frames:
            frame = self.frames[-1]
            self._error("unterminated conditional-compilation block", frame.offset)
        return self.tokens

    def _scan_code(self, interpolation_depth: Optional[int]) -> None:
        depth = interpolation_depth
        while self.index < len(self.source):
            if self.source.startswith("//", self.index):
                self._skip_line_comment()
                continue
            if self.source.startswith("/*", self.index):
                self._skip_block_comment()
                continue
            if self.source.startswith("*/", self.index):
                self._error("unexpected block-comment terminator", self.index)
            directive = self._directive_at_current_position()
            if directive is not None:
                self._consume_directive(directive)
                continue
            string_pounds = self._string_pounds_at_current_position()
            if string_pounds is not None:
                self._scan_string(string_pounds)
                continue
            character = self.source[self.index]
            if character.isspace():
                self.index += 1
                continue
            if character == "`":
                self._scan_backticked_identifier()
                continue
            if _is_identifier_start(character):
                self._scan_identifier()
                continue

            token_offset = self.index
            self._emit(TokenKind.PUNCTUATION, character, token_offset, token_offset + 1)
            self.index += 1
            if depth is not None:
                if character == "(":
                    depth += 1
                elif character == ")":
                    depth -= 1
                    if depth == 0:
                        return
        if depth is not None:
            self._error("unterminated string interpolation", len(self.source))

    def _directive_at_current_position(self) -> Optional[str]:
        if self.source[self.index] != "#":
            return None
        line_start = self.source.rfind("\n", 0, self.index) + 1
        if any(character not in " \t" for character in self.source[line_start : self.index]):
            return None
        for directive in self._DIRECTIVES:
            if not self.source.startswith(directive, self.index):
                continue
            end = self.index + len(directive)
            if end < len(self.source) and _is_identifier_continue(self.source[end]):
                continue
            return directive
        return None

    def _consume_directive(self, directive: str) -> None:
        directive_offset = self.index
        line_end = self.source.find("\n", self.index)
        if line_end == -1:
            line_end = len(self.source)
        tail_offset = self.index + len(directive)
        tail = self._clean_directive_tail(self.source[tail_offset:line_end], tail_offset).strip()

        if directive in ("#if", "#elseif"):
            try:
                branch = evaluate_condition(tail)
            except ValueError as error:
                self._error(f"invalid {directive} expression: {error}", directive_offset)
        elif tail:
            self._error(f"trailing content after {directive}", directive_offset)

        if directive == "#if":
            self.frames.append(
                _ConditionalFrame(self.condition, branch, False, directive_offset)
            )
            self.condition = condition_and(self.condition, branch)
        elif directive == "#elseif":
            if not self.frames:
                self._error("#elseif without matching #if", directive_offset)
            frame = self.frames[-1]
            if frame.saw_else:
                self._error("#elseif after #else", directive_offset)
            guard = condition_and(condition_not(frame.prior_branches), branch)
            self.condition = condition_and(frame.parent, guard)
            self.frames[-1] = frame._replace(
                prior_branches=condition_or(frame.prior_branches, branch)
            )
        elif directive == "#else":
            if not self.frames:
                self._error("#else without matching #if", directive_offset)
            frame = self.frames[-1]
            if frame.saw_else:
                self._error("duplicate #else", directive_offset)
            self.condition = condition_and(
                frame.parent, condition_not(frame.prior_branches)
            )
            self.frames[-1] = frame._replace(saw_else=True)
        elif directive == "#endif":
            if not self.frames:
                self._error("#endif without matching #if", directive_offset)
            frame = self.frames.pop()
            self.condition = frame.parent
        self.index = line_end

    def _clean_directive_tail(self, tail: str, absolute_offset: int) -> str:
        result: List[str] = []
        index = 0
        while index < len(tail):
            if tail.startswith("//", index):
                break
            if tail.startswith("/*", index):
                start = index
                depth = 1
                index += 2
                while index < len(tail) and depth:
                    if tail.startswith("/*", index):
                        depth += 1
                        index += 2
                    elif tail.startswith("*/", index):
                        depth -= 1
                        index += 2
                    else:
                        index += 1
                if depth:
                    self._error(
                        "unterminated block comment in conditional directive",
                        absolute_offset + start,
                    )
                result.append(" ")
                continue
            result.append(tail[index])
            index += 1
        return "".join(result)

    def _skip_line_comment(self) -> None:
        line_end = self.source.find("\n", self.index + 2)
        self.index = len(self.source) if line_end == -1 else line_end

    def _skip_block_comment(self) -> None:
        start = self.index
        depth = 1
        self.index += 2
        while self.index < len(self.source) and depth:
            if self.source.startswith("/*", self.index):
                depth += 1
                self.index += 2
            elif self.source.startswith("*/", self.index):
                depth -= 1
                self.index += 2
            else:
                self.index += 1
        if depth:
            self._error("unterminated block comment", start)

    def _string_pounds_at_current_position(self) -> Optional[int]:
        cursor = self.index
        while cursor < len(self.source) and self.source[cursor] == "#":
            cursor += 1
        if cursor < len(self.source) and self.source[cursor] == '"':
            return cursor - self.index
        return None

    def _scan_string(self, pounds: int) -> None:
        start = self.index
        quote_offset = start + pounds
        multiline = self.source.startswith('"""', quote_offset)
        quote = '"""' if multiline else '"'
        self.index = quote_offset + len(quote)
        segment_start = self.index
        segment_value: List[str] = []
        emitted_segment = False
        escape_marker = "\\" + ("#" * pounds)
        closing = quote + ("#" * pounds)

        while self.index < len(self.source):
            if self.source.startswith(closing, self.index) and not (
                pounds and self.index + len(closing) < len(self.source)
                and self.source[self.index + len(closing)] == "#"
            ):
                self._emit_string_segment(
                    segment_start,
                    self.index,
                    "".join(segment_value),
                    force=not emitted_segment,
                )
                self.index += len(closing)
                return
            if self.source.startswith(escape_marker + "(", self.index):
                self._emit_string_segment(
                    segment_start, self.index, "".join(segment_value), force=False
                )
                emitted_segment = True
                open_paren = self.index + len(escape_marker)
                self.index = open_paren
                self._scan_code(interpolation_depth=0)
                segment_start = self.index
                segment_value = []
                continue
            if self.source.startswith(escape_marker, self.index):
                decoded, end = self._decode_escape(self.index, escape_marker, multiline)
                segment_value.append(decoded)
                self.index = end
                continue
            character = self.source[self.index]
            if character == "\n" and not multiline:
                self._error("newline in single-line string literal", self.index)
            segment_value.append(character)
            self.index += 1
        self._error("unterminated string literal", start)

    def _decode_escape(self, offset: int, marker: str, multiline: bool) -> tuple[str, int]:
        cursor = offset + len(marker)
        if cursor >= len(self.source):
            self._error("unterminated string escape", offset)
        character = self.source[cursor]
        escapes = {
            "0": "\0",
            "n": "\n",
            "r": "\r",
            "t": "\t",
            '"': '"',
            "'": "'",
            "\\": "\\",
        }
        if character in escapes:
            return escapes[character], cursor + 1
        if character == "u":
            opening = cursor + 1
            if opening >= len(self.source) or self.source[opening] != "{":
                self._error("malformed Unicode string escape", offset)
            closing = self.source.find("}", opening + 1)
            if closing == -1:
                self._error("unterminated Unicode string escape", offset)
            digits = self.source[opening + 1 : closing].replace("_", "")
            try:
                if not digits:
                    raise ValueError
                value = chr(int(digits, 16))
            except (ValueError, OverflowError):
                self._error("invalid Unicode string escape", offset)
            return value, closing + 1
        if character == "\n" and multiline:
            cursor += 1
            while cursor < len(self.source) and self.source[cursor] in " \t":
                cursor += 1
            return "", cursor
        self._error(f"unsupported string escape {character!r}", offset)
        raise AssertionError("unreachable")

    def _emit_string_segment(
        self, start: int, end: int, value: str, force: bool
    ) -> None:
        if value or force:
            self._emit(TokenKind.STRING_SEGMENT, value, start, end)

    def _scan_backticked_identifier(self) -> None:
        start = self.index
        closing = self.source.find("`", start + 1)
        if closing == -1 or "\n" in self.source[start + 1 : closing]:
            self._error("unterminated backticked identifier", start)
        value = self.source[start + 1 : closing]
        if not value:
            self._error("empty backticked identifier", start)
        self._emit(TokenKind.IDENTIFIER, value, start, closing + 1)
        self.index = closing + 1

    def _scan_identifier(self) -> None:
        start = self.index
        self.index += 1
        while self.index < len(self.source) and _is_identifier_continue(
            self.source[self.index]
        ):
            self.index += 1
        self._emit(
            TokenKind.IDENTIFIER,
            self.source[start : self.index],
            start,
            self.index,
        )

    def _emit(self, kind: TokenKind, value: str, start: int, end: int) -> None:
        line, column = self._location(start)
        self.tokens.append(
            SourceToken(kind, value, start, end, line, column, self.condition)
        )

    def _location(self, offset: int) -> tuple[int, int]:
        line_index = bisect.bisect_right(self.line_starts, offset) - 1
        return line_index + 1, offset - self.line_starts[line_index] + 1

    def _error(self, message: str, offset: int) -> None:
        line, column = self._location(min(offset, len(self.source)))
        raise SwiftLexicalError(message, offset, line, column)


def tokenize(source: str) -> List[SourceToken]:
    """Tokenize source and attach cumulative Release reachability to each token."""

    if not isinstance(source, str):
        raise TypeError("source must be str")
    return _Lexer(source).tokenize()


__all__: Sequence[str] = (
    "ConditionalState",
    "SourceToken",
    "SwiftLexicalError",
    "TokenKind",
    "condition_and",
    "condition_not",
    "condition_or",
    "evaluate_condition",
    "tokenize",
)
