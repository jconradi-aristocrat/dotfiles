# Zsh Config — Conventions & Goals

This file briefs an AI assistant (or future-you) on how this zsh config is wired and how to extend it without breaking its character.

---

## North Star

Three priorities, in order. When they conflict, the earlier one wins.

1. **Speed.** Everything is for an interactive power developer. Startup time matters; per-keystroke latency matters more. Prefer Rust/Go reimplementations of GNU tools (rg, fd, bat, eza, dust, duf, procs, gping, dog, btop). Defer anything that can be deferred.
2. **Cutting edge.** Use modern tools (atuin over plain history, mise over nvm+pyenv+rbenv, oh-my-posh over starship, carapace over standalone completions, yazi over ranger/lf, fzf-tab over zsh menu, lazygit/lazydocker over raw CLI). Track upstream defaults; don't over-customize what the tool already does well.
3. **Beauty — Catppuccin Mocha.** One palette everywhere. The `catppuccin` function (functions.zsh) is the single switcher; if you add a new tool that has a theme, wire it into that function so flavor changes propagate cleanly.

---

## File map (load order is defined by `~/.zshrc`)

```
~/.zshrc                         # 12 lines. Sources the modules below in order.
~/.config/zsh/
  env.zsh                        # PATH, EDITOR, pagers, GNU coreutils, theme env
  options.zsh                    # setopt, history, compinit, ZLE widgets, fpath
  plugins.zsh                    # oh-my-posh, zoxide, fzf, carapace, fzf-tab,
                                 # direnv, mise, atuin, autosuggest,
                                 # fast-syntax-highlight, zsh-vi-mode
  aliases.zsh                    # Aliases only. Functions go in functions.zsh.
  functions.zsh                  # Shell functions, ZLE widgets, catppuccin switcher
  claude.zsh                     # Claude multi-agent / tmux helpers
  work.zsh                       # VPN, work-specific
  auto-tmux.zsh                  # Auto-attach tmux on interactive TTY
  CLAUDE.md                      # ← this file
  plugins/                       # Inline plugin sources (e.g. zsh-transient-prompt)
```

**Load order is significant.** atuin must load AFTER fzf so atuin owns `^R`. fast-syntax-highlight must load BEFORE zsh-vi-mode (vi-mode clobbers ZLE on init and rebinds in `zvm_after_init`, which is where `^R`/`^T`/`Alt-c` are restored). compinit must run BEFORE carapace/fzf-tab. Don't reorder without verifying.

---

## Where things go

| Kind of change             | Goes in                  |
|----------------------------|--------------------------|
| New alias                  | `aliases.zsh` (under the right banner) |
| New shell function         | `functions.zsh`          |
| New env var or PATH entry  | `env.zsh`                |
| New plugin or completion   | `plugins.zsh`            |
| New `setopt` / keybinding  | `options.zsh`            |
| New theme propagation      | `functions.zsh::catppuccin()` |
| One-off interactive helper | `functions.zsh` (prefix with `_` if internal) |

**Do not** put aliases in `functions.zsh` or vice versa. The split is the convention.

---

## Alias naming conventions

* **Single-letter** aliases are reserved for the most-used commands: `c` (claude), `g` (git), `l`/`ls`, `o` (open), `q` (cd ~/Documents/GitHub), `d` (dirs).
* **eza sort matrix** — see the block in `aliases.zsh`:
  * `l<key>[r]` where key = `S`ize, `m`odified, `c`reated, `u`sed (atime), `N`ame, e`x`tension. `r` suffix = reverse.
  * `lN` is capitalized because lowercase `ln` is `/bin/ln`. Same rule applies to any future alias that would shadow a real command.
  * Prepend `la` for the include-hidden variant of the three most-used (`laS`, `lam`, `lac`).
* **Git aliases** mirror oh-my-zsh's git plugin conventions (`gs`, `ga`, `gc`, `gco`, `gp`, `gpl`, `gst`, `glol`). When in doubt, match what's already there.
* **fzf functions** use the `f` prefix (`fe`, `fbr`, `fco`, `fshow`, `frg`, `fenv`, `fk`). Don't alias these to two-letter forms if doing so would shadow shell builtins (`fg`, `bg`, `jobs`, etc.).
* **Global aliases** (`alias -g`) are uppercase to make them visible mid-line: `G`, `L`, `H`, `T`, `GC`, `NE`, `NUL`.
* **Suffix aliases** are grouped by intent: text → `nvim`, viewable → `open`, archive → `extract`.

---

## fzf is the default fuzzy substrate

If a workflow can be made fuzzy, it should be. We use fzf for:

* `^R` history search → handed to **atuin** (atuin inherits FZF_DEFAULT_OPTS, so styling propagates).
* `^T` file picker / `Alt-C` dir picker → fzf with `fd` + bat/eza preview.
* `<TAB>` completion → **fzf-tab** with per-command preview rules.
* Git → `fbr` (switch branch), `fco` (checkout local/remote/tag), `fshow` (log browser, ENTER copies SHA).
* Files → `fe` (fuzzy edit), `frg` (live ripgrep → open at line).
* Processes → `killp` (multi-select kill).
* Directories → `cdf` (fuzzy cd with tree preview).
* Environment → `fenv` (inspect any env var).

**FZF_DEFAULT_OPTS order matters:** source the Catppuccin theme FIRST, then append layout opts (the theme file overwrites the var, not extends it). See `plugins.zsh`.

