# Release Process (Git Flow)

Goal

Ensure safe, repeatable releases with tags and notes, without direct pushes to `main`.

Flow

- Create/refresh `release/x.y.z` from `develop`
- Open PR: `main ← release/x.y.z` (require self-hosted checks)
- When green, merge via merge commit
- Tag `vX.Y.Z` on `main` and push; publish GitHub Release with `docs/releases/X.Y.Z.md`

Checks

- NotBad CI/CD Pipeline (Self-hosted)
- Policy - No GitHub-hosted runners on auto-triggered workflows

Rollback

- If broken, revert merge on `main`; or cut hotfix from `main` to patch
