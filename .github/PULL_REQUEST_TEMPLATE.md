## Result

<!-- 用户或仓库最终能观察到什么？ -->

## Baseline

- Base: `origin/develop@<full-sha>`
- Head: `<full-sha>`
- Worktree / branch:
- PRD / architecture / data / defect oracle:

## Scope

-

## Not changed

-

## Validation

- Level: T1 / T2 / T3 / T4
- Commands actually run:
- UI / AX / device / release evidence:
- Not run / remaining risk:

## Checklist

- [ ] 主 checkout 未修改，独立 worktree 无无关脏文件
- [ ] `git diff --check`
- [ ] `python3 Scripts/validate_docs.py --check`
- [ ] T2+ 已运行 `bash Scripts/check.sh`
- [ ] T3 已运行 affected UI / AX 并附截图
- [ ] T4 已覆盖 failure paths、clean routine check 和设备 / 发布证据
- [ ] 没有顺手修改无关标识符、wire、schema、签名或发布资源

Draft、Ready 和绿色 CI 都不等于合并授权。每次 merge 仍需 PO 对当前精确 head 明确授权。
