# ──────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ──────────────────────────────────────────────────────────

# mkdir + cd
mkcd() { mkdir -p "$1" && cd "$1"; }

# Universal archive extractor
extract() {
  if [[ ! -f "$1" ]]; then echo "extract: '$1' not found"; return 1; fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.zip)            unzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.xz)             unxz "$1" ;;
    *.Z)              uncompress "$1" ;;
    *)                echo "extract: don't know how to extract '$1'"; return 1 ;;
  esac
}

# Clone-and-cd, or mkcd, depending on arg
take() {
  if [[ "$1" =~ ^(git@|https?://) ]]; then
    git clone "$1" && cd "$(basename "$1" .git)"
  else
    mkcd "$1"
  fi
}

# Edit a file, creating parent directories if missing
vmk() {
  [[ -z "$1" ]] && { echo "usage: vmk <path>"; return 1; }
  mkdir -p "${1:h}" && nvim "$1"
}

# tmux attach-if-exists / create-if-not
ts() { tmux attach -t "${1:-main}" 2>/dev/null || tmux new -s "${1:-main}"; }

# Yazi with cwd-sync: when you quit, the shell cd's to wherever you ended up.
# Use `y` instead of `yazi` directly. Bound to Ctrl-X Ctrl-Y as a ZLE widget.
y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return
  fi
  command rm -f -- "$tmp"
}
_y_widget() { BUFFER="y"; zle accept-line; }
zle -N _y_widget
bindkey_persistent '^X^Y' _y_widget                 # Ctrl-X Ctrl-Y → launch yazi

# ──────────────────────────────────────────────────────────
# FZF POWER FUNCTIONS — all use fd / rg / bat / eza for previews.
# Naming: prefix `f` = "fuzzy". Aliases below in the FZF block.
# ──────────────────────────────────────────────────────────

# Fuzzy-pick a directory and cd into it
cdf() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git | \
    fzf --prompt='cd ❯ ' \
        --preview 'eza --tree --color=always --icons --level=2 {} | head -200') || return
  cd "$dir"
}

# Fuzzy-pick processes to kill (TAB for multi)
# Uses `command ps` to bypass our ps→procs alias (procs has a different flag set).
killp() {
  local pids
  pids=$(command ps -ef | sed 1d | \
    fzf -m --header='select procs to kill (TAB)' \
        --preview 'command ps -p $(echo {} | awk "{print \$2}") -o pid,ppid,user,%cpu,%mem,start,time,command' \
    | awk '{print $2}')
  [[ -n "$pids" ]] && echo "$pids" | xargs kill -9
}

# Fuzzy edit any file (respects .gitignore via fd, bat preview)
fe() {
  local file
  file=$(fd --type f --hidden --follow --exclude .git "${1:-.}" | \
    fzf --prompt='edit ❯ ' \
        --preview 'bat --style=numbers --color=always --line-range=:300 {}') || return
  ${EDITOR:-nvim} "$file"
}

# Live ripgrep with fzf — type to filter, ENTER opens in $EDITOR at the line.
# Requires: fzf >= 0.21, rg, bat, nvim.
frg() {
  local rg_cmd='rg --column --line-number --no-heading --color=always --smart-case '
  local out file line
  out=$(FZF_DEFAULT_COMMAND="$rg_cmd '' " \
    fzf --bind "change:reload:$rg_cmd {q} || true" \
        --ansi --disabled --query="${1:-}" \
        --prompt='rg ❯ ' \
        --delimiter : \
        --preview 'bat --color=always --style=numbers --highlight-line={2} {1}' \
        --preview-window 'right,60%,+{2}+3/3,~3') || return
  file=${out%%:*}
  line=$(echo "$out" | awk -F: '{print $2}')
  [[ -n "$file" ]] && ${EDITOR:-nvim} +"$line" "$file"
}

# Git: fuzzy switch branch (local + remote, strips origin/ prefix)
fbr() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ \
    --format='%(refname:short)') || return
  branch=$(echo "$branches" | fzf --prompt='switch ❯ ' --preview \
    'git log --color=always --oneline --graph --decorate --abbrev-commit {} | head -50') || return
  git switch "$branch"
}

# Git: fuzzy checkout local OR remote branch
fco() {
  local tags branches target
  tags=$(git tag    | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}')   || return
  branches=$(git branch --all | command grep -v HEAD | sed 's/.* //' | sed 's#remotes/[^/]*/##' \
    | sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}')      || return
  target=$( (echo "$branches"; echo "$tags") \
    | fzf --no-hscroll --no-multi -n 2 --ansi --prompt='checkout ❯ ') || return
  git checkout "$(echo "$target" | awk '{print $2}')"
}

# Git: fuzzy log browser with diff preview; ENTER = copy SHA to clipboard.
fshow() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr %C(cyan)<%an>%C(reset)" "$@" \
  | fzf --ansi --no-sort --reverse --tiebreak=index --prompt='log ❯ ' \
        --preview 'f() { set -- $(echo -- "$@" | command grep -o "[a-f0-9]\{7,\}"); [ $# -eq 0 ] || git show --color=always $1 | delta 2>/dev/null || git show --color=always $1; }; f {}' \
        --bind 'enter:execute:(command grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | tr -d "\n" | pbcopy) && echo "SHA copied"' \
        --bind 'ctrl-d:execute:(command grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | xargs -I% sh -c "git show --color=always %  | delta 2>/dev/null || git show --color=always %") | less -R'
}

