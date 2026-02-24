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
mkdir -p .git/hooks
cp Scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "🎉 Setup Complete! Happy Coding!"
