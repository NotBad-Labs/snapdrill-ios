# Hotfix Guide

When critical issues occur in production:

Flow

- Branch from `main`: `hotfix/x.y.(z+1)`
- Patch with tests; run local/CI gates
- PR: `main ← hotfix/x.y.(z+1)`; merge when green
- Back-merge `main` ← `develop`
