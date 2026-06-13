# ──────────────────────────────────────────────────────────
# CLAUDE MULTI-AGENT HELPERS
# ──────────────────────────────────────────────────────────

# Claude in a new tmux window
cw() {
  if [[ -z "$TMUX" ]]; then echo "cw: not in a tmux session"; return 1; fi
  local name="${1:-claude}"
  tmux new-window -n "$name" "claude"
}

# Claude in a new tmux session
cs() {
  local name="${1:-claude-$(date +%H%M)}"
  tmux new-session -d -s "$name" "claude"
  tmux switch-client -t "$name" 2>/dev/null || tmux attach -t "$name"
}

# List running claude processes with cwd
cls() {
  command ps -eo pid,etime,command | rg '\bclaude\b' | rg -v 'rg|cls\(\)' | while read -r pid etime cmd; do
    cwd=$(lsof -a -d cwd -p "$pid" 2>/dev/null | tail -1 | awk '{print $NF}')
    printf "%-7s %-10s %s\n" "$pid" "$etime" "${cwd:-?}"
  done
}

# Kill all stray claude processes (interactive)
ckill() {
  local pids
  pids=$(pgrep -x claude)
  if [[ -z "$pids" ]]; then echo "no claude processes"; return; fi
  echo "Found claude PIDs:"; echo "$pids"
  read -q "REPLY?Kill all? [y/N] " || { echo; return 1; }
  echo; echo "$pids" | xargs kill -TERM
}

# Pick from atuin history, run via claude
cl() {
  local cmd
  cmd=$(atuin search -i 2>/dev/null) || return
  [[ -n "$cmd" ]] && claude "$cmd"
}

# Claude explain current command line (Ctrl-X Ctrl-E)
explain_cmd() {
  BUFFER="claude \"Explain this command: $BUFFER\""
  zle accept-line
}
zle -N explain_cmd
bindkey '^X^E' explain_cmd

# Mobile push notification toggle (gated by flag file)
claude-notify() {
  case "$1" in
    on)     touch  ~/.claude-notify-enabled  && echo "claude push notifications: ON" ;;
    off)    rm -f  ~/.claude-notify-enabled  && echo "claude push notifications: OFF" ;;
    status) [[ -f  ~/.claude-notify-enabled ]] && echo "claude push notifications: ON" || echo "claude push notifications: OFF" ;;
    *)      echo "usage: claude-notify {on|off|status}" ;;
  esac
}
