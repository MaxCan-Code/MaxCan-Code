#!/usr/bin/env bash
# Exercises the live PreToolUse hooks. Cases live in this file rather than on a
# command line so the live Bash guard does not flag this runner's own invocation.
# Run: bash symlinks/.config/claude/hooks/run-guard-tests.sh
#      (exits non-zero if any case regresses)
#      It stubs tmux, so it needs no live services.
#
# The hook docs live in each script's header; this header holds what spans them.
# All are registered in ../settings.json under hooks.PreToolUse.
#
# | Hook | Fires on | Effect |
# | --- | --- | --- |
# | inline `echo` | `Edit` `Write` `NotebookEdit` | prior-art reminder |
# | `test-suite-reminder.sh` | same, source files only | tests-first reminder |
# | `cap-edit-size.sh` | every tool | denies calls taller than half the tmux window (1500 chars outside tmux) |
# | `no-bare-cli-tools.sh` | `Bash` | denies commands invoking a tool not on PATH |
#
# Reminders use `additionalContext`; guards use `permissionDecision: "deny"`. `deny`
# beats `ask`: the reason feeds back and the model retries, where `ask` stalls a
# background session with no tty.
#
# ## Prior-art reminder
#
# Before hand-assembling a workaround, spend one search on the existing work: for a task,
# "<tool> <task> command"; for a dependency that broke or vanished after an update, its
# upstream removal commit, PR and the issues they link.
#
# Case one: fixing Ctrl+G in background sessions, the first tmux attempt used
# `split-window` plus a hand-rolled `wait-for -S`/`wait-for` signal pair to get blocking
# behaviour. All of that was unnecessary — `tmux display-popup -E` blocks natively and is
# purpose-built for it. The general primitive feels familiar, so it's easy to start
# building scaffolding around its gaps instead of checking for the narrower command.
#
# Case two (2026-10-03): a nixpkgs bump dropped `aspellDicts.en-computers` because its
# upstream URL died. The response went to the Nix store and the Wayback Machine, while the
# removal's `aliases.nix` message, the PR, and the issue it referenced (#192590) already
# held a byte-identical mirror from 2022. The reminder had fired on every edit; it was
# read as boilerplate. The trail is short — removal commit, alias throw text, linked
# issue — and it is where the fix lives far more often than a reconstruction does.
#
# ## Working on these hooks
#
# - Payload JSON nests inside settings.json JSON. A literal `"` needs triple escaping and
#   has already broken one deny message — keep message text ASCII and quote-free.
# - This directory is **read-only to sandboxed commands** since stow linked it to
#   `~/.claude/hooks`; `cp` and `chmod` fail here even via the repo path, though the Write
#   tool succeeds. Installing a script takes Write plus a sandbox-off `chmod`.
# - stow linked the *directory*, so new scripts need no re-stow.
# - The settings watcher reloads mid-session; edits apply on the next tool call.
# - `additionalContext` **is** honored on `PreToolUse` — verified live, not assumed; the
#   schema documents only `permissionDecision` for this event.
# - Verify by triggering, not by parsing. A hook whose JSON parses can still never fire.

HOOKS=$(cd "$(dirname "$0")" && pwd)
GUARD=$HOOKS/no-bare-cli-tools.sh
TESTS=$HOOKS/test-suite-reminder.sh
fail=0

run() {
  want=$1; shift
  cmd=$*
  out=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd" | "$GUARD")
  if printf '%s' "$out" | grep -q permissionDecision; then got=DENY; else got=ALLOW; fi
  if [ "$got" = "$want" ]; then mark='ok  '; else mark='FAIL'; fail=1; fi
  printf '%s %-5s %s\n' "$mark" "$got" "$cmd"
}

fires() {
  want=$1; path=$2; key=${3:-file_path}
  out=$(printf '{"tool_input":{"%s":"%s"}}' "$key" "$path" | "$TESTS")
  if [ -n "$out" ]; then got=FIRE; else got=QUIET; fi
  if [ "$got" = "$want" ]; then mark='ok  '; else mark='FAIL'; fail=1; fi
  printf '%s %-5s %s\n' "$mark" "$got" "$path"
}

