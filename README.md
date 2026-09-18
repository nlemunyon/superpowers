# superpowers (trimmed)

Private fork of [obra/superpowers](https://github.com/obra/superpowers),
cut down to Claude Code + Codex and hardened for a build → fix → ship
loop that doesn't rely on a model just behaving.

## What's different from upstream

- **Named roles with real tool restrictions**, not prose asking nicely:
  `explorer`, `implementer`, `verifier`, `reviewer` in `.claude/agents/`
  (frontmatter `tools:`/`disallowedTools:`, enforced by Claude Code's tool
  schema) and `.codex/agents/*.toml` (enforced by `sandbox_mode`). The
  three read-only roles are additionally backed by
  `.claude/hooks/readonly-guard`, a `PreToolUse` hook that blocks
  mutating Bash commands and any Write/Edit outside `.superpowers/`.
- **A required `Done when` block** on every plan task (`writing-plans`),
  re-run from scratch by a fresh `verifier` subagent before the task
  reviewer ever sees the diff (`subagent-driven-development`,
  `verifier-prompt.md`). The agent that writes the fix is never the one
  that verifies it.
- **`skills/fixing-bugs`**: a read-only `explorer` isolates the root
  cause, the `implementer` writes a failing reproduction *before* any
  fix, a fresh `verifier` re-runs everything — including a
  docker-compose end-to-end stage when one exists — and a `reviewer`
  checks the diff. Capped at 3 fix rounds; round 3 still failing means
  stop and question the architecture, not try again.
- **`skills/shipping`**: `scripts/preflight.sh` runs the same checks the
  remote pipeline will (CI config lint, local GitLab CI jobs via
  `gitlab-ci-local`, tests) before anything gets pushed. `hooks/pre-push`
  blocks direct pushes to protected branches and any non-fast-forward
  push without an explicit override. The skill then watches the
  pipeline, triages failures, works merge-request review comments, and
  sets auto-merge only when told to.

## Install

```bash
scripts/install.sh /path/to/repo
```

This is the only install path in this fork — copies `skills/` into
`.agents/skills/` (symlinked from `.claude/skills/`), the four agent
roles into `.claude/agents/` and `.codex/agents/`, the readonly-guard
hook, `preflight.sh` into `.agents/scripts/`, and `pre-push` into
`.git/hooks/`. Appends a bootstrap block to `AGENTS.md`/`CLAUDE.md` if
one isn't already there.

Optional tools: `glab`, `gitlab-ci-local`, `docker compose`.

## Codex setup

Enable multi-agent dispatch in `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Without this, the spawn/message/wait tools aren't in the model's tool
schema at all — the roles in `.codex/agents/` exist on disk but nothing
can reach them. With it on, roles are spawned by name from within a
session, e.g. "Have verifier check Task 2."

Recommended backstop, same file, so a spawn that omits a model doesn't
silently inherit the session's most expensive one:

```toml
[agents]
default_subagent_model = "<a mid-tier model from your spawn allowlist>"
default_subagent_reasoning_effort = "medium"
```

See `skills/using-superpowers/references/codex-tools.md` for dispatch,
waiting, and model-routing details.

## A caveat worth knowing before you trust this

`readonly-guard` matches command *text*, not intent — it stops a model
that's casually drifting out of its lane (a reviewer fixing a typo it
noticed), not one spelled around with an absolute path, a wrapper shell,
or a different interpreter entirely. The Codex side is stronger by
construction: `sandbox_mode = "read-only"` is enforced by the OS, not by
reading strings, so a write fails there regardless of how the command is
spelled. Treat the hook as a tripwire for cooperative agents, not a
security boundary — for that, use sandboxing.

## Layout

```
skills/                 workflows: using-superpowers (bootstrap),
                         brainstorming → writing-plans →
                         subagent-driven-development (build),
                         fixing-bugs, shipping, plus TDD/debugging/
                         review/worktree/finishing-branch support skills
.claude/agents/*.md      explorer, implementer, verifier, reviewer
.claude/hooks/           readonly-guard (PreToolUse)
.codex/agents/*.toml     the same four roles, sandbox_mode-enforced
scripts/preflight.sh     CI lint + local pipeline + tests
scripts/install.sh       vendor everything into a target repo
hooks/pre-push           protected-branch + force-push guard, runs
                         preflight --quick
```
