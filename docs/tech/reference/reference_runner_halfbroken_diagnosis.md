---
last_verified: 2026-05-19
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [infra_change]
---
# Mac mini Runner 诊断与修复

> GitHub Actions self-hosted runner 进程存活但 GitHub 侧显示 offline 的诊断流程。

## 诊断

```bash
ssh admin@192.168.1.224
ps aux | grep -i runner
```

## 修复

```bash
cd ~/actions-runner
./svc.sh stop
./svc.sh start
```

## 症状

- Runner 进程存活但 GitHub 显示 offline
- CI job 永久 QUEUED
