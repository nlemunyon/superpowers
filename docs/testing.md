# Testing Superpowers

All tests live under `tests/` and run against Claude Code and/or Codex —
bash + Python integration tests, no LLM-judging harness.

- `tests/claude-code/` — headless `claude -p` tests that skills load and are
  followed correctly. `run-skill-tests.sh` runs the fast suite;
  `run-skill-tests.sh --integration` runs the slow (10-30 min) ones. See
  `tests/claude-code/README.md`.
- `tests/codex/` — codex plugin manifest and packaging checks
  (`test-marketplace-manifest.sh`, `test-package-codex-plugin.sh`).
- `tests/hooks/` — `hooks/session-start` output-shape tests for Claude Code
  and Copilot CLI.
- `tests/explicit-skill-requests/` — Haiku-specific, multi-turn, and
  skill-name-prompted tests.
- `tests/shell-lint/` — shell script lint checks.
- `tests/systematic-debugging/` — `find-polluter` behavior tests.
- `tests/writing-skills/` — graph-rendering tests for the writing-skills skill.

Run an individual suite directly, e.g.:

```bash
bash tests/hooks/test-session-start.sh
bash tests/codex/test-package-codex-plugin.sh
```

or via each directory's own `run-*.sh` where present.
