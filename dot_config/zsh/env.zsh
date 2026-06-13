# ──────────────────────────────────────────────────────────
# PATH / ENV
# ──────────────────────────────────────────────────────────

typeset -U path PATH                                # dedupe PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"

# ── Pager stack ────────────────────────────────────────────
# less is the scroller; batpipe syntax-highlights file args;
# --use-color colorizes less's own chrome (status, prompts, search).
export LESS="--RAW-CONTROL-CHARS --quit-if-one-screen --mouse --wheel-lines=3 \
--incsearch --ignore-case --tabs=4 --LONG-PROMPT --status-column \
--use-color -DSkY -DEkc -DPkc -DMkc -DNkc -DBkY -DHkY -DWkY"
export PAGER="less"
export BAT_PAGER="less $LESS"

# less <file> → bat syntax highlighting (transparent, via LESSOPEN).
# Uses bat directly; batpipe's parent-process detection misses less on macOS,
# which strips color. `|` prefix → fall back to raw file if bat outputs nothing.
export LESSOPEN='|/opt/homebrew/bin/bat --color=always --style=plain --paging=never -- %s 2>/dev/null'
unset LESSCLOSE BATPIPE

# DB pagers — column-aware, freezes header row
export PSQL_PAGER="pspg --style=21 --bold-labels --no-mouse"
export PAGER_FOR_MYSQL="pspg --style=21 --bold-labels"

export BREW_PREFIX="/opt/homebrew"

# Color support
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"

# GNU coreutils on PATH (overrides BSD versions on macOS)
# These come with `brew install coreutils gnu-sed gawk`
export PATH="$BREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$BREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="$BREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"

# Man pages: bat handles syntax highlighting; less handles paging via $LESS.
# (batman doesn't compose with macOS BSD man, so we wire bat directly.)
export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain --color=always --paging=always'"

# Atuin: skip writing certain prefixes to history
export ATUIN_NOBIND="false"

# Catppuccin flavor — set globally, switch with: catppuccin [frappe|latte|macchiato|mocha]
export CATPPUCCIN_FLAVOR="$(cat ~/.config/catppuccin-flavor 2>/dev/null || echo mocha)"

# LS_COLORS via vivid (catppuccin variant). eza, ls, fzf-tab previews, and
# every completion menu inherit these colors. Falls back silently if vivid
# isn't installed — keeps the cold-start path working on a fresh machine.
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate catppuccin-$CATPPUCCIN_FLAVOR 2>/dev/null)"
fi

# glow / glamour markdown rendering — flavor-driven JSON style.
[[ -f $HOME/.config/glow/catppuccin-$CATPPUCCIN_FLAVOR.json ]] && \
  export GLAMOUR_STYLE="$HOME/.config/glow/catppuccin-$CATPPUCCIN_FLAVOR.json"

# bat default theme follows the flavor too (already configured via bat
# config file, but the env var is a fallback if config is missing).
case $CATPPUCCIN_FLAVOR in
  mocha)     export BAT_THEME="Catppuccin Mocha" ;;
  frappe)    export BAT_THEME="Catppuccin Frappe" ;;
  latte)     export BAT_THEME="Catppuccin Latte" ;;
  macchiato) export BAT_THEME="Catppuccin Macchiato" ;;
esac

export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"

export TEALDEER_CONFIG_DIR="$HOME/.config/tealdeer"

# Secrets live in ~/.config/zsh/secrets.zsh (sourced from ~/.zshrc, chmod 600).

