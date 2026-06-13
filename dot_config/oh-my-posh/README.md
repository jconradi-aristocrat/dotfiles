# oh-my-posh — Catppuccin, four flavors, music-aware

A single oh-my-posh prompt that scales from an iPhone 15 in Blink Shell
(40–100 cols, mosh → tmux) to a MacBook M4 Max in Ghostty (160–240 cols),
keeps a vi-mode pill in lockstep with `zsh-vi-mode`, lights up a
right-side music widget whenever audio is actually playing on the
machine, and ships all four Catppuccin flavors selectable at runtime.
Rendered with `JetBrainsMonoNL Nerd Font`.

## What it looks like

Two-line block. Top line is left identity row + path/git on the left,
right-aligned system strip on the right. Bottom line is a status-colored
`❯` for input.

### iPhone portrait (~40 cols)
```
   I   ~/df    main !2
❯
```
OS pill (Apple/Linux/Win logo) · vi-mode (`I` / `N` / `V` / `V·L` / `R`) ·
path (unique style, e.g. `~/.c/o/config.json`) · git.

### Comfortable (80 cols)
```
   I   ~/df    main !2                                      15:04
❯
```
Adds SSH + root pills (if you're remoted in / elevated) on the left,
plus the clock on the right.

### Wide (120 cols)
```
   I   ~/df    main !2     Bohemian Rhapsody — Queen      92%   1.2s   15:04
❯
```
Music pill (only when something is playing) and battery appear.

### Ultra-wide on Ghostty M4 Max (160+ cols)
```
   I   ~/df    main !2     20.10.0      Bohemian Rhapsody — Queen      home-wifi      24%   72%   84%   92%   1.2s    Tue Jun 9   15:04
❯
```
Adds runtime version, connection (wifi SSID / ethernet), CPU, memory,
disk, and the date.

### Transient prompt (after Enter)
```
✓ 15:04:12 · 1.2s · ~/.config/ohmyposh · $ git status
✗ 15:04:33 · 380ms · 127 (command not found) · ~/.config/ohmyposh · $ gti status
```
Past lines collapse into one dim line: status glyph, fired-at time,
duration, exit code + reason (only on error), cwd, and the literal
command typed. The `$ <cmd>` half requires the `preexec` hook in
`~/.config/zsh/functions.zsh` (already wired) which exports
`OMP_LAST_COMMAND` for the next prompt render.

### Tooltips
Type `aws ` → yellow `  profile@region` at the right edge.
Type `kubectl ` → teal `⎈ context :: namespace`.
`terraform`, `tf`, `git`, `gh`, `docker`, `dc`, `python`, `pip`, `node`,
`npm`, `pnpm` are also wired. Submit the command → tooltip vanishes.

## Responsive breakpoints

| Width  | Left adds                          | Right adds                                          |
|--------|------------------------------------|-----------------------------------------------------|
| 0+     | os · vi-mode · path · git          | executiontime (when last cmd > 2s)                  |
| 80+    | + ssh · root                       | + clock                                             |
| 120+   | (no add)                           | + music (when playing) · battery                    |
| 160+   | (no add)                           | + runtime · connection · cpu · memory · disk · date |

Gating uses oh-my-posh's per-segment `min_width`. Below the threshold
the segment is omitted entirely.

## Color cycle (Catppuccin role-based)

The bar deliberately never puts the same accent role next to itself.
Adjacent pills always use a different role:

**Left:**
```
os(mauve) → ssh(sky) → root(red) → vi-mode(mode-color) → path(peach icon, lavender text) → git(state-color)
```

**Right (rightmost first):**
```
clock(lavender) → date(flamingo) → execute(peach) → battery(green/yellow/red) → disk(lavender)
  → memory(mauve) → cpu(teal) → connection(sapphire) → music(pink) → runtime(per-lang)
```

The vi-mode pill switches accent by mode (blue=INSERT, green=NORMAL,
mauve=VISUAL, lavender=V-LINE, red=REPLACE). The git pill switches by
state (sapphire=clean, yellow=dirty, pink=behind, green=ahead, red=both).

## Switching flavor

The `palettes` block ships all four Catppuccin flavors. Selection is
template-driven on `$CATPPUCCIN_FLAVOR`:

```sh
export CATPPUCCIN_FLAVOR=frappe       # or latte, macchiato, mocha
exec zsh
```

The `catppuccin` function in `~/.config/zsh/functions.zsh` does this
across tmux, bat, yazi, etc. in one command.

## Music widget

Powered by [`media-control`](https://github.com/ungive/mediaremote-adapter)
(`brew install media-control`). Covers every source that publishes to
macOS MediaRemote: YouTube Music Desktop, Chrome YouTube tabs, Spotify,
Apple Music, podcasts. Polls once every 3s, cached per session. The
pill is rendered only when `.playing == true` — so paused or stopped
audio hides it automatically.

## Vi-mode pill

Wired to `zsh-vi-mode` via a `zvm_after_select_vi_mode` hook in
`~/.config/zsh/plugins.zsh` that exports `$OMP_VI_MODE`. The pill reads
that env var and picks a color + label per mode.

## Files

| File                                      | Purpose                                   |
|-------------------------------------------|-------------------------------------------|
| `config.json`                         | The zsh prompt (this README's subject)    |
| `config.json.bak.YYYYMMDD-HHMMSS`     | Manual rollback snapshots                 |
| `CLAUDE.md`                               | Rules for AI-assisted edits               |
| `README.md`                               | This file                                 |

## Reload after editing

```sh
exec zsh
```

Quick sanity check without restart:

```sh
oh-my-posh print primary \
  --config ~/.config/ohmyposh/config.json --shell zsh
```

Per-flavor sanity check:

```sh
for f in mocha frappe macchiato latte; do
  echo "=== $f ==="
  CATPPUCCIN_FLAVOR=$f oh-my-posh print primary \
    --config ~/.config/ohmyposh/config.json --shell zsh
done
```

## Design constraints (short version)

- **Catppuccin palette role names only** — never raw hex in segment
  defs, so flavor switching cascades through every pill.
- **Color cycle** — no two adjacent pills share an accent role.
- **Every callout segment has a `cache` block** — keep prompt render
  under one frame. Music caches 3s, sysinfo 5s, git 5m.
- **Music widget hidden when not playing** — gated on `.playing` from
  `media-control` JSON output.

Full details live in `CLAUDE.md` next to this file.
