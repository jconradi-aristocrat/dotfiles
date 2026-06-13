# ──────────────────────────────────────────────────────────
# AUTO TMUX — pop into persistent session on interactive shell.
# Skips IDE-embedded terminals AND Ghostty (so Ghostty windows stay
# free-standing; attach to tmux manually with `ts` when you want it).
# ──────────────────────────────────────────────────────────

# `-t 1` gates everything below on stdout being a real TTY. Without it, env
# probes like VSCode's shell-env resolver (interactive login shell with stdio
# redirected) fall through to `exec tmux`, which fails with "not a terminal"
# and exits 1 — breaking VSCode's "resolve your shell environment".
if [[ -o interactive ]] \
   && [[ -t 1 ]] \
   && [[ -z "$TMUX" ]] \
   && [[ -z "$VSCODE_INJECTION" ]] \
   && [[ -z "$INSIDE_EMACS" ]] \
   && [[ -z "$INTELLIJ_ENVIRONMENT_READER" ]] \
   && [[ "$TERM_PROGRAM" != "vscode" ]] \
   && [[ "$TERM_PROGRAM" != "WarpTerminal" ]] \
   && [[ "$TERM_PROGRAM" != "ghostty" ]] \
   && command -v tmux >/dev/null 2>&1; then
  # Stash the real outer terminal identity before tmux overwrites TERM and
  # TERM_PROGRAM. tmux.conf's update-environment picks these up on attach,
  # making them available to pane shells for fastfetch protocol detection.
  export TERM_OUTER="${TERM}"
  export TERM_PROGRAM_OUTER="${TERM_PROGRAM:-}"
  exec tmux new -A -s main
fi

