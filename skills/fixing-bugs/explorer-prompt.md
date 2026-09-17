# Explorer Prompt (bug isolation)

```
Subagent: explorer            (Claude Code: subagent_type "explorer";
                               Codex: "Have explorer isolate this bug")
  description: "Isolate: [short bug name]"
  model: [MODEL — mid tier]
  prompt: |
    Isolate this bug. Read-only: you find the cause, you do not fix it.

    Bug report: [BUG_FILE]
    Write your findings to: [ISOLATION_FILE]

    Do, in order, citing path:line and command output for each:
    1. Read the full error text and stack trace in the report.
    2. Reproduce: find or write the exact command that shows the
       symptom. Run it. Paste the output.
    3. Recent changes: `git log --oneline -20` and `git diff` on the
       files in the trace. Note anything touching them.
    4. Trace the bad value backward to where it originates.
    5. Find working code doing the same thing; list the differences.
    6. Name ONE root cause, or ONE hypothesis with the evidence for it.

    Findings file sections: Reproduction (command + output), Affected
    files (path:line — why), Recent changes, Data-flow trace, Working
    pattern and differences, Root cause or hypothesis, Open doubts.

    [GAP — on re-dispatch: "Previous findings at [ISOLATION_FILE] lack
    <what>. Fill that gap; keep the rest."]

    Reply under 10 lines: reproduction command, root cause or
    hypothesis, affected files, doubts.
```
