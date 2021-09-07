#!/usr/bin/env bash
# PreToolUse(*) guard: refuse tool calls whose largest string argument exceeds
# CAP characters, keeping approval dialogs scrollable-small. Fails open —
# never blocks when it cannot measure. ExitPlanMode is capped on purpose:
# plans stay short and incremental. Do not exempt it.
set -uo pipefail

CAP=${CLAUDE_EDIT_CHAR_CAP:-1500}

# jq is not on PATH here; resolve it from the store by glob (fast, and survives
# a nixpkgs bump, unlike a hardcoded store path).
JQ=$(command -v jq 2>/dev/null || ls -d /nix/store/*-jq-*/bin/jq 2>/dev/null | head -1)
[ -x "$JQ" ] || exit 0

# Half of the current tmux window, in cells. tmux resolved like jq above.
H='' W=''
# No $TMUX gate: even when launched outside tmux (background jobs), the
# default server socket answers if a server is running.
TMUXBIN=$(command -v tmux 2>/dev/null || ls -d /nix/store/*-tmux-*/bin/tmux 2>/dev/null | head -1)
if [ -x "${TMUXBIN:-}" ]; then
  dims=$("$TMUXBIN" display-message -p '#{window_height} #{window_width}' 2>/dev/null) && set -- $dims && H=${1:-} W=${2:-}
fi
case "$H$W" in ''|*[!0-9]*) H='' ;; esac
[ -n "$H" ] && [ "${W:-0}" -lt 1 ] && H=''

if [ -n "$H" ]; then
  # Dialog height proxy: every tool_input string, wrapped at window width.
  CAP=$((H / 2))
  n=$("$JQ" --argjson w "$W" -r '[.tool_input // {} | .. | strings
        | split("\n") | map(if length == 0 then 1 else (length / $w | ceil) end) | add]
        | add // 0' 2>/dev/null) || exit 0
  msg="This call renders ~%s rows in the approval dialog; the cap is %s (half the tmux window). Split it into smaller sequential steps."
else
  n=$("$JQ" -r '[.tool_input // {} | .. | strings | length] | add // 0' 2>/dev/null) || exit 0
  msg="This call carries %s characters of arguments; the cap is %s. Split it into smaller sequential steps."
fi
case "$n" in ''|*[!0-9]*) exit 0 ;; esac

[ "$n" -le "$CAP" ] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'"$msg"'"}}\n' "$n" "$CAP"
exit 0
