#!/usr/bin/env bash
# PreToolUse(Edit|Write|NotebookEdit): remind to write the tests first, but only when
# the edit targets source code.
#
# Why a script and not the inline "if" field: if takes one permission-rule glob, and
# that matcher supports * and ** but NOT brace {a,b} or extglob @(a|b) -- both were
# tested live and silently matched nothing. That is the dangerous failure: the hook
# stays registered and never fires. Covering N extensions via if would need N
# separate hook entries.
#
# Only nags on source files; "write the tests first" is wrong advice for a README.
# Fails open: if the path cannot be determined, stay quiet rather than nag wrongly.
# Test battery: run-guard-tests.sh
set -uo pipefail

EXTS='py|ts|tsx|js|jsx|sh|bash|nix|k|rs|go|c|h|hpp|cpp|cc|lua|rb|pl|java|kt|swift|zig|ml|hs|el|ipynb'

input=$(cat)

# Edit/Write use file_path; NotebookEdit uses notebook_path.
path=$(printf '%s' "$input" | grep -oP '"(file_path|notebook_path)"\s*:\s*"(\\.|[^"\\])*"' | head -1)
[ -n "$path" ] || exit 0
path=${path#*:\"}
path=${path%\"}

[[ $path =~ \.($EXTS)$ ]] || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Before coding or building, create the test suite first - define the cases that must pass, then implement against them."}}\n'
exit 0