# Fuzzy inspect environment variables (value preview)
# Filter to valid identifier names — `env`'s output can include continuation
# lines from multi-line values, which would otherwise pollute the list.
fenv() {
  local var
  var=$(env | awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' | sort -u \
    | fzf --prompt='env ❯ ' \
          --preview 'printenv {}' \
          --preview-window=down:6:wrap) || return
  printenv "$var"
}

# Fuzzy-pick a Ghostty shader with bat preview, swap it into the live config,
# and trigger a reload via the front Ghostty window's Cmd+Shift+, binding.
# Pick "NONE" to disable. Only lines between the BEGIN/END markers are managed,
# so any hand-written `custom-shader =` lines elsewhere in the config are left
# alone.
fshader() {
  local cfg="$HOME/.config/ghostty/config"
  local dir="$HOME/.config/ghostty/shaders"
  local begin='# >>> fshader-managed >>>'
  local end='# <<< fshader-managed <<<'
  # NOTE: don't name a local `path` — in zsh it's tied to $PATH and would
  # blank PATH for the rest of the function, breaking fd/fzf/bat lookups.
  local pick shader

  [[ -f "$cfg" ]] || { echo "fshader: $cfg missing"; return 1; }
  [[ -d "$dir" ]] || { echo "fshader: $dir missing"; return 1; }

  pick=$( {
    echo "NONE  (disable custom shader)"
    fd --type f -e glsl . "$dir" | sort | sed "s|^$HOME/|~/|"
  } | fzf --prompt='shader ❯ ' \
          --preview 'p={}; case "$p" in NONE*) echo "(disable custom shader)" ;; *) bat --color=always --style=numbers --line-range=:200 "${p/#\~/'"$HOME"'}" ;; esac' \
          --preview-window='right,60%,wrap') || return

  # GNU sed (env.zsh puts it ahead of BSD sed on PATH).
  sed -i -E "/^${begin}$/,/^${end}$/d" "$cfg"

  if [[ "$pick" != NONE* ]]; then
    shader="${pick/#\~/$HOME}"
    {
      echo ""
      echo "$begin"
      echo "custom-shader-animation = always"
      echo "custom-shader = $shader"
      echo "$end"
    } >> "$cfg"
  fi

  # Reload only works when Ghostty is frontmost — otherwise hit Cmd+Shift+, yourself.
  osascript -e 'tell application "System Events" to keystroke "," using {command down, shift down}' 2>/dev/null

  echo "→ ${pick%% *}"
}

# Weather (current location or pass a city)
weather() { curl -s "wttr.in/${1:-}?format=v2"; }

# Cheatsheet for any command
cheat() { curl -s "cheat.sh/$1"; }

# Password generator (default 32 chars)
genpw() { openssl rand -base64 "${1:-32}"; }

# Time a command
timecmd() { /usr/bin/time -p "$@"; }

# Find what's listening on a port
whatport() {
  [[ -z "$1" ]] && { echo "usage: whatport <port>"; return 1; }
  lsof -nP -iTCP:"$1" -sTCP:LISTEN
}

# URL encode/decode helpers (functions so they can take piped input)
urlencode() { python3 -c "import sys,urllib.parse as u; print(u.quote_plus(sys.argv[1]))" "$1"; }
urldecode() { python3 -c "import sys,urllib.parse as u; print(u.unquote_plus(sys.argv[1]))" "$1"; }

# ──────────────────────────────────────────────────────────
# CATPPUCCIN FLAVOR SWITCHER
# Usage: catppuccin [frappe|latte|macchiato|mocha]
# Propagates to: oh-my-posh, tmux, bat, delta, Ghostty, ccstatusline
# ──────────────────────────────────────────────────────────

_catppuccin_update_ghostty() {
  local flavor="$1"
  local cap="${(C)flavor}"
  local cfg=~/.config/ghostty/config

  local bg fg cursor cursor_text sel_bg sel_fg unfocused icon_ghost icon_screen
  local p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15

  case "$flavor" in
    mocha)
      bg="#1e1e2e"; fg="#cdd6f4"; cursor="#cba6f7"; cursor_text="#1e1e2e"
      sel_bg="#45475a"; sel_fg="#cdd6f4"; unfocused="#11111b"
      icon_ghost="#cba6f7"; icon_screen="#1e1e2e"
      p0="#45475a"; p1="#f38ba8"; p2="#a6e3a1"; p3="#f9e2af"
      p4="#89b4fa"; p5="#cba6f7"; p6="#94e2d5"; p7="#bac2de"
      p8="#585b70"; p9="#f38ba8"; p10="#a6e3a1"; p11="#f9e2af"
      p12="#89b4fa"; p13="#cba6f7"; p14="#94e2d5"; p15="#a6adc8"
      ;;
    frappe)
      bg="#303446"; fg="#c6d0f5"; cursor="#ca9ee6"; cursor_text="#303446"
      sel_bg="#51576d"; sel_fg="#c6d0f5"; unfocused="#232634"
      icon_ghost="#ca9ee6"; icon_screen="#303446"
      p0="#51576d"; p1="#e78284"; p2="#a6d189"; p3="#e5c890"
      p4="#8caaee"; p5="#ca9ee6"; p6="#81c8be"; p7="#b5bfe2"
      p8="#626880"; p9="#e78284"; p10="#a6d189"; p11="#e5c890"
      p12="#8caaee"; p13="#ca9ee6"; p14="#81c8be"; p15="#a5adce"
      ;;
    latte)
      bg="#eff1f5"; fg="#4c4f69"; cursor="#8839ef"; cursor_text="#eff1f5"
      sel_bg="#bcc0cc"; sel_fg="#4c4f69"; unfocused="#dce0e8"
      icon_ghost="#8839ef"; icon_screen="#eff1f5"
      p0="#bcc0cc"; p1="#d20f39"; p2="#40a02b"; p3="#df8e1d"
      p4="#1e66f5"; p5="#8839ef"; p6="#179299"; p7="#5c5f77"
      p8="#acb0be"; p9="#d20f39"; p10="#40a02b"; p11="#df8e1d"
      p12="#1e66f5"; p13="#8839ef"; p14="#179299"; p15="#6c6f85"
      ;;
    macchiato)
      bg="#24273a"; fg="#cad3f5"; cursor="#c6a0f6"; cursor_text="#24273a"
      sel_bg="#494d64"; sel_fg="#cad3f5"; unfocused="#181926"
      icon_ghost="#c6a0f6"; icon_screen="#24273a"
      p0="#494d64"; p1="#ed8796"; p2="#a6da95"; p3="#eed49f"
      p4="#8aadf4"; p5="#c6a0f6"; p6="#8bd5ca"; p7="#b8c0e0"
      p8="#5b6078"; p9="#ed8796"; p10="#a6da95"; p11="#eed49f"
      p12="#8aadf4"; p13="#c6a0f6"; p14="#8bd5ca"; p15="#a5adcb"
      ;;
  esac

  sed -i "s|^theme = .*|theme = Catppuccin $cap|" "$cfg"
  sed -i "s|^background = .*|background = $bg|" "$cfg"
  sed -i "s|^foreground = .*|foreground = $fg|" "$cfg"
  sed -i "s|^cursor-color = .*|cursor-color = $cursor|" "$cfg"
  sed -i "s|^cursor-text = .*|cursor-text = $cursor_text|" "$cfg"
  sed -i "s|^selection-background = .*|selection-background = $sel_bg|" "$cfg"
  sed -i "s|^selection-foreground = .*|selection-foreground = $sel_fg|" "$cfg"
  sed -i "s|^unfocused-split-fill = .*|unfocused-split-fill = $unfocused|" "$cfg"
  sed -i "s|^macos-icon-ghost-color = .*|macos-icon-ghost-color = $icon_ghost|" "$cfg"
  sed -i "s|^macos-icon-screen-color = .*|macos-icon-screen-color = $icon_screen|" "$cfg"
  sed -i "s|^palette = 0=.*|palette = 0=$p0|" "$cfg"
  sed -i "s|^palette = 1=.*|palette = 1=$p1|" "$cfg"
  sed -i "s|^palette = 2=.*|palette = 2=$p2|" "$cfg"
  sed -i "s|^palette = 3=.*|palette = 3=$p3|" "$cfg"
  sed -i "s|^palette = 4=.*|palette = 4=$p4|" "$cfg"
  sed -i "s|^palette = 5=.*|palette = 5=$p5|" "$cfg"
  sed -i "s|^palette = 6=.*|palette = 6=$p6|" "$cfg"
  sed -i "s|^palette = 7=.*|palette = 7=$p7|" "$cfg"
  sed -i "s|^palette = 8=.*|palette = 8=$p8|" "$cfg"
  sed -i "s|^palette = 9=.*|palette = 9=$p9|" "$cfg"
  sed -i "s|^palette = 10=.*|palette = 10=$p10|" "$cfg"
  sed -i "s|^palette = 11=.*|palette = 11=$p11|" "$cfg"
  sed -i "s|^palette = 12=.*|palette = 12=$p12|" "$cfg"
  sed -i "s|^palette = 13=.*|palette = 13=$p13|" "$cfg"
  sed -i "s|^palette = 14=.*|palette = 14=$p14|" "$cfg"
  sed -i "s|^palette = 15=.*|palette = 15=$p15|" "$cfg"

  ghostty +reload-config 2>/dev/null || true
}

