#!/usr/bin/env bash
# PreToolUse(Bash) guard: refuse a command that invokes an executable which is not
# installed on PATH.
#
# Why: most common CLI tools are not on PATH on this machine. A bare name falls
# through to zsh's command_not_found_handler, which calls comma and then prompts or
# opens the fzy picker. Background sessions have no controlling tty, so the call dies
# with "Failed to open tty" -- after the pipeline has already half-run, which reads
# like a quoting bug rather than a missing tool.
#
# Fails open: anything it cannot statically resolve is allowed through.
# Test battery: run-guard-tests.sh
#
# Resolving a tool instead:
# - unambiguous name: ``P=`COMMA_ASK_TO_CONFIRM=false comma -x jq` `` prints the store path
# - ambiguous name (`python3` matches many derivations, so `comma -x` opens the picker):
#   `P=$(ls -d /nix/store/*-python3-*/bin/python3 | head -1)`
# - `nix run nixpkgs#NAME -- args` works under the sandbox (verified 2026-11-01)
# - better still, prefer Read/Grep/Glob over a shell one-liner
#
# It checks every token in executable position with `command -v`, reads `tool_input.command`
# only (matching the whole payload would hit the model-written `description`), and fails
# open. Four false positives shaped the tokenizer, all from ordinary commands: separators
# inside quotes, `2>&1` leaving `1` in executable position, unescaping `\n` before
# blanking quotes (which tore a jq program apart and stranded `.matcher`), and heredoc
# bodies read as commands (a commit message's `Co-Authored-By:` line). Three more came
# later: a `\`-newline continuation read as a new command, a quoted program path
# (`"$P" arg`) vanishing so `arg` looked like the command, and calls to a function the
# command itself defines. A guard that blocks real work is worse than one that
# occasionally misses.
#
# Note it matches textually, so a bare tool name as a *literal string* is denied too —
# put such strings in a file, as the test battery does.
set -uo pipefail

# Names that are reachable in the Bash tool's shell but not necessarily via this
# hook's PATH lookup. Add here rather than weakening the check. (, is on PATH today;
# it is listed because comma is how uninstalled tools are meant to be run.)
ALLOW='^(,)$'

input=$(cat)

# Only inspect tool_input.command. Grepping the whole payload would also match the
# model-written description ("validate with jq"), denying commands that are correct.
cmd=$(printf '%s' "$input" | grep -oP '"command"\s*:\s*"(\\.|[^"\\])*"' | head -1)
[ -n "$cmd" ] || exit 0
cmd=${cmd#*:\"}
cmd=${cmd%\"}

# Drop heredoc bodies before any quote handling. A body is data, not commands,
# and a lone apostrophe in it (it's) would mis-pair the quote blanking below.
# The opener's << and word are blanked too: step 1 would turn 'EOF' into a
# space and lose the delimiter. Herestrings (<<<) do not match.
hd_re='(^|[^<])<<(-?)[[:space:]]*(\\"|'"'"')?([A-Za-z_][A-Za-z0-9_]*)(\\"|'"'"')?'
out='' delim='' strip=''
while IFS= read -r line; do
  if [ -n "$delim" ]; then
    probe=$line
    # <<- strips leading tabs, which arrive as \t escapes or real tabs.
    while [ -n "$strip" ]; do
      case $probe in
        '\t'*) probe=${probe#'\t'} ;;
        $'\t'*) probe=${probe#?} ;;
        *) break ;;
      esac
    done
    [ "$probe" = "$delim" ] && delim=''
    continue
  fi
  if [[ $line =~ $hd_re ]]; then
    delim=${BASH_REMATCH[4]} strip=${BASH_REMATCH[2]}
    line=${line/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]} "}
  fi
  out+=${out:+'\n'}$line
done <<< "${cmd//\\n/$'\n'}"
cmd=$out

