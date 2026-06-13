# ──────────────────────────────────────────────────────────
# PLUGIN LOADING — three-tier architecture.
#
#  Tier A (sync, cached) — anything that injects $PATH, defines top-level
#    commands, or must be live before the first keystroke. Fed from
#    `zsh_eval_cache` (cache.zsh) so the sync cost is `source` of a
#    static file, not a fork.
#
#  Tier B (deferred via zsh-defer) — plugins that only add ZLE widgets,
#    completion hooks, syntax overlays, or precmd hooks. No risk of
#    "command not found" before they load — the keys themselves work.
#
#  Tier C (lazy stubs) — plugins that ADD commands you call by name
#    (forgit, fzf-git, navi). Stub functions / one-shot widgets load
#    the real plugin on first invocation, then re-fire to keep UX seamless.
#
# Load order within each tier is significant — see comments inline.
# ──────────────────────────────────────────────────────────

# ── zsh-defer (lazy-loading helper) ───────────────────────────────────
# Source FIRST so subsequent `zsh-defer …` calls queue up. Vendored in
# ~/.config/zsh/plugins/zsh-defer (upstream doesn't ship via Homebrew).
# Fallback: if missing, alias `zsh-defer` to a sync `source` so calls don't
# explode — degrades gracefully to pre-defer behavior.
if [[ -r "$HOME/.config/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  source "$HOME/.config/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh"
else
  zsh-defer() { "$@" }
fi

# ──────────────────────────────────────────────────────────
# Tier A — sync, cached. Required before first prompt or first keystroke.
# ──────────────────────────────────────────────────────────

# Prompt — must render before user sees anything.
zsh_eval_cache oh-my-posh oh-my-posh init zsh --config ~/.config/ohmyposh/config.json

# zoxide — adds `z`/`j` top-level commands.
zsh_eval_cache zoxide zoxide init zsh
alias j="z"

# mise — injects shims into PATH. NEVER defer (nvm-style trap).
zsh_eval_cache mise mise activate zsh

# direnv — hooks chpwd. If you cd before it loads, .envrc misses.
zsh_eval_cache direnv direnv hook zsh

# Atuin — owns ^R from the first prompt.
zsh_eval_cache atuin atuin init zsh

# Atuin ownership of ^R, asserted on every prompt so no later plugin can
# steal it (fzf re-binds on empty buffer in some session configurations).
autoload -Uz add-zsh-hook
_atuin_own_ctrl_r() { bindkey '^r' atuin-search 2>/dev/null }
add-zsh-hook precmd _atuin_own_ctrl_r

# ──────────────────────────────────────────────────────────
# FZF — env vars must be set BEFORE fzf key-bindings load (Tier B).
# Theme file (Catppuccin) sets FZF_DEFAULT_OPTS by itself; source it
# FIRST, then APPEND our layout. The other order silently clobbers.
# ──────────────────────────────────────────────────────────
source "$HOME/.config/fzf/themes/catppucin/themes/catppuccin-fzf-mocha.sh"

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--tmux center,90%,75% \
--height=~70% \
--layout=reverse \
--info=inline-right \
--border=rounded \
--padding=0,1 \
--margin=0 \
--ansi \
--multi \
--cycle \
--scroll-off=5 \
--tabstop=2 \
--prompt='❯ ' \
--pointer='▶' \
--marker='✓' \
--separator='─' \
--header-border=horizontal \
--preview-window='right,60%,wrap,border-left' \
--bind='ctrl-/:change-preview-window(down,75%|hidden|right,60%)' \
--bind='ctrl-u:preview-half-page-up' \
--bind='ctrl-d:preview-half-page-down' \
--bind='ctrl-y:execute-silent(echo -n {} | pbcopy)+abort' \
--bind='ctrl-o:execute-silent(open {})' \
--bind='ctrl-e:become(\${EDITOR:-nvim} {})' \
--bind='alt-a:select-all,alt-d:deselect-all,alt-t:toggle-all' \
--bind='?:toggle-preview' \
--color='border:#45475a,preview-border:#45475a,header:#cba6f7,info:#fab387,prompt:#89b4fa,pointer:#f38ba8,marker:#a6e3a1'"

# Native walker is in-process; no fork per keystroke. fd stays the fallback
# for hand-rolled pipelines (frg, fbr, etc.).
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="--walker=file,hidden,follow --walker-skip=.git,node_modules,.venv,target,dist,build --preview 'bat --style=numbers --color=always --line-range=:300 {}'"
export FZF_ALT_C_OPTS="--walker=dir,hidden,follow --walker-skip=.git,node_modules,.venv --preview 'eza --tree --color=always --icons --level=2 {} | head -200'"

# ──────────────────────────────────────────────────────────
# Tier B — deferred. Pure widget/hook/completion plugins.
# Load order within the deferred queue matters: compsys-extenders
# (carapace, fzf-tab) before ZLE-hookers (autosuggest, syntax-highlight),
# vi-mode last because it rewrites ZLE.
# ──────────────────────────────────────────────────────────

# fzf key-bindings (^T file, Alt-c dir) + completion (**<TAB>).
# fzf's own cleanup eval re-emits read-only options — harmless, noisy.
zsh-defer source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" 2>/dev/null
zsh-defer source "$BREW_PREFIX/opt/fzf/shell/completion.zsh" 2>/dev/null

# Carapace — ~1000 CLI completions. compinit already ran (Tier A sync via
# options.zsh), so safe to defer.
export CARAPACE_BRIDGES='zsh,fish,bash'
zsh-defer eval 'source <(carapace _carapace zsh)'

# fzf-tab — replaces compsys's TAB menu with a fzf picker. Needs compinit
# done first. Stays consistent with FZF_DEFAULT_OPTS.
zsh-defer source "$BREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' show-group brief
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 20
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' continuous-trigger 'ctrl-space'
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --inline-info
# Don't override accept-line — space inside fzf picker is fzf's filter
# character, not "accept and add space". Default (Enter accepts) is fine.
# Universal preview: dir → eza tree, file → bat, else echo the word.
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [[ -d $realpath ]]; then eza --tree --color=always --icons --level=2 $realpath 2>/dev/null
  elif [[ -f $realpath ]]; then bat --style=numbers --color=always --line-range=:300 $realpath 2>/dev/null
  else echo ${(P)word} 2>/dev/null || echo $word; fi'
# Per-command overrides (kept from the prior config — these are tuned).
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza --tree --color=always --level=2 $realpath 2>/dev/null | head -200'
zstyle ':fzf-tab:complete:(bat|cat|less|nvim|vim|vi|code):*' fzf-preview \
  'bat --style=numbers --color=always --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  'ps -p $word -o pid,ppid,user,%cpu,%mem,start,time,command 2>/dev/null'
zstyle ':fzf-tab:complete:(\\\\|*/|)(ls|eza|cp|mv|rm|ln|chmod|chown|du|file|stat):*' fzf-preview \
  '[[ -d $realpath ]] && eza --tree --color=always --icons --level=2 $realpath || bat --style=numbers --color=always --line-range=:300 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:git-(add|diff|restore|stash):*' fzf-preview \
  'git diff --color=always -- $word | delta 2>/dev/null || git diff --color=always -- $word'
zstyle ':fzf-tab:complete:git-(checkout|switch|log|show|reset|rebase|merge|cherry-pick|branch):*' fzf-preview \
  'git log --color=always --oneline --graph --decorate --abbrev-commit $word 2>/dev/null | head -200'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
  'git help $word | bat -p --color=always --language=man'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
  fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:ssh:*' fzf-preview \
  'dig +short $word 2>/dev/null; echo; getent hosts $word 2>/dev/null'
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info|home|reinstall):*-argument-rest' \
  fzf-preview 'brew info $word'
zstyle ':fzf-tab:complete:tldr:argument-rest' fzf-preview 'tldr --color=always $word'
zstyle ':fzf-tab:complete:man:*' fzf-preview \
  'MANPAGER="sh -c \"col -bx | bat --language=man --style=plain --color=always\"" man $word 2>/dev/null'

# zsh-abbr — fish-style abbreviations. Default storage path is
# ~/.config/zsh/abbreviations, which matches our seed file. ABBR_QUIETER
# suppresses "would replace existing command" warnings on startup so
# abbreviations that intentionally shadow our aliases (e.g. gco→git
# checkout, where alias gco also exists) load without log spam.
typeset -gi ABBR_QUIETER=1
zsh-defer source "$BREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh"

# zsh-autopair — auto-close (), [], {}, '', "".
zsh-defer source "$BREW_PREFIX/share/zsh-autopair/autopair.zsh"

# zsh-you-should-use — reminds when a defined alias was bypassed.
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL
# Silence reminders for the eza family — `ls`/`l`/`la`/`ll`/`lt`/`ld`
# share long flag sets, so YSU nags every time you call eza directly.
# Also silence the sort-matrix aliases (lS/lm/lc/...) for the same reason.
export YSU_IGNORED_ALIASES=(
  l ls la ll ld lt lt3 lta
  lS lSr lm lmr lc lcr lu lur lN lNr lx laS lam lac
  cat grep
  vi vim
)
zsh-defer source "$BREW_PREFIX/share/zsh-you-should-use/you-should-use.plugin.zsh"

# zsh-autosuggestions — async strategy keeps the matcher off the input
# thread. Catppuccin overlay0 stays visible without competing with text.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(forward-word end-of-line vi-forward-char vi-end-of-line vi-add-eol)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(forward-word vi-forward-word vi-forward-word-end)
zsh-defer source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlight — must be the last ZLE-hooker before vi-mode.
zsh-defer source "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# zsh-vi-mode — rewrites ZLE. Restore critical bindings in zvm_after_init.
ZVM_INIT_MODE=sourcing
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
ZVM_VI_HIGHLIGHT_BACKGROUND='#45475a'
ZVM_VI_HIGHLIGHT_FOREGROUND='#cdd6f4'
ZVM_CURSOR_STYLE_ENABLED=true
export OMP_VI_MODE="INSERT"

function zvm_after_init() {
  # Only restore the keys vi-mode actually clobbers (^T, Alt-c). ^R is owned
  # by the precmd hook above so we don't touch it here. We do NOT re-source
  # fzf key-bindings.zsh — it's heavy and the targeted rebinds suffice.
  bindkey '^T' fzf-file-widget 2>/dev/null
  bindkey '\ec' fzf-cd-widget 2>/dev/null
}

function zvm_after_select_vi_mode() {
  case $ZVM_MODE in
    $ZVM_MODE_NORMAL)      export OMP_VI_MODE="NORMAL"  ;;
    $ZVM_MODE_INSERT)      export OMP_VI_MODE="INSERT"  ;;
    $ZVM_MODE_VISUAL)      export OMP_VI_MODE="VISUAL"  ;;
    $ZVM_MODE_VISUAL_LINE) export OMP_VI_MODE="V-LINE"  ;;
    $ZVM_MODE_REPLACE)     export OMP_VI_MODE="REPLACE" ;;
  esac
  PS1="$(${_omp_executable:-oh-my-posh} print primary \
    --shell=zsh \
    --shell-version="$ZSH_VERSION" \
    --status=${_omp_status:-0} \
    --no-status=${_omp_no_status:-true} \
    --execution-time=${_omp_execution_time:--1} \
    --terminal-width="${COLUMNS:-0}" \
    2>/dev/null)"
  zle reset-prompt 2>/dev/null
}