_catppuccin_update_tealdeer() {
  local flavor="$1" text mauve teal rosewater sky
  case "$flavor" in
    mocha)     text="205,214,244"; mauve="203,166,247"; teal="148,226,213"; rosewater="245,224,220"; sky="137,220,235" ;;
    frappe)    text="198,208,245"; mauve="202,158,230"; teal="129,200,190"; rosewater="242,213,207"; sky="153,209,219" ;;
    latte)     text="76,79,105";   mauve="136,57,239";  teal="23,146,153";  rosewater="220,138,120"; sky="4,165,229"   ;;
    macchiato) text="202,211,245"; mauve="198,160,246"; teal="139,213,202"; rosewater="244,219,214"; sky="145,215,227" ;;
  esac
  local r g b
  _rgb() { r="${1%%,*}"; local rest="${1#*,}"; g="${rest%%,*}"; b="${rest##*,}" }
  local cfg=~/.config/tealdeer/config.toml
  # Use awk to rewrite each [style.NAME] block rgb values.
  awk -v T="$text" -v M="$mauve" -v TL="$teal" -v R="$rosewater" -v S="$sky" '
    BEGIN { split(T,t,","); split(M,m,","); split(TL,tl,","); split(R,r,","); split(S,s,",") }
    # Detect any [section] header; reset to empty for non-style blocks.
    /^\[/                             { in_blk = "" }
    /^\[style\.description\]/         { in_blk = "text" }
    /^\[style\.command_name\]/        { in_blk = "mauve" }
    /^\[style\.example_text\]/        { in_blk = "teal" }
    /^\[style\.example_code\]/        { in_blk = "rose" }
    /^\[style\.example_variable\]/    { in_blk = "sky" }
    /^foreground = / && in_blk!="" {
      if (in_blk=="text")  $0 = "foreground = { rgb = { r = " t[1]  ", g = " t[2]  ", b = " t[3]  " } }"
      if (in_blk=="mauve") $0 = "foreground = { rgb = { r = " m[1]  ", g = " m[2]  ", b = " m[3]  " } }"
      if (in_blk=="teal")  $0 = "foreground = { rgb = { r = " tl[1] ", g = " tl[2] ", b = " tl[3] " } }"
      if (in_blk=="rose")  $0 = "foreground = { rgb = { r = " r[1]  ", g = " r[2]  ", b = " r[3]  " } }"
      if (in_blk=="sky")   $0 = "foreground = { rgb = { r = " s[1]  ", g = " s[2]  ", b = " s[3]  " } }"
    }
    { print }
  ' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
}

_catppuccin_update_ccstatusline() {
  local flavor="$1"

  # Map flavor → ccstatusline hex colors (model, dir, git-branch, git-changes, ctx%, timer, sep)
  local model_color dir_color branch_color changes_color ctx_color sep_color timer_color
  case "$flavor" in
    mocha)
      model_color="cba6f7"; dir_color="89b4fa"; branch_color="94e2d5"
      changes_color="fab387"; ctx_color="f9e2af"; sep_color="7f849c"; timer_color="6c7086"
      ;;
    frappe)
      model_color="ca9ee6"; dir_color="8caaee"; branch_color="81c8be"
      changes_color="ef9f76"; ctx_color="e5c890"; sep_color="838ba7"; timer_color="737994"
      ;;
    latte)
      model_color="8839ef"; dir_color="1e66f5"; branch_color="179299"
      changes_color="fe640b"; ctx_color="df8e1d"; sep_color="8c8fa1"; timer_color="9ca0b0"
      ;;
    macchiato)
      model_color="c6a0f6"; dir_color="8aadf4"; branch_color="8bd5ca"
      changes_color="f5a97f"; ctx_color="eed49f"; sep_color="8087a2"; timer_color="6e738d"
      ;;
  esac

  cat > ~/.config/ccstatusline/settings.json <<EOF
{
  "version": 3,
  "lines": [
    [
      { "id": "1",  "type": "model", "color": "hex:${model_color}", "bold": true },
      { "id": "2",  "type": "separator", "color": "hex:${sep_color}", "metadata": { "character": "│" } },
      { "id": "3",  "type": "current-working-dir", "color": "hex:${dir_color}",
                    "metadata": { "abbreviateHome": "true", "segments": "3" } },
      { "id": "4",  "type": "separator", "color": "hex:${sep_color}", "metadata": { "character": "│" } },
      { "id": "5",  "type": "git-branch", "color": "hex:${branch_color}" },
      { "id": "6",  "type": "git-changes", "color": "hex:${changes_color}" },
      { "id": "7",  "type": "flex-separator" },
      { "id": "8",  "type": "context-percentage", "color": "hex:${ctx_color}" },
      { "id": "9",  "type": "separator", "color": "hex:${sep_color}", "metadata": { "character": "│" } },
      { "id": "10", "type": "block-timer", "color": "hex:${timer_color}" }
    ],
    [],
    []
  ],
  "flexMode": "full-minus-40",
  "compactThreshold": 60,
  "colorLevel": 3,
  "inheritSeparatorColors": false,
  "globalBold": false,
  "minimalistMode": false,
  "powerline": {
    "enabled": true,
    "separators": ["", ""],
    "separatorInvertBackground": [false],
    "startCaps": [""],
    "endCaps": [""],
    "autoAlign": true,
    "continueThemeAcrossLines": false
  }
}
EOF
}

