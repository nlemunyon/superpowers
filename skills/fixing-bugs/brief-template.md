# Fix Brief Template

Write `brief.md` from `isolation.md`. Exact values verbatim.

```markdown
# Fix: <bug name>

## Symptom
<verbatim error text and where it appears>

## Reproduce
Run: `<command from isolation.md>`
Expected now: <failing output>
Expected after fix: <passing output>

## Root cause
<one sentence, from isolation.md, with path:line>

## Files
- Test: `tests/<path>` (create or modify)
- Modify: `<path>:<lines>`

## Regression test
Test name: `<test_name>`
Asserts: <the reported symptom, not a mock>

## Constraints
- Smallest change that fixes the root cause. No refactors.
- Only the files above change.

## Done when
- `<focused test command>` exits 0
- `<full suite command>` exits 0
- `<lint command>` exits 0
- Only the files listed under Files changed
```