zsh-defer source "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

# fzf-git.sh — queued AFTER zsh-vi-mode so its ^g^* chords bind on top of
# vi-mode's keymaps (emacs/viins/vicmd). fzf-git.sh's own init function
# (__fzf_git_init) iterates all three keymaps and installs both forms
# `^g^x` and `^gx` — we don't need to re-assert anything. The script is
# pure function-defs + bindkey calls, so sourcing it via defer is cheap.
zsh-defer source "$HOME/.config/fzf-git/fzf-git.sh"

# navi widget — `navi widget zsh` emits the `_navi_widget` ZLE widget and
# binds it to ^G, which would clobber fzf-git's chord prefix. Source it,
# yank the ^G binding navi installed, and move the widget to ^X^N (a free
# chord). Then re-source fzf-git so its ^g^* keymaps win the race.
zsh-defer eval '
  builtin eval "$(navi widget zsh 2>/dev/null)"
  for _km in emacs viins vicmd; do
    bindkey -M $_km -r "^G" 2>/dev/null
    bindkey -M $_km "^X^N" _navi_widget 2>/dev/null
  done
  unset _km
  source "$HOME/.config/fzf-git/fzf-git.sh"
'

# ──────────────────────────────────────────────────────────
# Tier C — lazy stubs for plugins that ADD top-level command names.
# ──────────────────────────────────────────────────────────

