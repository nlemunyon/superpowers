# superpowers (trimmed)

Skills and subagent roles for Claude Code and Codex. Fork of
[obra/superpowers](https://github.com/obra/superpowers) with:

- Named roles with enforced tool sets: `explorer`, `implementer`,
  `verifier`, `reviewer`
- A **Done when** block on every task, re-run by a fresh verifier
- `fixing-bugs`: isolate → failing test → fix → verify (incl. docker
  compose e2e) → review
- `shipping`: preflight → rebase → push → watch pipeline → review
  comments → auto-merge (GitLab first, GitHub table)
- Everything else from upstream not needed for those two harnesses removed

## Install

Vendored (works behind blocked marketplaces):

```bash
scripts/install.sh /path/to/repo
```

Claude Code plugin (personal use): add this directory as a local
marketplace and install `superpowers`.

Optional tools: `glab`, `gitlab-ci-local`, `docker compose`.

## Codex

Enable multi-agent in `~/.codex/config.toml` and set a default subagent
model; see `skills/using-superpowers/references/codex-tools.md`. Roles
in `.codex/agents/` are spawned by name ("Have verifier check Task 2").
