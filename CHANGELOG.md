# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [6.0.0] - 2025-09-19

### Added

- Documentation governance: markdownlint, link-check, docs consistency checker
- CI workflows targeting develop and release branches; self-hosted iOS tests (iPhone 17 Pro / iOS 26)
- CONTRIBUTING, CODEOWNERS, PR template

### Changed

- Unified platform baseline to iOS 26 / Swift 6.2 / Xcode 26
- Adopt Git Flow (main ← release/\* ← develop ← feature/\*)

### Fixed

- Broken cross-links across PRD/TDD/RTM/Glossary
- Markdown lint issues (headings, spacing)