catppuccin() {
  local flavor="${1:-mocha}"
  case "$flavor" in
    frappe|latte|macchiato|mocha) ;;
    *) echo "catppuccin: unknown flavor '$flavor'" >&2
       echo "usage: catppuccin [frappe|latte|macchiato|mocha]" >&2
       return 1 ;;
  esac

  local cap="${(C)flavor}"

  echo "$flavor" > ~/.config/catppuccin-flavor

  # bat
  sed -i "s|^--theme=.*|--theme=\"Catppuccin $cap\"|" ~/.config/bat/config

  # delta — features include catppuccin-<flavor> from the vendored
  # ~/.config/git/catppuccin-delta.gitconfig (included from ~/.gitconfig).
  # Swap which catppuccin-<flavor> is selected on the [delta] features line.
  sed -i -E "s|catppuccin-[a-z]+|catppuccin-$flavor|g" ~/.gitconfig
  # lazygit pagers reference the same feature; swap there too.
  sed -i -E "s|catppuccin-[a-z]+|catppuccin-$flavor|g" ~/.config/lazygit/config.yml

  # Ghostty
  _catppuccin_update_ghostty "$flavor"

  # ccstatusline
  _catppuccin_update_ccstatusline "$flavor"

  # yazi (file manager) — flavors live in ~/.config/yazi/flavors/catppuccin-*.yazi
  if [[ -f ~/.config/yazi/theme.toml ]]; then
    sed -i "s|^dark *= *.*|dark  = \"catppuccin-$flavor\"|"  ~/.config/yazi/theme.toml
    sed -i "s|^light *= *.*|light = \"catppuccin-$flavor\"|" ~/.config/yazi/theme.toml
  fi

  # fzf — swap the sourced theme file in plugins.zsh so a fresh shell picks
  # up the new flavor. (Existing shell already loaded the old one; exec zsh
  # at the end of catppuccin() re-sources cleanly.)
  if [[ -f ~/.config/fzf/themes/catppucin/themes/catppuccin-fzf-$flavor.sh ]]; then
    sed -i "s|catppuccin-fzf-[a-z]*\.sh|catppuccin-fzf-$flavor.sh|" \
      ~/.config/zsh/plugins.zsh
  fi

  # vivid → LS_COLORS. env.zsh re-exports on next shell from $CATPPUCCIN_FLAVOR.

  # eza — re-point ~/.config/eza/theme.yml symlink at the chosen flavor.
  if [[ -f ~/.config/eza/themes/catppuccin-$flavor.yml ]]; then
    ln -sf "themes/catppuccin-$flavor.yml" ~/.config/eza/theme.yml
  fi

  # tealdeer — regenerate [style.*] color blocks. Each flavor's palette
  # below maps to: description=Text, command_name=Mauve, example_text=Teal,
  # example_code=Rosewater, example_variable=Sky.
  if [[ -f ~/.config/tealdeer/config.toml ]]; then
    _catppuccin_update_tealdeer "$flavor"
  fi

  # lazygit — user's config.yml has a hand-rolled BEGIN/END
  # `catppuccin-managed` block using the OLD top-level `theme:` schema
  # (lazygit still accepts it). For each flavor we read the vendored
  # `mauve.yml` (matches user's chosen accent), strip the `gui:` wrapper
  # to align with their schema, and replace the managed block in-place.
  local lg_src=~/.config/lazygit/catppuccin/themes-mergable/$flavor/mauve.yml
  local lg_cfg=~/.config/lazygit/config.yml
  if command -v yq >/dev/null 2>&1 && [[ -f $lg_src && -f $lg_cfg ]]; then
    local managed_block
    # Extract `gui.theme` → top-level `theme` + `gui.authorColors` → top-level.
    managed_block=$(yq eval '.gui' "$lg_src" 2>/dev/null)
    if [[ -n $managed_block ]]; then
      {
        echo "# BEGIN catppuccin-managed"
        echo "# Flavor: ${(C)flavor} — regenerated by \`catppuccin\` switcher."
        echo "$managed_block"
        echo "# END catppuccin-managed"
      } > ~/.config/lazygit/.catppuccin-block.tmp
      # Splice the new block in between the markers in config.yml.
      awk -v new_file=~/.config/lazygit/.catppuccin-block.tmp '
        /^# BEGIN catppuccin-managed/ {
          while ((getline line < new_file) > 0) print line
          close(new_file)
          in_block = 1
          next
        }
        /^# END catppuccin-managed/ { in_block = 0; next }
        !in_block { print }
      ' "$lg_cfg" > "$lg_cfg.tmp" && mv "$lg_cfg.tmp" "$lg_cfg"
      command rm -f ~/.config/lazygit/.catppuccin-block.tmp
    fi
  fi

  # k9s — skin file. catppuccin/k9s ships skin-<flavor>.yml.
  if [[ -f ~/.config/k9s/skins/catppuccin-$flavor.yaml ]]; then
    sed -i "s|skin: catppuccin-[a-z]*|skin: catppuccin-$flavor|" \
      ~/.config/k9s/config.yaml 2>/dev/null
  fi

  # btop — theme env var on a one-line include.
  if [[ -f ~/.config/btop/themes/catppuccin_$flavor.theme ]]; then
    sed -i "s|^color_theme = .*|color_theme = \"catppuccin_$flavor\"|" \
      ~/.config/btop/btop.conf 2>/dev/null
  fi

  # gh-dash — has no theme-by-name field; it inlines colors under
  # theme.colors. yq-merge the chosen flavor's color block into the live
  # config.yml without touching theme.ui or anything else.
  local ghd_theme=~/.config/gh-dash/themes/catppuccin-$flavor-blue.yml
  if command -v yq >/dev/null 2>&1 && [[ -f ~/.config/gh-dash/config.yml && -f $ghd_theme ]]; then
    yq eval-all '. as $item ireduce ({}; . * $item)' \
      ~/.config/gh-dash/config.yml "$ghd_theme" \
      > ~/.config/gh-dash/config.yml.tmp \
      && mv ~/.config/gh-dash/config.yml.tmp ~/.config/gh-dash/config.yml
  fi

  # lazydocker, glow, navi: configs aren't checked in yet. When you add a
  # themed config for any of them, drop a matching `sed -i` here and the
  # next `catppuccin <flavor>` flips it atomically with everything else.

  # tmux
  if [[ -n "$TMUX" ]]; then
    tmux set-environment -g CATPPUCCIN_FLAVOR "$flavor"
    tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
  fi

  exec zsh
}

# ──────────────────────────────────────────────────────────
# oh-my-posh transient-prompt: capture the just-typed command line.
# preexec fires after Enter, before the command runs; the env var is read
# on the NEXT prompt render — which IS the transient render. Without this,
# the transient template has no way to show the command text.
# ──────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook
_omp_capture_command() { export OMP_LAST_COMMAND="$1"; }
add-zsh-hook preexec _omp_capture_command

# ──────────────────────────────────────────────────────────
# MORE FZF POWER FUNCTIONS — quick fuzzy entrypoints for the things
# you reach for daily. All inherit FZF_DEFAULT_OPTS so they pick up the
# Catppuccin colors, tmux popup mode, and shared keybinds.
# ──────────────────────────────────────────────────────────

# `man <cmd>` via fzf — `tldr` summary on top, ENTER opens full man page.
fhelp() {
  local cmd="$1"
  if [[ -z "$cmd" ]]; then
    cmd=$(apropos . 2>/dev/null | awk '{print $1}' | sort -u \
      | fzf --prompt='help ❯ ' \
            --preview 'tldr --color=always {} 2>/dev/null || whatis {}') || return
  fi
  ${PAGER:-less} =(tldr --color=always "$cmd" 2>/dev/null; echo; man "$cmd" 2>/dev/null)
}

# cheat.sh — pick a snippet for the given command and paste it on the line.
fcheat() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    print -z -- "$(curl -s "cheat.sh/:list" | fzf --prompt='cheat ❯ ' \
      --preview 'curl -s cheat.sh/{} | bat --color=always --plain')"
  else
    curl -s "cheat.sh/$cmd" | bat --color=always --plain --paging=always
  fi
}

# navi widget — interactive cheatsheet repl, picked snippet ends up on line.
fnavi() { eval "$(navi --fzf-overrides '--prompt=navi ❯ ' --print)" }

# fbrew / fbrew-rm — fuzzy install / uninstall any formula or cask.
fbrew() {
  local picks
  picks=$( { brew formulae; brew casks } | fzf -m \
    --prompt='brew install ❯ ' \
    --preview 'brew info {} 2>/dev/null') || return
  echo "$picks" | xargs brew install
}
fbrew-rm() {
  local picks
  picks=$(brew list -1 | fzf -m \
    --prompt='brew uninstall ❯ ' \
    --preview 'brew info {} 2>/dev/null') || return
  echo "$picks" | xargs brew uninstall
}

# fport — fuzzy LISTEN port → kill the PID.
fport() {
  local pid
  pid=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | sed 1d \
    | fzf --prompt='port ❯ ' \
          --header 'select a LISTEN process to inspect or kill (ENTER=kill, ^P=preview)' \
          --preview 'p=$(echo {} | awk "{print \$2}"); ps -p $p -o pid,ppid,user,%cpu,%mem,start,time,command' \
    | awk '{print $2}')
  [[ -n "$pid" ]] && { print -P "%F{yellow}killing $pid%f"; kill "$pid"; }
}
fkill-port() { fport "$@" }

# fdocker — pick a running container; ENTER shells in with sh/bash fallback.
fdocker() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}' \
    | fzf --prompt='docker ❯ ' \
          --header 'ENTER → exec shell in container' \
          --preview 'docker inspect {1} | bat --color=always --language=json --plain' \
    | awk '{print $1}')
  [[ -n "$cid" ]] && docker exec -it "$cid" sh -c "command -v bash >/dev/null && exec bash || exec sh"
}

# fkube — pick a k8s context, or with `-p` a pod and tail its logs.
fkube() {
  if [[ "$1" == "-p" ]]; then
    local pod
    pod=$(kubectl get pods --all-namespaces -o wide 2>/dev/null | sed 1d \
      | fzf --prompt='pod ❯ ' \
            --preview 'kubectl describe pod -n {1} {2} 2>/dev/null | head -200') || return
    local ns="$(echo "$pod" | awk '{print $1}')"
    local name="$(echo "$pod" | awk '{print $2}')"
    [[ -n "$name" ]] && kubectl logs -f -n "$ns" "$name"
  else
    local ctx
    ctx=$(kubectl config get-contexts -o name 2>/dev/null \
      | fzf --prompt='ctx ❯ ' \
            --preview 'kubectl config view --minify --context={} 2>/dev/null') || return
    kubectl config use-context "$ctx"
  fi
}

