# ──────────────────────────────────────────────────────────
# MODERN CLI REPLACEMENTS
# ──────────────────────────────────────────────────────────

alias cat='bat --paging=never'
alias grep='rg'
alias rg-bat='batgrep'

# eza family
# ── Base listings ─────────────────────────────────────────
alias ls='eza --icons --group-directories-first --hyperlink'
alias l='eza --icons --group-directories-first --hyperlink'
alias ll='eza -lh --icons --git --group-directories-first --time-style=relative --hyperlink'
alias la='eza -lah --icons --git --group-directories-first --time-style=relative --hyperlink'
alias ld='eza -lhD --icons --git --hyperlink'                  # dirs only
# ── Trees ─────────────────────────────────────────────────
alias lt='eza --tree --level=2 --icons --git-ignore --hyperlink'
alias lt3='eza --tree --level=3 --icons --git-ignore --hyperlink'
alias lta='eza --tree --level=2 -a --icons --hyperlink'
# ── Sort matrix ───────────────────────────────────────────
# Naming: l<key>[r] — key = S(ize) m(odified) c(reated) u(sed/atime) n(ame) x(extension)
#                     r suffix = reverse. Prefix `la` = include hidden.
# Default direction matches what a human means: "biggest", "newest", "alphabetical".
_eza_sort='eza -lh --icons --git --time-style=relative --hyperlink --sort'
alias lS="$_eza_sort=size --reverse"         # largest first
alias lSr="$_eza_sort=size"                   # smallest first
alias lm="$_eza_sort=modified --reverse"      # newest modified first
alias lmr="$_eza_sort=modified"               # oldest modified first
alias lc="$_eza_sort=created --reverse"       # newest created first
alias lcr="$_eza_sort=created"                # oldest created first
alias lu="$_eza_sort=accessed --reverse"      # most recently accessed first
alias lur="$_eza_sort=accessed"               # least recently accessed first
alias lN="$_eza_sort=name"                    # a → z   (capital N: lowercase ln is /bin/ln)
alias lNr="$_eza_sort=name --reverse"         # z → a
alias lx="$_eza_sort=extension"               # grouped by file extension
# Hidden-file variants for the three you'll reach for most
alias laS="$_eza_sort=size --reverse -a"
alias lam="$_eza_sort=modified --reverse -a"
alias lac="$_eza_sort=created --reverse -a"
unset _eza_sort

# System inspectors
alias top='btop'
alias du='dust'
alias df='duf'
alias ps='procs'
alias ping='gping'
alias dig='dog'
alias help='tldr'

# Editor
alias vi='nvim'
alias vim='nvim'

# ──────────────────────────────────────────────────────────
# NAVIGATION & QUICK JUMPS
# ──────────────────────────────────────────────────────────

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias d='dirs -v'                                   # pushd stack
alias q='cd ~/Documents/GitHub'

# ──────────────────────────────────────────────────────────
# ZSHRC EDIT / RELOAD
# ──────────────────────────────────────────────────────────

alias zrc='${EDITOR:-nvim} ~/.zshrc'
alias zrr='exec zsh'

# ──────────────────────────────────────────────────────────
# YAZI (terminal file manager)
# Use `y` (function in functions.zsh) instead of bare `yazi`:
# it cd's the shell into the directory you exit in.
# ──────────────────────────────────────────────────────────

alias yz='yazi'                                     # raw yazi (no cwd-sync)
alias yc='${EDITOR:-nvim} ~/.config/yazi/yazi.toml' # edit yazi config

# ──────────────────────────────────────────────────────────
# CLAUDE / CODE
# ──────────────────────────────────────────────────────────

alias c='claude'
alias ch='claude --chrome'
alias co='code'

# ──────────────────────────────────────────────────────────
# GIT
# ──────────────────────────────────────────────────────────

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcoback='git checkout -'
alias gsw='git switch'
alias gswc='git switch -c'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gp='git push'
alias gpub='git push -u origin HEAD'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase'
alias gfa='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate --all -20'
alias glol="git log --pretty=format:'%C(auto)%h%d %s %C(244)%cr %C(cyan)<%an>%C(reset)' --graph"
alias gst='git stash'
alias gsp='git stash pop'
alias grh='git reset --hard'
alias gclean='git clean -fd'
alias gwt='git worktree'
alias gcp='git cherry-pick'
alias wip='git add -A && git commit -m "wip"'
alias lg='lazygit'

# gh CLI
alias ghpr='gh pr create --web'
alias ghprs='gh pr list'
alias ghrepo='gh repo view --web'
alias ghrun='gh run watch'

# ──────────────────────────────────────────────────────────
# TMUX
# ──────────────────────────────────────────────────────────

alias tm='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tls='tmux ls'
alias tk='tmux kill-session -t'
alias tka='tmux kill-server'

# ──────────────────────────────────────────────────────────
# DOCKER
# ──────────────────────────────────────────────────────────

alias dk='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias lzd='lazydocker'

# ──────────────────────────────────────────────────────────
# MACOS QOL
# ──────────────────────────────────────────────────────────

alias o='open .'
alias oa='open -a'
alias pbc='pbcopy'
alias pbv='pbpaste'

alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias lock='pmset displaysleepnow'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'

alias brewup='brew update && brew upgrade && brew cleanup && brew doctor'
alias dsclean='find . -name ".DS_Store" -type f -delete'

# ──────────────────────────────────────────────────────────
# NETWORK / SYSTEM
# ──────────────────────────────────────────────────────────

alias myip='curl -s https://ifconfig.me; echo'
alias localip="ipconfig getifaddr en0"
alias ports='lsof -i -P -n | grep LISTEN'
alias serve='python3 -m http.server'
alias jsonpp='python3 -m json.tool'

# ──────────────────────────────────────────────────────────
# FZF POWER ENTRYPOINTS (functions live in functions.zsh)
# ──────────────────────────────────────────────────────────
# Reminder (no alias needed): atuin owns ^R, fzf-tab owns <TAB>,
# Ctrl-T = file picker, Alt-C = dir picker, Ctrl-/ toggles preview,
# Ctrl-Y inside fzf copies the highlighted line to the clipboard.

alias f='fe'          # fuzzy edit file
alias fk='killp'      # fuzzy kill processes
# Use `fbr` / `fco` / `fshow` / `frg` / `fenv` directly — no shortened alias,
# to avoid shadowing shell builtins like `fg` (job control).

# ──────────────────────────────────────────────────────────
# ZSH GLOBAL ALIASES (expand anywhere in command line)
# Examples:
#   ls -la G config       →  ls -la | rg config
#   pwd GC                →  copy cwd to clipboard
#   find . NE             →  silence permission errors
# ──────────────────────────────────────────────────────────

alias -g G='| rg'
alias -g L='| less'
alias -g H='| head'
alias -g T='| tail'
alias -g GC='| pbcopy'
alias -g NE='2>/dev/null'
alias -g NUL='>/dev/null 2>&1'

# ──────────────────────────────────────────────────────────
# ZSH SUFFIX ALIASES (filename alone opens it with the right tool)
# Examples:  `~/.zshrc<Enter>` opens nvim
#            `report.pdf<Enter>` opens Preview
# ──────────────────────────────────────────────────────────

alias -s {md,txt,log,conf,cfg,json,yaml,yml,toml,ini,env}=nvim
alias -s {html,pdf,png,jpg,jpeg,gif}=open
alias -s {tar,gz,bz2,xz,zip,7z}=extract

alias quickbak='_bak(){ cp "$1" "$1.$(date +%Y%m%d).bak" }; _bak'