echo "=== Bash guard: must DENY (not on PATH) ==="
run DENY  'echo x | jq .'
run DENY  'jq -e . f.json'
run DENY  'python3 -c print'
run DENY  'ls && jq .'
run DENY  'fd -e md'
run DENY  'cat f | python3 -'

echo "=== Bash guard: must ALLOW ==="
run ALLOW 'P=$(COMMA_ASK_TO_CONFIRM=false comma -x jq)'
run ALLOW '/nix/store/abc-jq-1.8.1-bin/bin/jq -e .'
run ALLOW 'ls -d /nix/store/*-python3-*/bin/python3 | head -1'
run ALLOW 'git status --short'
run ALLOW ', stow -t ~ -d ~/.dotfiles symlinks'
run ALLOW 'nix run nixpkgs#stow -- -t ~/ -d ~/.dotfiles symlinks'
run ALLOW 'for f in a b; do echo $f; done'

echo "=== Bash guard: quoted prose must not look like commands (regression) ==="
run ALLOW "echo '(no output above = correct)'"
run ALLOW "echo 'pipe | semicolon ; paren ( here'"
run ALLOW "grep -n CAP file.sh; echo '(done)'"

echo "=== Bash guard: redirections are not commands (regression) ==="
run ALLOW 'bash run.sh 2>&1 | tail -22'
run ALLOW 'ls nope 2>/dev/null || echo none'
run ALLOW 'git log >out.txt 2>&1'
run DENY  'jq . f 2>&1 | tail -5'