# fssh — pick an SSH host from ~/.ssh/config and known_hosts.
fssh() {
  local host
  host=$( {
    awk '/^Host / && $2 !~ /[*?]/ {for (i=2;i<=NF;i++) print $i}' ~/.ssh/config 2>/dev/null
    awk '{print $1}' ~/.ssh/known_hosts 2>/dev/null | tr ',' '\n' | sort -u
  } | sort -u | fzf --prompt='ssh ❯ ' \
                    --preview 'dig +short {} 2>/dev/null; echo; ssh -G {} 2>/dev/null | head -20') || return
  ssh "$host"
}

# fman — pick any installed man page; preview rendered through MANPAGER.
fman() {
  local page
  page=$(man -k . 2>/dev/null | awk '{print $1, $2}' \
    | fzf --prompt='man ❯ ' \
          --preview 'echo {1} | xargs man 2>/dev/null | col -bx | bat --language=man --color=always --style=plain') || return
  man $(echo "$page" | awk '{print $1}')
}

# fz — fuzzy zoxide (visible scores). z is fast; fz is for when you want to see.
fz() {
  local dir
  dir=$(zoxide query -ls 2>/dev/null \
    | fzf --prompt='z ❯ ' --nth=2.. \
          --preview 'eza --tree --color=always --icons --level=2 $(echo {} | awk "{print \$2}") | head -200') || return
  cd "$(echo "$dir" | awk '{print $2}')"
}

# fcd-recent — recently-cd'd dirs from atuin's history.
fcd-recent() {
  local dir
  dir=$(atuin history list --format '{command}' --print0 2>/dev/null \
    | tr '\0' '\n' | awk '/^cd / {print $2}' | awk '!seen[$0]++' | head -200 \
    | fzf --prompt='recent ❯ ') || return
  cd "${dir/#\~/$HOME}"
}

# fconfig — fuzzy-pick any file under ~/.config; ENTER opens in $EDITOR.
fconfig() {
  local f
  f=$(fd --type f --hidden --follow --exclude .git . ~/.config \
    | fzf --prompt='config ❯ ' \
          --preview 'bat --style=numbers --color=always --line-range=:300 {}') || return
  ${EDITOR:-nvim} "$f"
}

# fcm — chezmoi-managed files (if chezmoi is in use).
fcm() {
  command -v chezmoi >/dev/null || { print -u2 'fcm: chezmoi not installed'; return 1 }
  local f
  f=$(chezmoi managed --include=files \
    | fzf --prompt='chezmoi ❯ ' \
          --preview 'chezmoi cat $HOME/{} 2>/dev/null | bat --color=always --style=numbers --line-range=:300') || return
  chezmoi edit "$HOME/$f"
}

