# NotBad Quality Dashboard

Generated: 2025-09-24 13:32:30

## Coverage Summary

- Overall coverage: 70.01% (8665/12377 lines)
- Logic-only coverage (Views excluded): 94.17% (8035/8532 lines)
- Coverage JSON mtime: 2025-09-24 13:23:24

## Recent Coverage Trend (overall)

| Snapshot | Coverage |
|---|---:|
| 2025-09-23 16:07:07 | 64.54% |
| 2025-09-23 16:09:05 | 64.54% |
| 2025-09-23 16:17:17 | 65.10% |
| 2025-09-23 16:29:44 | 65.09% |
| 2025-09-23 16:45:22 | 65.12% |
| 2025-09-23 17:25:38 | 65.38% |
| 2025-09-23 22:34:42 | 68.25% |
| 2025-09-24 09:58:59 | 0.00% |
| 2025-09-24 12:04:39 | 70.01% |
| 2025-09-24 13:23:25 | 70.01% |

## How to regenerate

1. Run unit tests via the quality script to produce coverage:
   - `zsh Scripts/check-quality.sh`
2. Generate this dashboard:
   - `zsh Scripts/generate-dashboard.sh`

## Recent Commits (last 5)

- a38e1a9 chore(quality): add coverage dashboard generator and wire into CI; fix rollback runbook spacing
- 23d870e chore(ci): prune legacy workflows — keep only self-hosted pipeline & guard policy
- b518bbd chore(ci): finalize fully self-hosted posture — disable auxiliary workflows and keep only self-hosted pipeline active
- 72e79bf ci(policy): enforce no GitHub-hosted runners on auto-triggered workflows; manual-only hosted jobs remain allowed
- c089a8b ci: disable GitHub-hosted iOS CI auto-triggers (manual-only) to avoid billing failures; keep self-hosted pipeline as the source of truth