# Undo the JSON escaping enough to tokenize: \n becomes a real separator, \" and \\
# become their literal characters.
# Order matters. Quoted spans must be blanked BEFORE \n is turned into a separator:
# a jq program like '"k=\(.v)\n"' contains \n inside quotes, and unescaping first
# splits the quoted span across lines, stranding fragments like .v in what then looks
# like executable position. Blanking quotes first also stops prose containing ( | ;
# from reading as command separators. Fewer tokens keeps the guard fail-open.
#   1. single-quoted spans (single quotes are never escaped in JSON). Each becomes ''
#      rather than vanishing, so a quoted command word ("$P" args) stays a token that
#      the quote rule below skips, instead of promoting its first argument.
cmd=$(printf '%s' "$cmd" | sed "s/'[^']*'/''/g")
#   2. double-quoted spans, which arrive as \" ... \"; same, they become ""
cmd=$(printf '%s' "$cmd" | sed -e 's/\\"/\x01/g' -e 's/\x01[^\x01]*\x01/""/g')
#   2b. backslash-newline (\\\n in JSON) is a line continuation, not a command break
cmd=$(printf '%s' "$cmd" | sed 's/\\\\\\n/ /g')
#   3. any \n still left is a real line break between commands, not string content
cmd=$(printf '%s' "$cmd" | sed -e 's/\\n/\n/g' -e 's/\\\\/\\/g')

# Functions defined in the command itself (name() or function name) are callable later
# in it. Collect their names after quote blanking, so text inside strings never counts.
funcs=" $(printf '%s' "$cmd" \
  | grep -oE '(^|[[:space:];&|{])(function[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*|[A-Za-z_][A-Za-z0-9_-]*[[:space:]]*\(\))' \
  | sed -E -e 's/^[[:space:];&|{]//' -e 's/^function[[:space:]]+//' -e 's/[[:space:]]*\(\)$//' \
  | tr '\n' ' ') "

# Blank out redirections before splitting on &. Otherwise 2>&1 splits into a segment
# beginning with "1", which then looks like a command in executable position.
cmd=$(printf '%s' "$cmd" | sed -E -e 's/[0-9]*>>?&?[0-9-]*/ /g' -e 's/[0-9]*<&?[0-9-]*/ /g')

# Split on anything that starts a new command, so the first word of each segment is in
# executable position. $( is split explicitly, but a bare ( is NOT: nested quoting
# inside a command substitution defeats naive quote pairing, and splitting on every
# paren strands fragments of quoted program text (jq's join(a)) in executable position.
# Losing coverage of a bare (subshell) is the cheaper mistake -- && and | still split it.
cmd=$(printf '%s' "$cmd" | sed 's/\$(/\n/g')
segments=$(printf '%s' "$cmd" | tr '|;&`\n' '\n\n\n\n\n')

missing=''
while IFS= read -r seg; do
  # Strip leading whitespace, leading VAR=value assignments, and wrappers that take
  # the real command as their argument.
  seg="${seg#"${seg%%[![:space:]]*}"}"
  while [[ $seg =~ ^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|sudo|doas|env|command|exec|nohup|time|xargs|builtin)[[:space:]]+(.*)$ ]]; do
    seg="${BASH_REMATCH[2]}"
  done

  tok=${seg%%[[:space:]]*}
  [ -n "$tok" ] || continue

  # Skip anything not resolvable as a plain name: explicit paths, expansions, globs,
  # quoting, assignments, flags, redirects, and shell keywords.
  case $tok in
    */*|*'$'*|*'*'*|*'?'*|*'~'*|*'"'*|*"'"*|*'('*|*')'*|*=*|-*|.*|'<'*|'>'*|'{'|'}'|'[['|']]'|'!') continue ;;
    if|then|else|elif|fi|for|while|until|do|done|case|esac|in|function|select|return) continue ;;
  esac
  # A command name always contains a letter. This drops leftovers like the "1" from
  # 2>&1, bare numbers, and stray punctuation.
  [[ $tok =~ [A-Za-z] ]] || continue
  [[ $tok =~ $ALLOW ]] && continue
  [[ $funcs == *" $tok "* ]] && continue

  if ! command -v -- "$tok" >/dev/null 2>&1; then
    case " $missing " in *" $tok "*) ;; *) missing="$missing $tok" ;; esac
  fi
done <<< "$segments"

[ -n "$missing" ] || exit 0

missing=${missing# }
reason="Not on PATH: ${missing}. "'A bare name does not resolve here - it falls through to the zsh command_not_found_handler, which needs a tty and dies with (Failed to open tty) in background sessions, after the pipeline has half-run. Resolve a store path first and exec that: for an unambiguous name use P=$(COMMA_ASK_TO_CONFIRM=false comma -x NAME); for an ambiguous one (python3 matches many derivations, so comma -x opens the picker) use P=$(ls -d /nix/store/*-NAME-*/bin/NAME | head -1). nix run nixpkgs#NAME -- ARGS also works. Better still, prefer the Read/Grep/Glob tools over a shell one-liner where one fits.'

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
