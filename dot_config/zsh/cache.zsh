# ──────────────────────────────────────────────────────────
# CACHE LAYER — sourced FIRST by ~/.zshrc.
# Goal: cache slow `tool init zsh` outputs and zcompile every
# config file so interactive startup is dominated by syscalls,
# not subshell forks.
# ──────────────────────────────────────────────────────────

# Profiler gate. Run `ZSH_PROFILE=1 exec zsh` then `zprof | head -40`.
[[ -n $ZSH_PROFILE ]] && zmodload zsh/zprof

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# zsh_eval_cache <name> <cmd> [args...]
# Source $cmd's stdout from $ZSH_CACHE_DIR/<name>.zsh. Regenerate if the
# binary's mtime is newer than the cache. zcompile in the background so the
# next shell starts even faster.
#
# Example: zsh_eval_cache zoxide zoxide init zsh
zsh_eval_cache() {
  local name="$1"; shift
  local bin; bin="$(command -v "$1")" || return
  local cache="$ZSH_CACHE_DIR/$name.zsh"
  if [[ ! -s "$cache" || "$bin" -nt "$cache" ]]; then
    "$@" > "$cache" 2>/dev/null
    { zcompile -R -- "$cache".zwc "$cache" } &!
  fi
  source "$cache"
}

# Invalidate every cached eval. Called by `update-all` and useful manually
# after `brew upgrade <tool>` if you don't want to wait for the mtime check.
zsh_cache_clear() {
  command rm -f -- "$ZSH_CACHE_DIR"/*.zsh "$ZSH_CACHE_DIR"/*.zwc
  print -r -- "cleared $ZSH_CACHE_DIR"
}

# zbench — median startup time over N runs (default 10).
# bindkey_persistent — register a key binding that SURVIVES every later
# keymap rebuild (zsh-vi-mode init, fzf re-sources, etc.). It does three
# things:
#   1. `bindkey` immediately so it works before deferred plugins load
#   2. queue it into zvm_after_init_commands so vi-mode re-applies it
#   3. re-apply via precmd on every prompt — the only bulletproof path
# Per-prompt cost is sub-millisecond per binding; the array stays small.
#
# Usage: bindkey_persistent '^X^S' _s_widget
# Two parallel arrays — keys and widgets — paired by index. Storing the
# args literally (not as an eval string) avoids EXTENDED_GLOB expanding
# `^X^S` into a `^X^S`-negated glob pattern when the array is replayed.
# Two parallel arrays — keys and widgets — paired by index. Bindings get
# installed across emacs / viins / vicmd so the binding works in whatever
# mode you're in (the user lives in viins via zsh-vi-mode; without this,
# ^X^S etc. silently bind to `undefined-key` outside emacs).
typeset -ga _BINDKEY_PERSISTENT_KEYS
typeset -ga _BINDKEY_PERSISTENT_WIDGETS
_bindkey_persistent_install_one() {
  local key="$1" widget="$2" km
  for km in emacs viins vicmd; do
    bindkey -M $km "$key" "$widget" 2>/dev/null
  done
}
bindkey_persistent() {
  _bindkey_persistent_install_one "$1" "$2"
  _BINDKEY_PERSISTENT_KEYS+=("$1")
  _BINDKEY_PERSISTENT_WIDGETS+=("$2")
  # zsh-vi-mode rebuilds keymaps on init — queue the bindkey calls so it
  # re-applies them. ${(qq)…} double-quotes so EXTENDED_GLOB can't expand
  # `^X^S`-style strings into glob negations during eval.
  typeset -ga zvm_after_init_commands
  zvm_after_init_commands+=(
    "bindkey -M emacs ${(qq)1} ${(qq)2}"
    "bindkey -M viins ${(qq)1} ${(qq)2}"
    "bindkey -M vicmd ${(qq)1} ${(qq)2}"
  )
}
_bindkey_persistent_reapply() {
  local i
  for i in {1..${#_BINDKEY_PERSISTENT_KEYS}}; do
    _bindkey_persistent_install_one \
      "$_BINDKEY_PERSISTENT_KEYS[i]" \
      "$_BINDKEY_PERSISTENT_WIDGETS[i]"
  done
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _bindkey_persistent_reapply

zbench() {
  local n="${1:-10}" i out total=0 best=99999 worst=0 v
  local -a runs
  for ((i=1; i<=n; i++)); do
    v=$( { /usr/bin/time -p zsh -i -c exit } 2>&1 | awk '/real/ {print $2*1000}' )
    runs+=("$v")
    (( total += v ))
    (( v < best )) && best=$v
    (( v > worst )) && worst=$v
  done
  out=$(printf '%s\n' "${runs[@]}" | sort -n | awk -v n=$n 'NR==int((n+1)/2){print}')
  printf 'runs=%d  median=%dms  best=%dms  worst=%dms  mean=%dms\n' \
    "$n" "$out" "$best" "$worst" $(( total / n ))
}
