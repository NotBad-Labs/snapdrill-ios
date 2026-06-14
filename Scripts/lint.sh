#!/usr/bin/env bash

set -euo pipefail

if ! command -v swiftlint >/dev/null; then
  echo "error: SwiftLint not installed. Install it with: brew install swiftlint" >&2
  exit 1
fi

swiftlint --strict
