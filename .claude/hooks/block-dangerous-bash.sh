#!/bin/bash
# PreToolUse (Bash): 阻塞危险命令类别。
# 匹配到 → exit 2 + stderr 提示。
#
# 定位：defense-in-depth 启发式，非 sandbox。静态分析挡「误操作 + 简单注入」，
# 挡不住运行时展开类（$VAR / 命令替换 $(...) / 反引号——只有执行才知道真值）——已知上限。
#
# 用户显式授权后绕过：设置环境变量 CLAUDE_HOOK_ALLOW_DANGEROUS=1

set -eo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

if [ "${CLAUDE_HOOK_ALLOW_DANGEROUS:-0}" = "1" ]; then
    exit 0
fi

require_command jq
require_command python3

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
    exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

CLASSIFICATION=$(python3 - "$COMMAND" "$CURRENT_BRANCH" <<'PY'
import codecs
import os
import re
import shlex
import sys

command = sys.argv[1]
current_branch = sys.argv[2] if len(sys.argv) > 2 else ""
protected = {
    branch.strip()
    for branch in os.environ.get(
        "CLAUDE_HOOK_PROTECTED_BRANCHES",
        "main master develop release production",
    ).split()
    if branch.strip()
}


def decode_ansi_c(source):
    # 解码 ANSI-C 引用 $'...'（含 \xNN/\NNN/\t 等转义）为普通 '...'，
    # 防 `bash -c $'rm -rf /'` / `bash -c $'rm\x20-rf\x20/'` 绕过静态分析。
    # 逐转义尽力解码：单个非法转义（如 \u123）不致整段退化（agy/deepseek review）。
    def decode_escape(esc_match):
        try:
            return codecs.decode(esc_match.group(0), "unicode_escape")
        except Exception:
            return esc_match.group(0)

    def repl(match):
        decoded = re.sub(r"\\(x[0-9A-Fa-f]{1,2}|[0-7]{1,3}|.)", decode_escape, match.group(1))
        return "'" + decoded.replace("'", "") + "'"
    return re.sub(r"\$'((?:[^'\\]|\\.)*)'", repl, source, flags=re.DOTALL)


def tokenize(source):
    source = decode_ansi_c(source)
    lexer = shlex.shlex(source, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def split_commands(tokens):
    commands = []
    current = []
    for token in tokens:
        if token in {";", "&&", "||", "|", "&", "(", ")"}:
            if current:
                commands.append(current)
                current = []
        else:
            current.append(token)
    if current:
        commands.append(current)
    return commands


def strip_assignment_wrappers(argv):
    argv = list(argv)
    while argv:
        command_name = os.path.basename(argv[0])
        if command_name in {"sudo", "command", "builtin", "noglob"}:
            argv = argv[1:]
            continue
        if command_name == "env":
            argv = argv[1:]
            while argv and (argv[0].startswith("-") or "=" in argv[0]):
                argv = argv[1:]
            continue
        while argv and "=" in argv[0] and not argv[0].startswith("-"):
            key = argv[0].split("=", 1)[0]
            if key.replace("_", "").isalnum() and not key[:1].isdigit():
                argv = argv[1:]
            else:
                break
        break
    return argv


def has_short_option(argv, option_char):
    return any(
        token.startswith("-")
        and not token.startswith("--")
        and option_char in token[1:]
        for token in argv
    )


def has_long_option(argv, names):
    return any(token in names or any(token.startswith(f"{name}=") for name in names) for token in argv)


def shell_command_string_arg(argv):
    for index, token in enumerate(argv[1:], start=1):
        if token.startswith("-") and not token.startswith("--") and "c" in token[1:]:
            if index + 1 < len(argv):
                return argv[index + 1]
            return None
    return None


def is_recursive_root_rm(argv):
    if not argv or os.path.basename(argv[0]) != "rm":
        return False

    recursive = False
    targets = []
    option_mode = True

    for token in argv[1:]:
        if option_mode and token == "--":
            option_mode = False
            continue
        if option_mode and token.startswith("-") and token != "-":
            if token in {"-r", "-R", "--recursive"}:
                recursive = True
            elif not token.startswith("--") and any(char in token[1:] for char in ("r", "R")):
                recursive = True
            continue
        option_mode = False
        targets.append(token)

    root_targets = {"/", "//", "/*"}
    return recursive and any(target in root_targets for target in targets)


def normalize_git_args(argv):
    if not argv or os.path.basename(argv[0]) != "git":
        return None, []

    args = argv[1:]
    while args:
        token = args[0]
        if token == "-C" and len(args) >= 2:
            args = args[2:]
            continue
        if token.startswith("-C") and token != "-C":
            args = args[1:]
            continue
        if token in {"-c", "--config-env"} and len(args) >= 2:
            args = args[2:]
            continue
        if token.startswith("-"):
            args = args[1:]
            continue
        break

    if not args:
        return None, []
    return args[0], args[1:]


def push_option_takes_value(token):
    return token in {
        "--repo",
        "--receive-pack",
        "--exec",
        "--push-option",
        "-o",
    }


def branch_name_from_refspec(refspec):
    refspec = refspec.lstrip("+")
    if ":" in refspec:
        _, destination = refspec.split(":", 1)
        candidate = destination or refspec.split(":", 1)[0]
    else:
        candidate = refspec
    if candidate.startswith("refs/heads/"):
        candidate = candidate[len("refs/heads/"):]  # 保留多段分支名（release/v1），不截成叶子
    return candidate


def is_force_push_to_protected_branch(args):
    force = False
    positionals = []
    skip_next = False

    for token in args:
        if skip_next:
            skip_next = False
            continue
        if token == "--":
            continue
        if token in {"--force", "--force-with-lease", "--force-if-includes"}:
            force = True
            continue
        if token.startswith("--force-with-lease="):
            force = True
            continue
        if token.startswith("--"):
            if push_option_takes_value(token):
                skip_next = True
            continue
        if token.startswith("-") and token != "-":
            if "f" in token[1:]:
                force = True
            if any(option in token[1:] for option in ("o",)):
                skip_next = True
            continue
        positionals.append(token)

    # + 前缀强推 refspec（位置无关；remote 名不以 + 开头）：直接判其目标分支，
    # 覆盖 'git push origin +main' / 'git push --repo origin +main'（remote 被 flag 吃掉）等
    plus_targets = {branch_name_from_refspec(p) for p in positionals if p.startswith("+")}
    if plus_targets & protected:
        return True

    if not force:
        return False

    refspecs = positionals[1:] if len(positionals) > 1 else []
    if not refspecs and current_branch:
        refspecs = [current_branch]
    if not refspecs:
        return True

    branches = {branch_name_from_refspec(refspec) for refspec in refspecs}
    return bool(branches & protected)


def classify(argv):
    argv = strip_assignment_wrappers(argv)
    if not argv:
        return None

    shell_name = os.path.basename(argv[0])
    if shell_name in {"bash", "sh", "zsh"}:
        command_string = shell_command_string_arg(argv)
        if command_string:
            nested = analyze(command_string)
            if nested:
                return nested

    if is_recursive_root_rm(argv):
        return "recursive root rm"

    git_command, git_args = normalize_git_args(argv)
    if git_command == "push" and is_force_push_to_protected_branch(git_args):
        return "force push to protected branch"
    if git_command == "reset" and has_long_option(git_args, {"--hard"}):
        return "git reset hard"
    if git_command == "clean" and has_short_option(git_args, "f") and (
        has_short_option(git_args, "d") or has_short_option(git_args, "x")
    ):
        return "destructive git clean"
    if git_command == "branch" and any(token == "-D" or (token.startswith("-") and "D" in token[1:]) for token in git_args):
        return "force delete git branch"
    return None


def analyze(source):
    # 先按换行切（shlex 把换行当普通空白吞掉，否则 'true\nrm -rf /' 会并成一条命令绕过，codex review）
    for segment in source.split("\n"):
        try:
            tokens = tokenize(segment)
        except ValueError:
            continue
        for argv in split_commands(tokens):
            classification = classify(argv)
            if classification:
                return classification
    return None


result = analyze(command)
if result:
    print(result)
PY
)

if [ -n "$CLASSIFICATION" ]; then
    echo "拦截危险命令：" >&2
    echo "  $COMMAND" >&2
    echo "" >&2
    echo "危险类别：$CLASSIFICATION" >&2
    echo "如确需执行，请让用户在终端直接运行；或让用户显式授权后" >&2
    echo "通过 CLAUDE_HOOK_ALLOW_DANGEROUS=1 环境变量绕过。" >&2
    exit 2
fi

exit 0