# fenv-set — pick an env var, edit its value, re-export.
fenv-set() {
  local var new
  var=$(env | awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' | sort -u \
    | fzf --prompt='set ❯ ' --preview 'printenv {}') || return
  new=$(gum input --value "${(P)var}" --header "$var =" 2>/dev/null) || return
  export "$var"="$new"
  print -P "%F{green}exported $var%f"
}

# ──────────────────────────────────────────────────────────
# MAINTENANCE — byte-compile, audit, update.
# ──────────────────────────────────────────────────────────

# Byte-compile every shell config file so the next shell loads bytecode.
# zsh prefers <file>.zwc when it's newer than <file>; otherwise falls back.
zrecompile() {
  local f
  for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.config/zsh/*.zsh; do
    [[ -r "$f" ]] || continue
    zcompile -R -- "$f".zwc "$f" 2>/dev/null && print "✓ $f"
  done
}

# Inventory which installed tools are wired vs. silently missing from
# plugins.zsh. Run after `brew install <new tool>` — output is a punch list.
audit-shell-integrations() {
  local -a checks=(
    "zoxide|command -v zoxide && rg -q 'zoxide init' ~/.config/zsh/plugins.zsh"
    "mise|command -v mise && rg -q 'mise activate' ~/.config/zsh/plugins.zsh"
    "atuin|command -v atuin && rg -q 'atuin init' ~/.config/zsh/plugins.zsh"
    "atuin-daemon-cfg|test -f ~/.config/atuin/config.toml && rg -q '^\\[daemon\\]' ~/.config/atuin/config.toml"
    "atuin-daemon-live|atuin daemon status 2>&1 | rg -q 'Healthy:  true'"
    "carapace|command -v carapace && rg -q 'carapace _carapace' ~/.config/zsh/plugins.zsh"
    "fzf|command -v fzf && [[ -r $BREW_PREFIX/opt/fzf/shell/key-bindings.zsh ]]"
    "fzf-tab|[[ -r $BREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh ]]"
    "fzf-git|[[ -r ~/.config/fzf-git/fzf-git.sh ]]"
    "forgit|[[ -r $BREW_PREFIX/share/forgit/forgit.plugin.zsh ]]"
    "navi|command -v navi && rg -q 'navi widget zsh' ~/.config/zsh/plugins.zsh"
    "direnv|command -v direnv && rg -q 'direnv hook' ~/.config/zsh/plugins.zsh"
    "zsh-defer|[[ -r ~/.config/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh ]]"
    "zsh-abbr|[[ -r $BREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh ]] && [[ -r ~/.config/zsh/abbreviations ]]"
    "zsh-autopair|[[ -r $BREW_PREFIX/share/zsh-autopair/autopair.zsh ]]"
    "zsh-you-should-use|[[ -r $BREW_PREFIX/share/zsh-you-should-use/you-should-use.plugin.zsh ]]"
    "zsh-autosuggestions|[[ -r $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]"
    "fast-syntax-highlighting|[[ -r $BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]"
    "zsh-vi-mode|[[ -r $BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]]"
    "vivid|command -v vivid && [[ -n \$LS_COLORS ]]"
    "tealdeer|command -v tldr && [[ -d ~/.config/tealdeer ]]"
    "bat-catppuccin|bat --list-themes 2>/dev/null | rg -q Catppuccin"
    "delta-catppuccin|git config --global --get delta.features | rg -q catppuccin- && git config --global --includes --get-all 'delta.catppuccin-mocha.syntax-theme' | rg -q Catppuccin && [[ -r ~/.config/git/catppuccin-delta.gitconfig ]]"
    "topgrade|command -v topgrade && [[ -r ~/.config/topgrade.toml ]] && ! topgrade --dry-run --only brew_formula 2>&1 | rg -q 'Failed to deserialize'"
    "k9s-catppuccin|ls ~/.config/k9s/skins/catppuccin-{mocha,frappe,latte,macchiato}.yaml >/dev/null 2>&1"
    "btop-catppuccin|ls ~/.config/btop/themes/catppuccin_{mocha,frappe,latte,macchiato}.theme >/dev/null 2>&1"
    "lazygit-catppuccin|[[ -d ~/.config/lazygit/catppuccin/themes-mergable/mocha ]] && rg -q '^# BEGIN catppuccin-managed' ~/.config/lazygit/config.yml"
    "gh-dash-catppuccin|ls ~/.config/gh-dash/themes/catppuccin-{mocha,frappe,latte,macchiato}-blue.yml >/dev/null 2>&1 && rg -q 'primary: \"#' ~/.config/gh-dash/config.yml"
    "fzf-catppuccin|ls ~/.config/fzf/themes/catppucin/themes/catppuccin-fzf-{mocha,frappe,latte,macchiato}.sh >/dev/null 2>&1"
    "glow-catppuccin|ls ~/.config/glow/catppuccin-{mocha,frappe,latte,macchiato}.json >/dev/null 2>&1 && [[ -n \$GLAMOUR_STYLE ]]"
    "eza-catppuccin|ls ~/.config/eza/themes/catppuccin-{mocha,frappe,latte,macchiato}.yml >/dev/null 2>&1 && [[ -L ~/.config/eza/theme.yml ]]"
    "tealdeer-catppuccin|test -f ~/.config/tealdeer/config.toml && rg -q '\\[style\\.description\\]' ~/.config/tealdeer/config.toml"
    "Brewfile|[[ -r ~/.config/brewfile/Brewfile ]]"
  )
  local pass=0 fail=0
  local c name test
  for c in "${checks[@]}"; do
    name="${c%%|*}"; test="${c#*|}"
    if eval "$test" >/dev/null 2>&1; then
      printf '\e[32m✓\e[0m %s\n' "$name"; (( pass++ ))
    else
      printf '\e[31m✗\e[0m %s — wire it up\n' "$name"; (( fail++ ))
    fi
  done
  print
  print -P "%F{cyan}$pass passing, $fail missing%f"
}

# mkproj — scaffold a new project. Creates a git-initialized directory
# with README, .gitignore, optional mise.toml + .envrc, then cd's into it.
# Defaults to a generic layout; pass a template to specialize:
#   mkproj <name>           — generic
#   mkproj <name> node      — adds package.json scaffold + node mise pin
#   mkproj <name> python    — adds pyproject.toml + python mise pin + venv
#   mkproj <name> rust      — `cargo init` + rust mise pin
#   mkproj <name> go        — `go mod init` + go mise pin
mkproj() {
  local name="${1:?usage: mkproj <name> [node|python|rust|go]}"
  local kind="${2:-generic}"
  local root="$HOME/Documents/GitHub/$name"
  [[ -d "$root" ]] && { print -u2 "mkproj: $root already exists"; return 1 }
  mkdir -p "$root" && cd "$root" || return
  git init -q
  print "# $name\n" > README.md
  cat > .gitignore <<'EOF'
# OS / editor
.DS_Store
*.swp
.idea/
.vscode/
.envrc.local
.direnv/
# Build
dist/
build/
target/
node_modules/
__pycache__/
*.pyc
.venv/
# Logs / temp
*.log
.tmp/
EOF
  case "$kind" in
    node)
      print 'tools = { node = "lts" }' > mise.toml
      cat > package.json <<EOF
{
  "name": "${name:l}",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": { "dev": "node index.js", "test": "node --test" }
}
EOF
      print 'console.log("hello from '"$name"'");' > index.js
      ;;
    python)
      print 'tools = { python = "3.13" }' > mise.toml
      cat > pyproject.toml <<EOF
[project]
name = "${name:l}"
version = "0.0.1"
requires-python = ">=3.13"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF
      print 'layout python' > .envrc
      ;;
    rust)
      print 'tools = { rust = "stable" }' > mise.toml
      cargo init --quiet 2>/dev/null
      ;;
    go)
      print 'tools = { go = "latest" }' > mise.toml
      go mod init "github.com/$(gh api user --jq .login 2>/dev/null || echo me)/${name:l}" >/dev/null 2>&1
      ;;
    *) : ;;
  esac
  [[ -f .envrc ]] && direnv allow . 2>/dev/null
  git add . && git commit -qm "feat: scaffold $name ($kind)" 2>/dev/null
  print -P "%F{green}✓%f scaffolded $kind project at $root"
  print -P "%F{cyan}next:%f $(command -v gh >/dev/null && echo 'gh repo create --source=. --private --push') "
}

# gpr — "I'm done; ship it." Push current branch (setting upstream on the
# first push), then open the PR creation page in the browser. Refuses to
# run on the main/master/develop branches.
gpr() {
  local branch protected
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
    || { print -u2 'gpr: not on a branch'; return 1 }
  for protected in main master develop trunk; do
    if [[ "$branch" == "$protected" ]]; then
      print -u2 "gpr: refusing to push from $branch"
      return 1
    fi
  done
  # Push, setting upstream automatically (push.autoSetupRemote = true).
  if ! git push --force-with-lease 2>/dev/null; then
    git push -u origin "$branch" || return
  fi
  # If a PR already exists, open it; else launch the create page.
  if gh pr view --json url --jq .url 2>/dev/null; then
    gh pr view --web
  else
    gh pr create --web
  fi
}

# jbr — Jira-ticket → branch. Usage: `jbr ABC-123 short slug`. Creates and
# checks out a branch named `<lowercase-ticket>-<slug-joined-with-dashes>`,
# matching common team conventions. Slug words from the rest of the args.
jbr() {
  local ticket="${1:?usage: jbr <TICKET> [description words…]}"
  shift
  local slug
  slug=$(echo "$@" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
  local branch="${ticket:l}${slug:+-$slug}"
  git switch -c "$branch"
}

# s — smart tmux session picker via sesh. Aggregates active sessions +
# zoxide top dirs + ~/Documents/GitHub repos; ENTER attaches (creates if
# needed). Bound to ^X^S (chord lives in the same family as ^X^Y yazi /
# ^X^N navi).
s() {
  command -v sesh >/dev/null || { print -u2 's: sesh not installed'; return 1 }
  local pick
  pick=$(sesh list --icons 2>/dev/null \
    | fzf --ansi --no-sort \
          --prompt='session ❯ ' \
          --header='ENTER → attach/create tmux session' \
          --preview 'sesh preview {}' \
          --preview-window='right,60%,wrap') || return
  sesh connect "$pick"
}

# ZLE widget so ^X^S fires from the prompt without typing `s`.
_s_widget() { BUFFER="s"; zle accept-line }
zle -N _s_widget
bindkey_persistent '^X^S' _s_widget

# slast — attach to the last tmux session (sesh remembers).
slast() { sesh last }

# proj — jump between projects with rich context.
# Aggregates: zoxide top dirs + `find ~/Documents/GitHub -maxdepth 2 -name .git`.
# Preview shows: README headline, mise tools, recent commits, git status.
# ENTER cd's into the project (direnv / mise hooks fire automatically).
proj() {
  local pick
  pick=$( {
    zoxide query -ls 2>/dev/null | awk '{print $2}'
    fd -t d -d 2 -H '^\.git$' ~/Documents/GitHub 2>/dev/null | sed 's|/\.git$||'
  } | awk '!seen[$0]++' \
    | fzf --prompt='proj ❯ ' \
          --header='ENTER → cd; mise + direnv hooks fire on chpwd' \
          --preview '
              p={}
              echo "📁 $p"
              echo
              if [[ -d "$p/.git" ]]; then
                git -C "$p" log -3 --oneline --color=always 2>/dev/null
                echo
                git -C "$p" status -sb 2>/dev/null | head -10
                echo
              fi
              if [[ -f "$p/mise.toml" ]] || [[ -f "$p/.tool-versions" ]]; then
                echo "── mise ──"
                (cd "$p" && mise current 2>/dev/null | head -8)
                echo
              fi
              if [[ -f "$p/README.md" ]]; then
                echo "── README ──"
                bat --color=always --style=plain --line-range=:30 "$p/README.md" 2>/dev/null
              elif [[ -f "$p/README" ]]; then
                bat --color=always --style=plain --line-range=:30 "$p/README" 2>/dev/null
              fi' \
          --preview-window='right,60%,wrap') || return
  cd "$pick"
}

# gha — fuzzy-pick a GitHub Actions run; ENTER tails its logs.
gha() {
  command -v gh >/dev/null || { print -u2 'gha: gh not installed'; return 1 }
  local run
  run=$(gh run list --limit 30 --json databaseId,name,status,conclusion,headBranch,createdAt \
        --template '{{range .}}{{tablerow .databaseId .name .status (printf "%v" .conclusion) .headBranch .createdAt}}{{end}}' 2>/dev/null \
    | fzf --prompt='run ❯ ' \
          --header 'pick run → view + tail logs' \
          --preview 'gh run view {1} 2>/dev/null | bat --color=always --style=plain' \
          --preview-window='right,60%,wrap')
  [[ -n "$run" ]] && gh run view "${run%% *}" --log
}

# ghissue — fuzzy-pick an open issue; ENTER opens it in the browser.
ghissue() {
  command -v gh >/dev/null || { print -u2 'ghissue: gh not installed'; return 1 }
  local issue
  issue=$(gh issue list --limit 100 --json number,title,author,labels \
        --template '{{range .}}{{tablerow (printf "#%v" .number) .title .author.login}}{{end}}' 2>/dev/null \
    | fzf --prompt='issue ❯ ' \
          --preview 'gh issue view {1} --comments 2>/dev/null | bat --color=always --style=plain --language=md' \
          --preview-window='right,60%,wrap')
  [[ -n "$issue" ]] && gh issue view "${issue%% *}" --web
}

# ghnot — fuzzy notifications; ENTER opens the linked thread in browser.
ghnot() {
  command -v gh >/dev/null || { print -u2 'ghnot: gh not installed'; return 1 }
  local pick url
  pick=$(gh api notifications --paginate --jq \
    '.[] | "\(.subject.type)\t\(.repository.full_name)\t\(.subject.title)\t\(.subject.url)"' 2>/dev/null \
    | fzf --prompt='notif ❯ ' --delimiter='\t' \
          --with-nth=1,2,3 \
          --preview 'echo {4} | sed "s|api.github.com/repos|github.com|; s|/pulls/|/pull/|" | xargs -I{} sh -c "gh api {} --jq .body 2>/dev/null | bat --color=always --plain --language=md"') || return
  url=$(echo "$pick" | awk -F'\t' '{print $4}' \
    | sed 's|api.github.com/repos|github.com|; s|/pulls/|/pull/|')
  [[ -n "$url" ]] && open "$url"
}

# health — one-stop wellness check. Run after `update-all` or whenever
# something feels off. No side effects, just observations.
health() {
  print -P "%F{cyan}━━━ shell health ━━━%f"
  print -P "%F{cyan}» versions%f"
  zsh --version | head -1
  print "fzf       $(fzf --version)"
  print "atuin     $(atuin --version 2>/dev/null)"
  print "mise      $(mise --version 2>/dev/null)"
  print "git       $(git --version)"
  print "delta     $(delta --version 2>/dev/null | head -1)"
  print "lazygit   $(lazygit --version 2>&1 | sed 's/, build.*//' | head -1)"
  print "topgrade  $(topgrade --version 2>/dev/null)"

  print -P "\n%F{cyan}» theme%f"
  print "catppuccin flavor : $CATPPUCCIN_FLAVOR"
  print "delta features    : $(git config --get delta.features)"
  print "BAT_THEME         : $BAT_THEME"
  print "GLAMOUR_STYLE     : ${GLAMOUR_STYLE:t:r}"

  print -P "\n%F{cyan}» atuin daemon%f"
  atuin daemon status 2>&1 | head -3 || print "  (no daemon)"

  print -P "\n%F{cyan}» startup%f"
  zbench 5

  print -P "\n%F{cyan}» integrations%f"
  audit-shell-integrations | tail -3
}

# ghco — fuzzy-pick a GitHub PR and check it out via `gh pr checkout`.
# Preview pane shows the PR body + the latest review summary.
ghco() {
  command -v gh >/dev/null || { print -u2 'ghco: gh not installed'; return 1 }
  local pr
  pr=$(gh pr list --limit 100 --json number,title,headRefName,author,isDraft \
        --template '{{range .}}{{tablerow (printf "#%v" .number) .title .headRefName .author.login (printf "%v" .isDraft)}}{{end}}' 2>/dev/null \
    | fzf --prompt='pr ❯ ' \
          --header 'pick PR → gh pr checkout' \
          --preview 'gh pr view {1} --comments 2>/dev/null | bat --color=always --style=plain --language=md' \
          --preview-window='right,60%,wrap')
  [[ -n "$pr" ]] && gh pr checkout "${pr%% *}"
}

# ghpr-merge — interactively merge a PR with squash/merge/rebase choice.
ghpr-merge() {
  command -v gh >/dev/null || { print -u2 'ghpr-merge: gh not installed'; return 1 }
  local pr method
  pr=$(gh pr list --json number,title --template '{{range .}}{{tablerow (printf "#%v" .number) .title}}{{end}}' \
    | fzf --prompt='merge ❯ ' --preview 'gh pr view {1}') || return
  method=$(printf 'squash\nmerge\nrebase' | fzf --prompt='method ❯ ') || return
  gh pr merge "${pr%% *}" --"$method" --delete-branch
}

# gabsorb — auto-distribute staged changes into the right historical commits.
# Wraps git-absorb with sane defaults: rebase autosquash after absorb so the
# fixup commits actually fold into their targets.
gabsorb() {
  command -v git-absorb >/dev/null || { print -u2 'gabsorb: git-absorb not installed'; return 1 }
  git absorb --base "$(git merge-base HEAD origin/HEAD 2>/dev/null || echo HEAD~10)" --and-rebase
}

# wt — git-worktree picker. Lists worktrees with branch + path; ENTER cd's
# into the picked worktree. Pair with `gwta <branch>` (abbr) to create.
wt() {
  local picked
  picked=$(git worktree list --porcelain 2>/dev/null \
    | awk '
        /^worktree / {p=$2}
        /^branch / {b=$2; printf "%-40s %s\n", b, p}
        /^bare/    {printf "%-40s %s\n", "(bare)", p}
        /^detached/{printf "%-40s %s\n", "(detached)", p}
      ' \
    | fzf --prompt='wt ❯ ' \
          --header 'pick worktree → cd into it' \
          --preview 'eza --tree --color=always --icons --level=2 $(echo {} | awk "{print \$NF}") 2>/dev/null | head -200') || return
  cd "$(echo "$picked" | awk '{print $NF}')"
}

# lgp — swap the active lazygit pager. lazygit picks pagers[0]; this
# yq-reorders so the requested entry is first. Restart lazygit to pick up.
#
#   lgp           → print all entries (current = first)
#   lgp sbs       → delta side-by-side
#   lgp unified   → delta unified
#   lgp fancy     → diff-so-fancy
lgp() {
  local cfg=~/.config/lazygit/config.yml needle
  case "${1:-}" in
    ''|list|status)
      print -P "%F{cyan}lazygit pagers (active = first):%f"
      yq '.git.pagers[] | "  - " + .pager' "$cfg"
      return
      ;;
    sbs|side|side-by-side) needle='side-by-side' ;;
    u|unified)             needle='unified' ;;
    f|fancy|diff-so-fancy) needle='diff-so-fancy' ;;
    *) print -u2 "lgp: unknown pager '$1'. Use sbs|unified|fancy."; return 1 ;;
  esac
  local tmp=$(mktemp)
  yq ".git.pagers = ([.git.pagers[] | select(.pager | test(\"$needle\"))] + [.git.pagers[] | select(.pager | test(\"$needle\") | not)])" \
    "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  print -P "%F{green}lazygit active pager →%f $(yq '.git.pagers[0].pager' "$cfg")"
  print -P "%F{yellow}restart lazygit to pick up.%f"
}

