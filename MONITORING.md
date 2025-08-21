# Monitoring Setup

## How it works

1. **Dependabot** checks daily for Claude Code updates in `/monitor/package.json`
2. When new version found → Dependabot opens PR
3. **GitHub Action** tests if patches still work
4. If patches work → PR auto-closes
5. If patches broken → PR stays open with "patches-broken" label

That's it! The open Dependabot PR *is* your issue tracker.

## Manual test
Go to Actions → Test Patches → Run workflow