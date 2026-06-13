# zsh config — quick reference

Modular zsh setup for power-dev work. Catppuccin Mocha everywhere. ~0.4s cold start.

> Conventions and "where do I add X" rules live in **CLAUDE.md** next to this file.

---

## Files

| File              | Holds                                                          |
|-------------------|----------------------------------------------------------------|
| `~/.zshrc`        | 12-line entry point — sources the modules in order             |
| `env.zsh`         | PATH, EDITOR, pagers (less + bat), GNU coreutils, theme env    |
| `options.zsh`     | `setopt`, history config, ZLE widgets, **the one** `compinit`  |
| `plugins.zsh`     | oh-my-posh, zoxide, fzf, carapace, fzf-tab, direnv, mise, atuin, autosuggest, fast-syntax-highlight, **zsh-vi-mode** |
| `aliases.zsh`     | All aliases (the only place they go)                           |
| `functions.zsh`   | All shell functions + `catppuccin` flavor switcher             |
| `claude.zsh`      | Claude multi-agent / tmux helpers                              |
| `work.zsh`        | VPN (openconnect-sso for GlobalProtect)                        |
| `auto-tmux.zsh`   | Auto-attach to tmux session `main` on interactive TTY          |

Module load order in `~/.zshrc`: `env → options → plugins → aliases → functions → claude → work → auto-tmux`. **Don't reorder**: atuin needs to load after fzf so it owns `^R`; fast-syntax-highlight must load before zsh-vi-mode; zsh-vi-mode must load last (it clobbers ZLE bindings and rebinds them in `zvm_after_init`); carapace/fzf-tab need `compinit` to have already run.

### vi mode

`zsh-vi-mode` (Homebrew) gives a real modal command line: `Esc` → NORMAL, `i/a` → INSERT, `v` → VISUAL with full text objects (`ci"`, `da(`, etc.). Cursor shape and selection highlight match Catppuccin Mocha. `^R` (atuin), `^T` and `Alt-c` (fzf) are restored after init via `zvm_after_init` so the muscle memory still works.

---

## `ls` sort matrix (`eza` under the hood)

Pattern: `l<key>[r]`, prefix `la` adds hidden files.

| You want…                          | Type     |
|------------------------------------|----------|
| Biggest files                      | `lS`     |
| Smallest files                     | `lSr`    |
| Most recently modified             | `lm`     |
| Oldest modified                    | `lmr`    |
| Most recently created              | `lc`     |
| Oldest created                     | `lcr`    |
| Most recently accessed             | `lu`     |
| Least recently accessed            | `lur`    |
| Alphabetical (A→Z)                 | `lN`     |
| Reverse alphabetical (Z→A)         | `lNr`    |
| Grouped by extension               | `lx`     |
| Biggest, incl. hidden              | `laS`    |
| Newest, incl. hidden               | `lam`    |
| Newest-created, incl. hidden       | `lac`    |
| Directories only                   | `ld`     |
| Tree (depth 2 / 3 / w hidden)      | `lt` `lt3` `lta` |
| Default colorful list              | `ls` `l` |
| Long list w/ git                   | `ll`     |
| Long list w/ git + hidden          | `la`     |

`lN` is capitalized because lowercase `ln` is the symlink command.

---

## fzf — the fuzzy substrate

fzf, atuin, and fzf-tab share the same Catppuccin theme via `FZF_DEFAULT_OPTS`.

| Key / cmd        | Does                                                    |
|------------------|---------------------------------------------------------|
| `^R`             | atuin history search                                    |
| `^T`             | file picker (fd + bat preview)                          |
| `Alt-C`          | directory picker (fd + eza tree preview)                |
| `<TAB>`          | fzf-tab completion (per-command preview rules)          |
| `^/` (in fzf)    | toggle preview                                          |
| `^Y` (in fzf)    | copy highlighted line to clipboard                      |
| `^X^Z`           | edit ~/.zshrc                                           |
| `^X^R`           | `exec zsh` reload                                       |
| `^X^F`           | edit current command line in nvim                       |
| `^X^E`           | Claude-explain current command                          |
| `^X^Y`           | launch yazi (`y`)                                       |

### Power functions

| Cmd       | Picks                                                         |
|-----------|---------------------------------------------------------------|
| `fe` / `f` | any file → opens in `$EDITOR`                                |
| `frg [q]` | live ripgrep across files → ENTER opens at line              |
| `fbr`     | git branches (sorted by recency) → `git switch`              |
| `fco`     | local branch OR remote OR tag → `git checkout`               |
| `fshow`   | git log browser; ENTER copies SHA, `^D` shows diff in `less` |
| `fenv`    | environment variable → prints its value                      |
| `cdf`     | directory → `cd`                                             |
| `killp` / `fk` | processes (multi w/ TAB) → SIGKILL                     |

---

## Yazi (terminal file manager)

| Cmd              | Does                                                |
|------------------|-----------------------------------------------------|
| `y`              | Launch yazi; **on quit, shell `cd`s into the new dir** |
| `yz`             | Raw yazi (no cwd-sync)                              |
| `yc`             | Edit `yazi.toml`                                    |
| `^X^Y`           | Same as `y`                                         |

