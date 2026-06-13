# ──────────────────────────────────────────────────────────
# ZSH OPTIONS, COMPLETION, KEYBINDINGS
# ──────────────────────────────────────────────────────────

bindkey -e                                          # emacs keybindings

# Disable XON/XOFF flow control so ^S / ^Q reach ZLE instead of being eaten
# by the tty driver. Required for any binding that uses ^S (e.g. ^X^S sesh
# picker — without this, the kernel intercepts ^S as "pause output").
[[ -o interactive ]] && stty -ixon -ixoff 2>/dev/null

# Behavior
setopt AUTO_CD                                      # 'src' alone cds to ./src
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_PUSHD                                   # cd onto a directory stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB                                # ^, ~, # in globs
setopt NUMERIC_GLOB_SORT
setopt NO_CASE_GLOB                                 # case-insensitive globs
setopt INTERACTIVE_COMMENTS                         # # comments in interactive shell
setopt NO_BEEP
setopt NOTIFY                                       # bg job status immediately
setopt LIST_PACKED                                  # compact completion menus

# History
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$HOME/.zsh_history"

setopt EXTENDED_HISTORY                             # timestamp + duration
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY                                  # confirm before running !! / !$
setopt HIST_IGNORE_SPACE                            # leading space → don't save
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY_TIME

# Completion system
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*' \
  '+l:|=*'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'
zstyle ':completion:*:*:*:*:processes' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# Extra completions: docker (installed by Docker Desktop). Add others here.
[[ -d ~/.docker/completions ]] && fpath=(~/.docker/completions $fpath)

# Compinit needs its cache dir to exist.
[[ -d ~/.zsh/cache ]] || mkdir -p ~/.zsh/cache

# Daily-rotated compinit: full path (with security audit) at most once per
# 24h, fast `-C` skip the rest of the time. The trailing `&!` zcompiles the
# dump in the background so the next shell parses it as bytecode.
autoload -Uz compinit
{
  local zcd=~/.zsh/cache/.zcompdump
  if [[ -n $zcd(#qN.mh+24) || ! -s $zcd ]]; then
    compinit -d $zcd
  else
    compinit -C -d $zcd
  fi
  { [[ -s $zcd && (! -s $zcd.zwc || $zcd -nt $zcd.zwc) ]] && zcompile $zcd } &!
}

# Custom widgets
edit_zshrc()   { BUFFER="${EDITOR:-nvim} ~/.zshrc"; zle accept-line; }
reload_zshrc() { BUFFER="exec zsh"; zle accept-line; }
zle -N edit_zshrc
zle -N reload_zshrc
bindkey_persistent '^X^Z' edit_zshrc                # Ctrl-X Ctrl-Z → edit
bindkey_persistent '^X^R' reload_zshrc              # Ctrl-X Ctrl-R → reload

# Edit current command line in $EDITOR (Ctrl-X Ctrl-F)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey_persistent '^X^F' edit-command-line
