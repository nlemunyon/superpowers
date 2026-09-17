#!/usr/bin/env bash
# Preflight before push: prove the pipeline will pass before the remote runs it.
#
# Order: CI config lint -> local CI jobs -> project test command.
# Deterministic; an agent only steps in when a stage fails.
#
# Usage: scripts/preflight.sh [--quick]
#   --quick   skip local CI jobs (lint config + tests only); used by pre-push
#
# Config (env or .preflight file, KEY=VALUE per line):
#   PREFLIGHT_STAGES   CI stages to run locally (default: "lint test build")
#   PREFLIGHT_JOBS     explicit job names instead of stages
#   PREFLIGHT_TEST     test command (default: auto-detect)
#   PREFLIGHT_SKIP_CI  1 = never run local CI jobs
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "preflight: not a git repo" >&2; exit 2; }
cd "$root"
[ -f .preflight ] && set -a && . ./.preflight && set +a
quick=0; [ "${1:-}" = "--quick" ] && quick=1
stages=${PREFLIGHT_STAGES:-"lint test build"}
fail=0

step() { printf '\n== %s\n' "$*"; }
result() { # name exit
  if [ "$2" -eq 0 ]; then printf '   ok   %s\n' "$1"; else printf '   FAIL %s (exit %s)\n' "$1" "$2"; fail=1; fi; }

# 1. CI config lint
if [ -f .gitlab-ci.yml ]; then
  step "gitlab-ci lint"
  if command -v glab >/dev/null; then
    glab ci lint; result "glab ci lint" $?
  elif command -v gitlab-ci-local >/dev/null; then
    gitlab-ci-local --list >/dev/null; result "gitlab-ci-local parse" $?
  else
    echo "   skip  no glab or gitlab-ci-local installed"
  fi
elif [ -d .github/workflows ] && command -v actionlint >/dev/null; then
  step "actionlint"; actionlint; result "actionlint" $?
fi

# 2. Local CI jobs
if [ "$quick" -eq 0 ] && [ "${PREFLIGHT_SKIP_CI:-0}" != "1" ] && [ -f .gitlab-ci.yml ]; then
  step "local CI jobs"
  if command -v gitlab-ci-local >/dev/null; then
    if [ -n "$(git status --porcelain --untracked-files=all)" ]; then
      echo "   note  gitlab-ci-local only sees staged/committed files; unstaged edits are ignored"
    fi
    if [ -n "${PREFLIGHT_JOBS:-}" ]; then
      for j in $PREFLIGHT_JOBS; do gitlab-ci-local "$j"; result "job $j" $?; done
    else
      for s in $stages; do
        if gitlab-ci-local --list 2>/dev/null | awk '{print $2}' | grep -qx "$s"; then
          gitlab-ci-local --stage "$s"; result "stage $s" $?
        fi
      done
    fi
  elif command -v glci >/dev/null; then
    glci; result "glci" $?
  else
    echo "   skip  install gitlab-ci-local (npm i -g gitlab-ci-local) to run jobs locally"
  fi
fi

# 3. Tests
step "tests"
test_cmd=${PREFLIGHT_TEST:-}
if [ -z "$test_cmd" ]; then
  if   [ -f package.json ] && grep -q '"test"' package.json; then test_cmd="npm test --silent"
  elif [ -f pytest.ini ] || grep -qs pytest pyproject.toml setup.cfg tox.ini || ls tests/test_*.py tests/**/test_*.py >/dev/null 2>&1; then test_cmd="pytest -q"
  elif [ -f Cargo.toml ]; then test_cmd="cargo test"
  elif [ -f go.mod ]; then test_cmd="go test ./..."
  elif [ -f Makefile ] && grep -q '^test:' Makefile; then test_cmd="make test"
  fi
fi
if [ -n "$test_cmd" ]; then bash -c "$test_cmd"; result "$test_cmd" $?; else echo "   skip  no test command detected; set PREFLIGHT_TEST"; fi

echo
if [ "$fail" -eq 0 ]; then echo "preflight: PASS"; else echo "preflight: FAIL"; fi
exit $fail
