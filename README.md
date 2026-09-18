# superpowers (trimmed fork)

Superpowers is a complete software development methodology for your coding
agent, built on a set of composable skills and instructions that make sure
the agent actually uses them. This is a private fork trimmed to Claude Code
and Codex, with enforced subagent roles and a hardened build → fix → ship
loop layered on top.

## Table of Contents

- [How it works](#how-it-works)
- [What's different from upstream](#whats-different-from-upstream)
- [Installation](#installation)
  - [Claude Code](#claude-code)
  - [Codex](#codex)
- [The Basic Workflow](#the-basic-workflow)
- [What's Inside](#whats-inside)
- [Philosophy](#philosophy)
- [A caveat worth knowing before you trust this](#a-caveat-worth-knowing-before-you-trust-this)
- [Contributing](#contributing)
- [License](#license)

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees
that you're building something, it *doesn't* just jump into writing code.
Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in
chunks short enough to actually read and digest.

After you've signed off on the design, your agent puts together an
implementation plan that's clear enough for an enthusiastic junior engineer
with poor taste, no judgement, no project context, and an aversion to
testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna
Need It), and DRY.

Next up, once you say "go", it launches a *subagent-driven-development*
process, having agents work through each engineering task, inspecting and
reviewing their work, and continuing forward. In this fork, the agent that
writes a fix is never the one that verifies it — a fresh `verifier` subagent
re-runs everything from scratch before a task reviewer ever sees the diff.

There's a bunch more to it, but that's the core of the system. Because the
skills trigger automatically, you don't need to do anything special. Your
coding agent just has Superpowers.

## What's different from upstream

- **Named roles with real tool restrictions**, not prose asking nicely:
  `explorer`, `implementer`, `verifier`, `reviewer` in `.claude/agents/`
  (frontmatter `tools:`/`disallowedTools:`, enforced by Claude Code's tool
  schema) and `.codex/agents/*.toml` (enforced by `sandbox_mode`). The three
  read-only roles are additionally backed by `.claude/hooks/readonly-guard`,
  a `PreToolUse` hook that blocks mutating Bash commands and any Write/Edit
  outside `.superpowers/`.
- **A required `Done when` block** on every plan task (`writing-plans`),
  re-run from scratch by a fresh `verifier` subagent before the task
  reviewer ever sees the diff (`subagent-driven-development`,
  `verifier-prompt.md`).
- **`skills/fixing-bugs`**: a read-only `explorer` isolates the root cause,
  the `implementer` writes a failing reproduction *before* any fix, a fresh
  `verifier` re-runs everything — including a docker-compose end-to-end
  stage when one exists — and a `reviewer` checks the diff. Capped at 3 fix
  rounds; round 3 still failing means stop and question the architecture,
  not try again.
- **`skills/shipping`**: `scripts/preflight.sh` runs the same checks the
  remote pipeline will (CI config lint, local GitLab CI jobs via
  `gitlab-ci-local`, tests) before anything gets pushed. `hooks/pre-push`
  blocks direct pushes to protected branches and any non-fast-forward push
  without an explicit override. The skill then watches the pipeline,
  triages failures, works merge-request review comments, and sets
  auto-merge only when told to.
- Trimmed to only the harnesses this fork supports (Claude Code, Codex) and
  the one, vendored install path below — no plugin marketplace, no other
  coding agents.

## Installation

Installation differs by harness. If you use both, install separately for
each one.

### Claude Code

```bash
scripts/install.sh /path/to/repo
```

This vendors `skills/` into `.agents/skills/` (symlinked from
`.claude/skills/`), the four agent roles into `.claude/agents/`, the
`readonly-guard` hook into `.claude/hooks/`, and `preflight.sh` into
`.agents/scripts/`. It appends a bootstrap block to `CLAUDE.md` if one isn't
already there.

### Codex

Run the same installer — it also vendors `.codex/agents/*.toml` and
`hooks/pre-push`, and appends the bootstrap block to `AGENTS.md`:

```bash
scripts/install.sh /path/to/repo
```

Then enable multi-agent dispatch in `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Without this, the spawn/message/wait tools aren't in the model's tool
schema at all — the roles in `.codex/agents/` exist on disk but nothing can
reach them. With it on, roles are spawned by name from within a session,
e.g. "Have verifier check Task 2."

Recommended backstop, same file, so a spawn that omits a model doesn't
silently inherit the session's most expensive one:

```toml
[agents]
default_subagent_model = "<a mid-tier model from your spawn allowlist>"
default_subagent_reasoning_effort = "medium"
```

See `skills/using-superpowers/references/codex-tools.md` for dispatch,
waiting, and model-routing details.

Optional tools used by the ship workflow: `glab`, `gitlab-ci-local`,
`docker compose`.

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas
   through questions, explores alternatives, presents design in sections
   for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates
   isolated workspace on new branch, runs project setup, verifies clean
   test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into
   bite-sized tasks (2-5 minutes each). Every task has exact file paths,
   complete code, and a required `Done when` block of runnable verification
   commands.

4. **subagent-driven-development** or **executing-plans** - Activates with
   plan. Dispatches a fresh subagent per task, then a fresh `verifier`
   subagent re-runs the `Done when` checks from scratch before a two-stage
   review (spec compliance, then code quality) — or executes in batches
   with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces
   RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal
   code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against
   plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete.
   Verifies tests, presents options (merge/PR/keep/discard), cleans up
   worktree.

Two more workflows round out the loop this fork adds:

8. **fixing-bugs** - Activates for bug reports. Read-only `explorer`
   isolates root cause, `implementer` writes a failing reproduction before
   fixing, fresh `verifier` re-runs everything, `reviewer` checks the diff.
   Capped at 3 rounds.

9. **shipping** - Activates when a branch is ready to go out. Preflight →
   rebase → push → open/update the merge request → watch the pipeline →
   triage failures → work review comments → merge only on explicit
   authorization.

**The agent checks for relevant skills before any task.** Mandatory
workflows, not suggestions.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing
  anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes
  root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **fixing-bugs** - Explorer isolates root cause, implementer writes a
  failing reproduction before fixing, fresh verifier re-runs everything,
  reviewer checks the diff. Capped at 3 rounds.
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans, each task with a
  required `Done when` verification block
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with a fresh verifier
  subagent, then two-stage review (spec compliance, then code quality)
- **shipping** - Preflight, push, merge-request review, and auto-merge, all
  gated on explicit authorization for the final merge

**Meta**
- **writing-skills** - Create new skills following best practices
  (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

### Enforced Roles

`.claude/agents/{explorer,implementer,verifier,reviewer}.md` and
`.codex/agents/*.toml` give each role a real, schema-enforced tool set
instead of a prose instruction. `explorer`, `verifier`, and `reviewer` are
read-only; only `implementer` can write, and it's the role that never gets
to grade its own work.

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success, with a fresh
  subagent doing the verifying

## A caveat worth knowing before you trust this

`readonly-guard` matches command *text*, not intent — it stops a model
that's casually drifting out of its lane (a reviewer fixing a typo it
noticed), not one spelled around with an absolute path, a wrapper shell, or
a different interpreter entirely. The Codex side is stronger by
construction: `sandbox_mode = "read-only"` is enforced by the OS, not by
reading strings, so a write fails there regardless of how the command is
spelled. Treat the hook as a tripwire for cooperative agents, not a
security boundary — for that, use sandboxing.

## Contributing

This is a private fork; changes go through normal PR review, not upstream's
process. Keep in mind that any updates to skills must work across both
harnesses this fork supports.

1. Create a branch for your work
2. Follow the `writing-skills` skill for creating and testing new and
   modified skills
3. Run `scripts/preflight.sh` before pushing — `hooks/pre-push` runs it
   automatically in `--quick` mode
4. Submit a PR

Plugin-infrastructure and skill-behavior tests live at `tests/` and run via
the relevant `run-*.sh` scripts (see `tests/claude-code/run-skill-tests.sh`,
`tests/explicit-skill-requests/run-all.sh`, etc.).

See `skills/writing-skills/SKILL.md` for the complete guide.

## License

MIT License - see LICENSE file for details

## Layout

```
skills/                 workflows: using-superpowers (bootstrap),
                         brainstorming -> writing-plans ->
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
