#!/usr/bin/env bash
# Regenerates ~/.agents/handoff/SYSTEM.md as verbatim command output.
# Facts are always "$ command" + literal output; never retype or summarise.
set -u

OUT="${HOME}/.agents/handoff/SYSTEM.md"
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp)"

fmt() { # render argv as a copyable shell command
  local o="" a
  for a in "$@"; do
    case "$a" in
      *[[:space:]]*|*"'"*) a="'${a//\'/\'\\\'\'}'" ;;
    esac
    o+="$a "
  done
  printf '%s' "${o% }"
}

emit() { # emit <heading> <tags> <command...>
  local h="$1" t="$2" cmd
  shift 2
  cmd="$(fmt "$@")"
  printf '<!-- tags: %s -->\n## %s\n\n```\n$ %s\n' "$t" "$h" "$cmd"
  "$@" 2>&1 | head -n 40
  printf '```\n\n'
}

FP="$( { uname -a | head -n 1; grep -E '^(ID|BUILD_ID)=' /etc/os-release; nproc; } )"

{
  printf 'updated: %s\n\n' "$(date +%F)"
  printf '## Fingerprint\n\n```\n%s\n```\n\n' "$FP"

  emit "OS / kernel" "always" cat /etc/os-release
  emit "Shell / display" "always" bash -c 'echo "SHELL=$SHELL"; echo "DISPLAY=$DISPLAY"; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"; echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"'
  emit "Terminal / editor" "always" bash -c 'command -v code vim nvim helix 2>/dev/null || echo "(none of code/vim/nvim/helix)"'
  emit "Hardware" "always" bash -c 'nproc; free -h | head -n 2'
  emit "GPU" "always, gpu" bash -c 'command -v nvidia-smi >/dev/null && nvidia-smi -L || echo "(no nvidia-smi)"'

  if command -v pacman >/dev/null; then
    emit "Package manager (pacman)" "always" bash -c 'command -v pacman; pacman -Q | wc -l'
  elif command -v apt >/dev/null; then
    emit "Package manager (apt)" "always" bash -c 'command -v apt; dpkg -l | wc -l'
  elif command -v brew >/dev/null; then
    emit "Package manager (brew)" "always" brew --version
  else
    emit "Package manager" "always" echo "(none detected)"
  fi

  command -v python3 >/dev/null && emit "Python runtime" "python" python3 -V
  command -v node    >/dev/null && emit "Node toolchain" "node, web" bash -c 'node -v; npm -v'
  command -v go      >/dev/null && emit "Go toolchain" "go" go version
  command -v cargo   >/dev/null && emit "Rust toolchain" "rust" cargo -V
  command -v git     >/dev/null && emit "Git" "always" git --version
  command -v docker  >/dev/null && emit "Docker" "container" docker -v
} > "$TMP"

OLD_FP="$(awk '
  /^## Fingerprint$/ { f=1; next }
  f && /^```$/     { n++; next }
  f && n==1        { print }
  f && n>=2        { exit }
' "$OUT" 2>/dev/null)"
if [ -f "$OUT" ] && [ -n "$OLD_FP" ] && [ "$OLD_FP" = "$FP" ]; then
  echo "fingerprint unchanged"
else
  echo "fingerprint changed (or first run)"
fi
mv "$TMP" "$OUT"
echo "SYSTEM.md written ($OUT)"