Inside yazi: `h j k l` navigate, `Enter` open, `Space` select, `a` create, `d` cut, `y` copy, `p` paste, `D` trash, `.` toggle hidden, `q` quit, `cd` jump, `/` search, `s` shell, `T` tasks. Previews work for: text (bat), images (imagemagick), PDFs (poppler), archives (sevenzip), video (ffmpeg).

---

## Git

`gs` status • `ga` add • `gaa` add-all • `gc` commit • `gcm` commit-m • `gca` amend-noedit • `gco` checkout • `gsw` switch • `gswc` switch-create • `gcoback` checkout previous • `gb` branch • `gd` diff • `gds` diff-staged • `gp` push • `gpub` push-upstream-HEAD • `gpf` push force-with-lease • `gpl` pull-rebase • `gfa` fetch-all-prune • `gl` graph log -20 • `glol` pretty graph • `gst` stash • `gsp` stash pop • `gst gsp grh gclean gwt gcp` • `wip` add+commit-wip • `lg` lazygit.

`gh` CLI: `ghpr` create PR (web) • `ghprs` list PRs • `ghrepo` open in web • `ghrun` watch action.

---

## Docker

`dk` docker • `dc` compose • `dcu` compose up -d • `dcd` compose down • `dcl` compose logs -f • `dps` pretty ps • `lzd` lazydocker.

---

## tmux

`tm` tmux • `ta <name>` attach • `tn <name>` new • `tls` list • `tk <name>` kill session • `tka` kill server • `ts [name]` attach-or-create (default `main`). On interactive TTY (Ghostty/IDEs excluded), auto-attaches to `main` — see `auto-tmux.zsh`.

---

## Catppuccin flavor switcher

```zsh
catppuccin mocha       # default
catppuccin frappe
catppuccin latte
catppuccin macchiato
```

Propagates to: bat, delta, Ghostty (palette + icon colors), ccstatusline, tmux, yazi (rewrites `theme.toml`). Persists in `~/.config/catppuccin-flavor`. Triggers `exec zsh` at the end.

---

## Global aliases (expand mid-command)

```zsh
ls -la G config      # → ls -la | rg config
some-cmd L           # → some-cmd | less
pwd GC               # → pwd | pbcopy
find . NE            # → find . 2>/dev/null
some-cmd NUL         # → some-cmd >/dev/null 2>&1
```

`G L H T GC NE NUL` — uppercase by convention so they read as one mid-command.

---

## Suffix aliases (filename alone opens it)

```
~/.zshrc<Enter>      → opens in nvim
report.pdf<Enter>    → opens in Preview
archive.tar.gz<Enter>→ runs extract()
```

Text-ish (`md txt log conf cfg json yaml yml toml ini env`) → `nvim`. Viewables (`html pdf png jpg jpeg gif`) → `open`. Archives (`tar gz bz2 xz zip 7z`) → `extract`.

---

## Navigation

| Cmd     | Does                                  |
|---------|---------------------------------------|
| `..` `...` `....` `.....` | cd up 1/2/3/4         |
| `-`     | cd to previous dir (`cd -`)           |
| `d`     | show pushd stack (`dirs -v`)          |
| `1`–`9` | (via `setopt AUTO_PUSHD`) jump in stack |
| `q`     | cd to `~/Documents/GitHub`            |
| `z <q>` | zoxide jump (`j <q>` same)            |
| `cdf`   | fuzzy-pick dir                        |

---

## Network / system

`myip` (public IP) • `localip` (en0) • `ports` (LISTEN) • `serve` (python http server) • `jsonpp` (pipe-through pretty-print) • `flushdns` • `lock` (display sleep) • `showfiles` / `hidefiles` (Finder) • `brewup` (full upgrade cycle) • `dsclean` (purge .DS_Store) • `whatport <p>` (lsof on port) • `weather [city]` • `cheat <cmd>` (cheat.sh) • `genpw [n]` (base64) • `timecmd <cmd>` • `urlencode` / `urldecode`.

---

## Claude / multi-agent

`c` claude • `ch` claude --chrome • `co` code • `cw [name]` claude in new tmux window • `cs [name]` claude in new tmux session • `cls` list claude procs with cwd • `ckill` interactive kill all claude • `cl` pick atuin command → run via claude • `claude-notify {on|off|status}` push-notification toggle.

---

## Modern tools used (so you don't reach for the old ones)

| Old             | Now                |
|-----------------|--------------------|
| `ls`            | `eza`              |
| `cat`           | `bat`              |
| `grep`          | `rg`               |
| `find`          | `fd`               |
| `du`            | `dust`             |
| `df`            | `duf`              |
| `ps`            | `procs`            |
| `top`           | `btop`             |
| `ping`          | `gping`            |
| `dig`           | `dog`              |
| `man`           | `bat`-paged        |
| `vi`/`vim`      | `nvim`             |
| smart `cd`      | `zoxide`           |
| `^R` history    | `atuin`            |
| completion      | `fzf-tab` + `carapace` |
| prompt          | `oh-my-posh`       |
| nvm/pyenv/rbenv | `mise`             |
| ranger/lf       | `yazi`             |
| git CLI         | `lazygit` (`lg`)   |
| docker CLI      | `lazydocker` (`lzd`) |

Whenever you `command ps …` or `command grep …` in a function, it's to bypass these aliases (e.g. `procs` doesn't accept `ps`'s flags).

---

## Reload after edits

```zsh
exec zsh        # or: zrr
```

Or just `^X^R`.
