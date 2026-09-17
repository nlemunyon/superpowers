# Superpowers (trimmed fork)

Fork of obra/superpowers, cut to Claude Code + Codex, with enforced
subagent roles and a shipping workflow. Upstream: https://github.com/obra/superpowers

## Layout

- `skills/` — the workflows. Entry points: `using-superpowers` (bootstrap),
  `brainstorming` → `writing-plans` → `subagent-driven-development` (build),
  `fixing-bugs` (fix), `shipping` (push/MR/merge).
- `.claude/agents/` — Claude Code roles: explorer, implementer, verifier, reviewer.
  Tool allowlists in frontmatter; `.claude/hooks/readonly-guard` blocks writes
  for read-only roles.
- `.codex/agents/` — the same roles as Codex TOML (`sandbox_mode` does the guarding).
- `scripts/preflight.sh` — CI lint + local pipeline + tests. `hooks/pre-push` runs it.
- `scripts/install.sh TARGET` — vendor everything into a repo (no marketplace needed).

## Working on this repo

- Skills are behavior code. Change wording only with a reason you can state.
- Keep `.claude/agents/*.md` and `.codex/agents/*.toml` in sync; the TOML
  body is the .md body minus frontmatter.
- Shell: `scripts/lint-shell.sh`. Tests: `tests/`.
- Upstream sync: `git fetch upstream && git merge upstream/main`, then re-apply
  the trim (see git log for what was removed).