When adding a new fzf entry-point, give it:
* A `--prompt='<verb> ❯ '` so the user knows what they're picking.
* A `--preview` (bat for files, eza for dirs, git for commits, printenv for env).
* `--preview-window=right:60%:wrap` (or top/down for tall data).
* Inherit `FZF_DEFAULT_OPTS` for colors — don't redeclare them.

---

## Catppuccin Mocha — one palette, one switcher

`functions.zsh::catppuccin <flavor>` is the only place flavor-switching logic lives. To add a new tool's theme:

1. Add a `_catppuccin_update_<tool>` helper (or inline sed) inside the `catppuccin` function body.
2. The flavor argument is one of `mocha | frappe | latte | macchiato`.
3. Read the current default from `~/.config/catppuccin-flavor` (env.zsh exports it on startup).
4. If the tool requires a restart to pick up theme changes, fire it (we already `exec zsh` at the end).

Currently wired: oh-my-posh (palette comes from `$CATPPUCCIN_FLAVOR`), bat, delta, ghostty, ccstatusline, tmux, yazi.

---

## Yazi (terminal file manager)

* Launch with `y` — the function in `functions.zsh` cd's the shell into yazi's exit directory.
* `yz` = raw yazi (no cwd-sync). `yc` = edit yazi.toml.
* Bound to `^X^Y`.
* Theme lives in `~/.config/yazi/theme.toml`, which points to a flavor under `~/.config/yazi/flavors/catppuccin-*.yazi/`. `catppuccin()` rewrites the `dark = "..."` line.
* Yazi previews PDFs (poppler), images (imagemagick), archives (sevenzip) — all installed via brew.

---

## What NOT to add

* **No oh-my-zsh / prezto / antigen frameworks.** We load plugins explicitly via brew formula paths. Adding a framework would double-source and slow startup.
* **No second `compinit`.** It already runs once in `options.zsh` after fpath is finalized. Docker Desktop's auto-appended block in `.zshrc` has been intentionally removed — don't restore it.
* **No theme overrides outside `catppuccin()`.** If a tool's config hardcodes colors, pull them through the switcher instead.
* **No `alias <shell-builtin>=<other>`.** Don't shadow `fg`, `bg`, `jobs`, `cd`, `pwd`, `kill`, `time`, `ln`, etc. Use a different name.
* **No synchronous network calls at startup.** No `eval "$(curl …)"`, no remote completion fetches. Defer with `zsh-defer` or compute at install time.
* **No PATH appends without `typeset -U path PATH`** — env.zsh dedupes once at top; keep it that way.

---

## Verification after edits

Quick sanity loop (paste into a fresh shell):

```zsh
# 1. Reload cleanly
exec zsh

# 2. Confirm compinit runs once
zsh -i -c 'echo $#fpath; functions compinit | head -1' | tail -5

# 3. Spot-check sort aliases
lS  | head -3   # biggest first
lSr | head -3   # smallest first
lm  | head -3   # newest first
lc  | head -3   # newest-created first
lu  | head -3   # most-recently-accessed first
lN  | head -3   # alpha
lx  | head -3   # grouped by extension

# 4. Yazi cwd-sync
y    # navigate, then `q` → shell should be in the new dir

# 5. fzf coverage
fe          # fuzzy edit any file
frg foo     # live ripgrep
fbr         # switch git branch (in a repo)
fshow       # browse git log
killp       # fuzzy kill

# 6. Theme switch end-to-end
catppuccin frappe && catppuccin mocha
```

If any of those break: the audit failed. Re-read this file before changing anything.

---

## Modern-tool registry (what replaces what)

| Old (BSD/GNU)       | New (in this config)        | Why                          |
|---------------------|-----------------------------|------------------------------|
| `ls`                | `eza`                       | Icons, git, sort matrix      |
| `cat`               | `bat`                       | Syntax highlighting          |
| `grep`              | `rg` (aliased)              | Speed, smart-case            |
| `find`              | `fd`                        | Speed, sane defaults         |
| `du`                | `dust`                      | Tree view                    |
| `df`                | `duf`                       | Color, grouped               |
| `ps`                | `procs`                     | Color, columns               |
| `top`               | `btop`                      | TUI, GPU                     |
| `ping`              | `gping`                     | Graph                        |
| `dig`               | `dog`                       | JSON, color                  |
| `man`               | `bat`-paged via `MANPAGER`  | Highlighted man pages        |
| `vi`/`vim`          | `nvim`                      | Modern Neovim                |
| `cd` (smart)        | `zoxide` (`z`/`j`)          | Frecency                     |
| history (`^R`)      | `atuin`                     | Searchable, sync             |
| completion (`<TAB>`)| `fzf-tab` + `carapace`      | Fuzzy + 1000 CLIs            |
| prompt              | `oh-my-posh`                | Catppuccin-driven            |
| nvm/pyenv/rbenv     | `mise`                      | One tool, declarative        |
| ranger/lf           | `yazi`                      | Async, fast previews         |
| git CLI             | `lazygit` (`lg`)            | TUI for complex ops          |
| docker CLI          | `lazydocker` (`lzd`)        | TUI for daily ops            |
| `cd ..`             | `..` `...` `....` aliases   | Faster                       |
| `htop`/sysinfo      | `fastfetch` greeter         | Boot-time system snapshot    |

When introducing a new "replacement," check this table first — there may already be one you forgot about.