# cheatsheet — quick reminder of what's wired up. Type `cheatsheet` to
# discover the keys / functions / abbreviations you forgot you had.
cheatsheet() {
  bat --color=always --style=plain --language=md <<'EOF'
# Shortcuts wired in this config

## Key bindings
- `^R`            atuin (history search; precmd-asserted every prompt)
- `^T`            fzf file picker (walker, hidden+follow)
- `Alt-c`         fzf dir picker (walker)
- `TAB`           fzf-tab — fuzzy completion menu with per-command preview
- `^G^B / ^Gb`    fzf-git branches
- `^G^F / ^Gf`    fzf-git files
- `^G^T / ^Gt`    fzf-git tags
- `^G^R / ^Gr`    fzf-git remotes
- `^G^H / ^Gh`    fzf-git hashes
- `^G^S / ^Gs`    fzf-git stashes
- `^G^L / ^Gl`    fzf-git reflogs
- `^G^W / ^Gw`    fzf-git worktrees
- `^G?`           fzf-git binding cheatsheet (inline)
- `^X^N`          navi cheatsheet picker
- `^X^Y`          yazi (cwd-syncing)
- `^X^N`          navi cheatsheet picker
- `^X^S`          sesh tmux session picker (active sessions + zoxide + GitHub repos)
- `^X^E`          edit current command line in $EDITOR
- `^X^Z`          edit ~/.zshrc
- `^X^R`          reload shell (`exec zsh`)
- `^Space`        zsh-tab continuous trigger (cycle group)

## Inside any fzf picker
- `?`             toggle preview pane
- `^/`            cycle preview position (right → down → hidden)
- `^U / ^D`       half-page up/down in the preview
- `^Y`            copy highlighted line to clipboard, abort
- `^O`            `open` the highlighted entry
- `^E`            edit the highlighted entry in $EDITOR (becomes the process)
- `Alt-a / d / t` select all / deselect all / toggle all

## fzf-powered functions (type the name)
- `cdf`           fuzzy-cd with tree preview
- `fe / f`        fuzzy edit a file (bat preview)
- `frg <q?>`      live ripgrep → open at line
- `fbr`           fuzzy switch git branch
- `fco`           fuzzy checkout (branches + tags)
- `fshow`         git log browser; Enter copies SHA, ^D drills diff in less
- `fenv`          inspect any env var
- `fhelp <cmd?>`  tldr + man drill-down via fzf
- `fcheat <cmd?>` cheat.sh snippets via fzf
- `fnavi`         navi cheats inline
- `fbrew`         fuzzy `brew install` (formulae + casks)
- `fbrew-rm`      fuzzy `brew uninstall`
- `fport`         pick a LISTEN port → kill the PID
- `fdocker`       pick a running container → shell in
- `fkube`         pick a k8s context (or `fkube -p` for pod + logs)
- `fssh`          pick an SSH host from config + known_hosts
- `fman`          pick any man page (rendered preview)
- `fz`            fuzzy zoxide with visible frecency scores
- `fcd-recent`    recently-cd'd dirs from atuin history
- `fconfig`       any file under ~/.config → $EDITOR
- `fcm`           chezmoi-managed file → `chezmoi edit`
- `fenv-set`      edit an env var inline (gum input), re-export

## Abbreviations (type the LHS + space)
- Run `abbr list` to see them all. Edit ~/.config/zsh/abbreviations to add.
- Examples: gco→git checkout, kgp→kubectl get pods, dcu→docker compose up -d

## Maintenance
- `zbench [n]`            median startup of N runs (default 10)
- `audit-shell-integrations` — green-bar all wired integrations
- `update-all` / `upall`  — topgrade + cache flush + recompile + audit
- `zrecompile`            — byte-compile every config file
- `zsh_cache_clear`       — invalidate ~/.cache/zsh/*.zsh
- `catppuccin <flavor>`   — flip every wired tool's theme atomically

## Git TUIs / interactives (lazy-loaded on first call)
- `lg`                    lazygit
- `lzd`                   lazydocker
- `lgp [sbs|unified|fancy]` swap lazygit's active pager (delta sbs/unified/diff-so-fancy)
- `ghco`                  fuzzy-pick a GitHub PR → `gh pr checkout`
- `ghpr-merge`            interactively merge a PR (squash|merge|rebase)
- `gha`                   fuzzy-pick a GitHub Actions run → tail logs
- `ghissue`               fuzzy-pick an open issue → open in browser
- `ghnot`                 fuzzy GitHub notifications → open in browser
- `gabsorb`               `git absorb --and-rebase` against origin/HEAD merge-base
- `wt`                    fuzzy-pick a git worktree → cd into it
- `proj`                  fuzzy-jump between projects (zoxide + ~/Documents/GitHub)
                          preview: recent commits + mise tools + README headline
- `s` / `^X^S`            sesh tmux session picker → attach (or create)
- `slast`                 attach to last tmux session
- `gpr`                   push (force-with-lease, set upstream) + open PR in browser
- `jbr <TICKET> [words]`  Jira-ticket → checkout branch `ticket-slug-from-words`
- `mkproj <name> [kind]`  scaffold project at ~/Documents/GitHub/<name>
                          kinds: generic | node | python | rust | go
                          git init + README + .gitignore + mise.toml + .envrc
- `health`                versions + theme + atuin daemon + zbench + audit (no side effects)

## Git diff pagers (global = diffnav)
- `git diff`              → diffnav (file tree + delta)
- `git d`                 alias for diff
- `git ds <args>`         force delta side-by-side
- `git du <args>`         force delta unified
- `git dfancy <args>`     force diff-so-fancy
- `git dnav <args>`       force diffnav (in case of override)
- `git log/show/blame`    → delta (per-command pager)
- `git add -p`            → delta inline filter (--color-only)
- All delta features inherit `[delta] features = catppuccin-mocha decorations merge-symbols`
  from `~/.config/git/catppuccin-delta.gitconfig` (vendored from upstream).

## Inside lazygit (`lg`)
- `?`            help / list bindings
- `<tab>`        cycle panels
- `e`            edit file at line in nvim
- `<space>`      stage / unstage
- `c`            commit (will open $EDITOR)
- `C` *files*    **Conventional Commits picker** (type → scope → subject)
- `n` *branches* new branch from current with name prompt
- `D` *branches* force-delete branch
- `F` *commits*  fixup HEAD → selected commit + autosquash-rebase
- `S` *stash*    stash including untracked (-u)
- `A` *files*    toggle assume-unchanged
- `T`            open repo in browser via `gh`
- `P`            create PR via `gh pr create --web`
- `fga / fgd / fgl / fgcb / fgss / fgsp / fgcp / fgcf / fgrh / fgbd / fgrc`
                          forgit (interactive git workflows)
EOF
}

# update-all — let topgrade handle the upstream tools; chain the locals.
update-all() {
  print -P "%F{cyan}┃ topgrade%f"
  topgrade --yes
  print -P "%F{cyan}┃ codemod skills%f"
  command -v npx >/dev/null && npx --yes codemod ai list --harness claude --format json >/dev/null 2>&1
  print -P "%F{cyan}┃ flush zsh eval caches%f"
  zsh_cache_clear 2>/dev/null
  print -P "%F{cyan}┃ recompile zsh%f"
  zrecompile
  print -P "%F{cyan}┃ integration audit%f"
  audit-shell-integrations
}
