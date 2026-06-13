# =============================================================================
#  clipboard.zsh — vi-yank → system clipboard, with OSC 52 fallback over SSH/mosh
# =============================================================================
#
# Integrates with the zsh-vi-mode plugin sourced in plugins.zsh.
#
# - In a local terminal session: pbcopy / wl-copy / xclip get the yanked text.
# - In an SSH/mosh session (including Blink Shell on iPhone): OSC 52 escape is
#   emitted; tmux passes it through, terminal copies to the system pasteboard.
#
# Note: NEVER use `local path` in zsh — it shadows $PATH (it's a tied array).
# See ~/.claude/projects/-/memory/feedback_zsh_local_path.md.

# -----------------------------------------------------------------------------
#  Helper — push text to whichever clipboard surface is available.
# -----------------------------------------------------------------------------
_yank_to_clip() {
  local text="$1"
  [[ -z "$text" ]] && return 0

  if [[ -n "$SSH_CONNECTION$SSH_TTY" ]]; then
    # OSC 52: \e]52;c;<base64>\a — tmux passthrough handles the rest.
    printf '\033]52;c;%s\a' "$(printf '%s' "$text" | base64 | tr -d '\n')"
    return 0
  fi

  if (( $+commands[pbcopy] )); then
    printf '%s' "$text" | pbcopy
  elif (( $+commands[wl-copy] )); then
    printf '%s' "$text" | wl-copy
  elif (( $+commands[xclip] )); then
    printf '%s' "$text" | xclip -selection clipboard
  fi
}

# -----------------------------------------------------------------------------
#  Widget — yank into both $CUTBUFFER and the system clipboard.
# -----------------------------------------------------------------------------
vi-yank-clip() {
  zle vi-yank
  _yank_to_clip "$CUTBUFFER"
}
zle -N vi-yank-clip

vi-yank-eol-clip() {
  zle vi-yank-eol
  _yank_to_clip "$CUTBUFFER"
}
zle -N vi-yank-eol-clip

# -----------------------------------------------------------------------------
#  Bind under zsh-vi-mode's keymap. zsh-vi-mode rebinds everything during its
#  init, so we have to register inside its post-init hook to win.
# -----------------------------------------------------------------------------
typeset -ga zvm_after_init_commands
zvm_after_init_commands+=(
  'bindkey -M vicmd y vi-yank-clip'
  'bindkey -M vicmd Y vi-yank-eol-clip'
)

# Belt-and-suspenders: also bind in vicmd directly in case zsh-vi-mode is
# disabled / unavailable on this host.
bindkey -M vicmd 'y' vi-yank-clip 2>/dev/null || true
bindkey -M vicmd 'Y' vi-yank-eol-clip 2>/dev/null || true
