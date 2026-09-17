#!/usr/bin/env bash
# Vendor this skills library into a target repo so it works with no
# marketplace or plugin install (Claude Code and Codex).
#
# Usage: scripts/install.sh /path/to/repo
#
# Installs:
#   .agents/skills/           skills (Codex reads here; Claude Code via symlink)
#   .claude/skills -> ../.agents/skills
#   .claude/agents/           explorer, implementer, verifier, reviewer
#   .claude/hooks/            readonly-guard
#   .codex/agents/            same roles for Codex
#   .agents/scripts/          preflight.sh
#   .git/hooks/pre-push       protected-branch and force-push guard + quick preflight
#   AGENTS.md / CLAUDE.md     bootstrap block appended if absent
set -euo pipefail

src=$(cd "$(dirname "$0")/.." && pwd)
dst=${1:?usage: install.sh /path/to/repo}
dst=$(cd "$dst" && pwd)
[ -d "$dst/.git" ] || { echo "install: $dst is not a git repo" >&2; exit 2; }

copy() { mkdir -p "$(dirname "$2")"; rm -rf "$2"; cp -R "$1" "$2"; }

copy "$src/skills"          "$dst/.agents/skills"
copy "$src/.claude/agents"  "$dst/.claude/agents"
copy "$src/.claude/hooks"   "$dst/.claude/hooks"
copy "$src/.codex/agents"   "$dst/.codex/agents"
mkdir -p "$dst/.agents/scripts"
cp "$src/scripts/preflight.sh" "$dst/.agents/scripts/preflight.sh"
chmod +x "$dst/.agents/scripts/preflight.sh" "$dst/.claude/hooks/"* 
find "$dst/.agents/skills" -path '*/scripts/*' -type f -exec chmod +x {} +

if [ ! -e "$dst/.claude/skills" ]; then ln -s ../.agents/skills "$dst/.claude/skills"; fi

cp "$src/hooks/pre-push" "$dst/.git/hooks/pre-push"; chmod +x "$dst/.git/hooks/pre-push"

block='<!-- superpowers:bootstrap -->
## Skills

At session start, read `.agents/skills/using-superpowers/SKILL.md` and follow it.
Skills live in `.agents/skills/<name>/SKILL.md`. Subagent roles: `.claude/agents/`
(Claude Code) and `.codex/agents/` (Codex).
<!-- /superpowers:bootstrap -->'

for f in AGENTS.md CLAUDE.md; do
  if [ -f "$dst/$f" ] && grep -q 'superpowers:bootstrap' "$dst/$f"; then continue; fi
  if [ "$f" = CLAUDE.md ] && [ -f "$dst/CLAUDE.md" ] && grep -q '^@AGENTS.md' "$dst/CLAUDE.md"; then continue; fi
  if [ "$f" = CLAUDE.md ] && [ ! -f "$dst/CLAUDE.md" ]; then printf '@AGENTS.md\n' > "$dst/CLAUDE.md"; continue; fi
  printf '\n%s\n' "$block" >> "$dst/$f"
done

grep -q '^\.superpowers/' "$dst/.gitignore" 2>/dev/null || printf '.superpowers/\n.worktrees/\n' >> "$dst/.gitignore"

echo "installed into $dst"
echo "next: npm i -g gitlab-ci-local  (optional, for local pipeline runs); glab auth login"
