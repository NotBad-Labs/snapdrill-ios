# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [6.0.1] - 2025-09-24 (Unreleased)

### Added — Coverage and Docs

- Targeted test suites to safely raise overall coverage to 70.01% (logic-only 93.63%)
- Coverage artifacts and documentation updates (milestones, snapshot JSON)
- DEBUG-only test hooks for view-layer code paths (no impact on release builds)

### Changed — CI and Badges

- Local CI script improvements: parallel testing defaults, configurable destination/workers, optional markdownlint skip
- README badges updated to reflect latest coverage metrics

### Notes

- No production behavior changes; this is a quality/coverage uplift release.
- Intended to be released after integrating `feature/navigation-coordinator` → `develop` and promoting to a short-lived `release/6.0.1` branch.

## [6.0.0] - 2025-09-19 (Build 1)

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
