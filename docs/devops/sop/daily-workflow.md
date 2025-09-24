# Daily Workflow SOP

Morning

- [ ] Check CI status
- [ ] Review coverage trend
- [ ] Review/triage PRs and issues

Development

1. Create feature branch
2. Write tests (TDD)
3. Implement feature
4. Run `zsh Scripts/check-quality.sh`
5. Push and open PR to develop

Release

1. Create release branch from develop
2. Update version and notes
3. Run full test suite
4. Merge release PR to main
5. Tag and publish Release
