# ──────────────────────────────────────────────────────────
# TMUX TITLE — drive the tmux window name from zsh's PWD.
# Tmux's `pane_current_path` is stuck on the atuin pty-proxy
# wrapper's cwd (foreground process), so tmux can't see when
# zsh cd's. We bypass it: chpwd fires inside the wrapped shell,
# we compute the short path and call `tmux rename-window`. The
# catppuccin tabs render `#W` (see tmux.conf section 6) so they
# pick up the new name immediately on the next status refresh.
# Calls `command tmux` so a `tmux` shell alias can't intercept.
# ──────────────────────────────────────────────────────────

if [[ -n "$TMUX" ]]; then
  autoload -Uz add-zsh-hook

  _tmux_title_refresh() {
    local short
    if [[ -x "$HOME/.config/tmux/scripts/short_path.sh" ]]; then
      short="$("$HOME/.config/tmux/scripts/short_path.sh" "$PWD" 24)"
    else
      short="${${PWD/#$HOME/~}:t}"
    fi
    # `-t "$TMUX_PANE"` is critical: without an explicit target, tmux renames
    # the active window of the active session — which can be a different
    # window than the one this shell lives in (e.g. when send-keys delivers
    # commands to a backgrounded pane).
    command tmux rename-window -t "$TMUX_PANE" -- "$short" 2>/dev/null
  }

  add-zsh-hook chpwd _tmux_title_refresh
  # chpwd only fires on subsequent cd's, so seed the name once at shell init.
  _tmux_title_refresh
fi
