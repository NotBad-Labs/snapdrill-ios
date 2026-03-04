#!/bin/bash

# Check if SwiftLint is installed
if which swiftlint >/dev/null; then
  swiftlint --strict
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
