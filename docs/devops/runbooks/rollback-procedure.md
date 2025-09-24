# Rollback Procedure

Preconditions

- Broken build or critical regression after release

Steps

1. Create a revert PR for the release merge commit on `main`
2. Disable rollout or pull the release if applicable
3. Communicate status in CHANGELOG and PR
4. Open an incident entry and schedule a post-mortem
