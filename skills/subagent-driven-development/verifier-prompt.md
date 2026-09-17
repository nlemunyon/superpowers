# Verifier Subagent Prompt Template

Dispatch after an implementer reports DONE and before the task review.
The verifier is a fresh context: it did not write the code and cannot
edit it. Its verification file is the test evidence the reviewer trusts.

```
Subagent: verifier            (Claude Code: subagent_type "verifier";
                               Codex: "Have verifier check Task N")
  description: "Verify Task N"
  model: [MODEL — mid tier; the role file sets a default]
  prompt: |
    Verify Task N: [task name].

    Brief (requirements, ends in a Done-when block): [BRIEF_FILE]
    Implementer's report (unverified claims):        [REPORT_FILE]
    Diff range: [BASE_SHA]..HEAD
    Write your verification to:                      [VERIFICATION_FILE]

    Follow your role's procedure: re-run every Done-when command fresh,
    run the full suite once, run the Reproduce section if present, run
    the e2e stage if a compose file or e2e command exists, and compare
    the diff's file list against the brief's Files block.

    [E2E — only if the project defines it: "e2e command: <cmd>"]

    Reply under 8 lines: verdict, each failing item on one line, the
    verification file path.
```

**Placeholders:**
- `[BRIEF_FILE]`, `[REPORT_FILE]` — same files the implementer used
- `[VERIFICATION_FILE]` — `<workspace>/task-N-verification.md`; fix
  rounds append to it
- `[BASE_SHA]` — the BASE you recorded before dispatching the implementer

**Verifier returns:** PASS or FAIL with one line per failing item.
FAIL items enter the fix loop as Critical findings.
