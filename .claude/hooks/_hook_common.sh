#!/bin/bash
# Shared helpers for Claude Code hooks.

require_command() {
    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "hook dependency missing: $cmd" >&2
        echo "Install '$cmd' or remove/disable the hook that requires it." >&2
        exit 1
    fi
}
