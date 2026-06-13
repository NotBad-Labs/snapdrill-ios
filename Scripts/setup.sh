#!/bin/bash

echo "🚀 Setting up SnapDrill Development Environment..."

# 1. Check Homebrew
if ! which brew >/dev/null; then
    echo "❌ Homebrew not found. Please install it first."
    exit 1
fi

# 2. Install Tools
echo "🛠 Checking tools..."
if ! which swiftlint >/dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint
else
    echo "✅ SwiftLint already installed."
fi

# 3. Install Git Hooks
echo "🪝 Installing Git Hooks..."
hooks_dir=$(git rev-parse --git-path hooks 2>/dev/null) || {
    echo "❌ Not inside a Git repository."
    exit 1
}
mkdir -p "$hooks_dir"
cp Scripts/pre-commit "$hooks_dir/pre-commit"
chmod +x "$hooks_dir/pre-commit"

echo "🎉 Setup Complete! Happy Coding!"