echo "=== Bash guard: quoted program text is not commands (regression) ==="
# runq escapes the way a real payload does, so cases may contain double quotes.
runq() {
  want=$1; shift
  cmd=$*
  esc=$(printf '%s' "$cmd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  out=$(printf '{"tool_input":{"command":"%s"}}' "$esc" | "$GUARD")
  if printf '%s' "$out" | grep -q permissionDecision; then got=DENY; else got=ALLOW; fi
  if [ "$got" = "$want" ]; then mark='ok  '; else mark='FAIL'; fail=1; fi
  printf '%s %-5s %s\n' "$mark" "$got" "$cmd"
}
runq ALLOW '"$P" -r ".hooks[] | \"m=\(.matcher)\n\"" f.json'
runq ALLOW 'echo "keys: $("$P" -r "keys|join(a)" f)"'
runq ALLOW 'printf "%s\n" done'
runq ALLOW '"$pw/bin/playwright" screenshot http://x a.png'
runq ALLOW "'/opt/x/bin/tool' screenshot a.png"
runq DENY  'echo "a b"; jq .'

echo "=== Bash guard: backslash-newline continues a command (regression) ==="
run ALLOW 'nix shell nixpkgs#ruby --command \\\nbundle install'
run DENY  'ls \\\n-la && jq .'

echo "=== Bash guard: newline-separated commands still checked ==="
run ALLOW 'ls\ngit status'
run DENY  'ls\njq .'

echo "=== Bash guard: heredoc bodies are data, not commands (regression) ==="
run ALLOW 'git commit -F - <<'"'"'EOF'"'"'\nhooks: fold docs\n\nCo-Authored-By: x\nEOF'
run ALLOW 'cat <<EOF\nfoo bar\nEOF'
run ALLOW 'cat <<\"EOF\"\nfoo; bar | baz\nEOF'
run ALLOW 'cat <<-EOF\n\tfoo bar\n\tEOF'
run ALLOW 'cat <<'"'"'EOF'"'"'\nit'"'"'s here\nEOF\necho done'
run ALLOW 'cat <<EOF | grep x\nfoo\nEOF'
run DENY  'cat <<EOF\nfoo\nEOF\njq .'
run DENY  'cat <<EOF | jq .\nfoo\nEOF'
run DENY  'grep x <<< foo; jq .'

echo "=== Bash guard: functions defined in the command are callable (regression) ==="
run ALLOW 't(){ echo $1; }; t a\nt b'
run ALLOW 'chk() { ls; }\nchk'
run ALLOW 'function go_x { ls; }; go_x'
run DENY  't(){ echo; }; t; jq .'

echo "=== Bash guard: description is ignored ==="
out=$(printf '%s' '{"tool_input":{"command":"ls -la","description":"validate with jq"}}' | "$GUARD")
if printf '%s' "$out" | grep -q permissionDecision; then echo 'FAIL DENY  description leaked'; fail=1; else echo 'ok   ALLOW description ignored'; fi

echo "=== test-suite reminder: code fires, prose/config stays quiet ==="
fires FIRE  /x/y/foo.nix
fires FIRE  /x/y/foo.py
fires FIRE  /x/y/build.sh
fires FIRE  /x/y/statusline-command.k
fires QUIET /x/y/README.md
fires QUIET /x/y/settings.json
fires QUIET /x/y/notes.txt
fires FIRE  /x/y/a.ipynb notebook_path
fires QUIET /x/y/noextension

echo "=== deny payload is valid JSON ==="
P=$(COMMA_ASK_TO_CONFIRM=false comma -x jq)
printf '%s' '{"tool_input":{"command":"echo x | jq ."}}' | "$GUARD" \
  | "$P" -e '.hookSpecificOutput | .permissionDecision + " / " + (.permissionDecisionReason | .[0:30])'

echo "=== cap-edit-size: half-tmux-window row cap ==="
CAPSH=$HOOKS/cap-edit-size.sh
capstub=$(mktemp -d)
# Stub tmux reports a 20-row x 40-col window => row cap is 10.
printf '#!/bin/sh\necho "20 40"\n' > "$capstub/tmux"
chmod +x "$capstub/tmux"
# Second stub simulates no tmux server: display-message fails -> char fallback.
capno=$(mktemp -d)
printf '#!/bin/sh\nexit 1\n' > "$capno/tmux"
chmod +x "$capno/tmux"

cap() {
  want=$1; payload=$2; label=$3; stubdir=${4:-$capstub}
  out=$(printf '%s' "$payload" | env "PATH=$stubdir:$PATH" "$CAPSH")
  if printf '%s' "$out" | grep -q permissionDecision; then got=DENY; else got=ALLOW; fi
  if [ "$got" = "$want" ]; then mark='ok  '; else mark='FAIL'; fail=1; fi
  printf '%s %-5s %s\n' "$mark" "$got" "$label"
}

wide=$(printf 'x%.0s' $(seq 1 500))
tall='l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\nl11\nl12'
six='l1\nl2\nl3\nl4\nl5\nl6'
huge=$(printf 'x%.0s' $(seq 1 1600))

cap ALLOW '{"tool_name":"Bash","tool_input":{"command":"git status"}}' 'short command fits'
cap DENY  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$wide\"}}" 'Bash: 500 chars wrap past 10 rows'
cap DENY  "{\"tool_name\":\"Write\",\"tool_input\":{\"content\":\"$tall\"}}" 'Write: 12 short lines exceed 10 rows'
cap DENY  "{\"tool_name\":\"Edit\",\"tool_input\":{\"old_string\":\"$six\",\"new_string\":\"$six\"}}" 'Edit: old+new sum to 12 rows'
cap ALLOW "{\"tool_name\":\"Edit\",\"tool_input\":{\"old_string\":\"a\",\"new_string\":\"$six\"}}" 'Edit: 7 rows fit'
cap ALLOW 'not json at all' 'unparsable input fails open'
cap ALLOW "{\"tool_input\":{\"content\":\"$wide\"}}" 'no tmux server: 500 chars under char cap' "$capno"
cap DENY  "{\"tool_input\":{\"content\":\"$huge\"}}" 'no tmux server: 1600 chars over char cap' "$capno"
# Deliberate: plans are capped too, to keep them short and incremental.
cap DENY  "{\"tool_name\":\"ExitPlanMode\",\"tool_input\":{\"plan\":\"$tall\"}}" 'ExitPlanMode: tall plan capped on purpose'
rm -rf "$capstub" "$capno"

echo
[ "$fail" = 0 ] && echo 'ALL PASS' || echo 'REGRESSIONS ABOVE'
exit $fail
