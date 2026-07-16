#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "${BASH_SOURCE[0]%/*}" && pwd -P)"
cd "$script_dir/.."

if ! command -v swiftlint >/dev/null 2>&1; then
  printf '%s\n' "error: SwiftLint not installed; run Scripts/setup.sh" >&2
  exit 1
fi

swiftlint --strict