# forgit — interactive git workflows. Several forgit command names collide
# with aliases.zsh (gclean, gcp, gco, gss, ga). To avoid surprising the
# user — and to avoid the eval-vs-alias parse error during stub creation —
# we expose forgit commands under a `f`-prefixed namespace:
#   forgit_log   → fgl     forgit_diff   → fgd     forgit_add → fga
#   forgit_branch_delete → fgbd            forgit_revert_commit → fgrc
#   forgit_checkout_branch → fgcb         forgit_checkout_file → fgcf
#   forgit_stash_show → fgss              forgit_stash_push → fgsp
#   forgit_clean → fgclean                forgit_cherry_pick → fgcp
#   forgit_ignore → fgi                   forgit_reset_head → fgrh
# Stubs are pure functions (no alias collision possible).
_forgit_lazy_load() {
  unset -f fga fgd fgl fgi fgcf fgrh fgcb fgco fgss fgsp fgclean fgcp fgbd fgrc 2>/dev/null
  source "$BREW_PREFIX/share/forgit/forgit.plugin.zsh"
  # Map our fg* stubs onto forgit's actual function names so the second
  # invocation reaches forgit directly.
  fga()       { forgit_add "$@" }
  fgd()       { forgit_diff "$@" }
  fgl()       { forgit_log "$@" }
  fgi()       { forgit_ignore "$@" }
  fgcf()      { forgit_checkout_file "$@" }
  fgrh()      { forgit_reset_head "$@" }
  fgcb()      { forgit_checkout_branch "$@" }
  fgco()      { forgit_checkout_commit "$@" }
  fgss()      { forgit_stash_show "$@" }
  fgsp()      { forgit_stash_push "$@" }
  fgclean()   { forgit_clean "$@" }
  fgcp()      { forgit_cherry_pick "$@" }
  fgbd()      { forgit_branch_delete "$@" }
  fgrc()      { forgit_revert_commit "$@" }
}
for _cmd in fga fgd fgl fgi fgcf fgrh fgcb fgco fgss fgsp fgclean fgcp fgbd fgrc; do
  functions[$_cmd]="_forgit_lazy_load && $_cmd \"\$@\""
done
unset _cmd

# (fzf-git and navi are sourced via zsh-defer above, AFTER zsh-vi-mode,
# so their bindings land cleanly across all keymaps. No lazy stub needed
# since both are pure widget plugins, not new top-level commands.)
