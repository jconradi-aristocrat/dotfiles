# CLAUDE.md — `~/.config/ohmyposh/`

Conventions and constraints for the oh-my-posh prompt. Read this before
editing `config.json`. Parent rules in `~/.config/CLAUDE.md` apply;
this file refines and overrides them only where called out.

## Targets

| Where                 | Terminal           | Connection                    | Typical width |
|-----------------------|--------------------|-------------------------------|---------------|
| MacBook M4 Max        | Ghostty            | local                         | 160–240 cols  |
| iPhone 15             | Blink Shell        | mosh → M4 Max → tmux attach   | 40–100 cols   |

Both terminals render the same `config.json` — there is no
per-terminal config. Width tiers are the only differentiator.

## Font

`JetBrainsMonoNL Nerd Font` on both terminals. Nerd Font glyphs **are in
budget** (the Termius "no NF" rule from the older parent CLAUDE.md is
obsolete — Blink Shell renders NF cleanly).

When picking glyphs, prefer the well-supported ranges that JetBrains
Mono NF ships: `nf-fa-*`, `nf-dev-*`, `nf-cod-*`, and the `nf-md-*`
subset already used in `tmux.omp.json` (`󱟢`, `󰂄`, `󰁾`). Avoid niche
codepoints that may render as a tofu box.

## Catppuccin

- Canonical flavor: **Mocha**.
- The `palettes` block keeps all four flavors (mocha / frappe / latte /
  macchiato) and reads `$CATPPUCCIN_FLAVOR` to select. This is wired to
  the flavor switcher in `~/.config/zsh/functions.zsh`; don't break
  that contract.
- Use palette names (`p:mauve`, `p:crust`, etc.) — never hex.
- **Role-based palette.** Same role table is mirrored in
  `~/.config/tmux/tmux.conf` (with hex values inline because of
  catppuccin plugin load order — see `tmux/CLAUDE.md`). The two surfaces
  share one language.

  Lprompt rainbow walk (left → right): mauve → red → peach → yellow →
  green → sapphire. Rprompt rainbow walk: pink → peach → yellow →
  green → teal → sky → sapphire → blue → lavender → mauve.

  | Pill role               | bg                                    | fg                  |
  |-------------------------|---------------------------------------|---------------------|
  | os                      | `p:mauve`                             | `p:crust` bold      |
  | ssh (SSHSession)        | `p:red`                               | `p:crust` bold      |
  | root (elevated)         | `p:peach`                             | `p:crust` bold      |
  | vi-mode                 | `p:yellow` (fixed; mode shown by letter only) | `p:crust` bold      |
  | path                    | `p:green`                             | `p:crust` bold      |
  | git clean               | `p:sapphire`                          | `p:crust` bold      |
  | git dirty               | `p:yellow`                            | `p:crust` bold      |
  | git behind              | `p:pink`                              | `p:crust` bold      |
  | git diverged            | `p:red`                               | `p:crust` bold      |
  | git ahead               | `p:teal` (was green; collides with path) | `p:crust` bold   |
  | music (.playing)        | `p:pink`                              | `p:crust` bold      |
  | runtime (node/go/python/rust) | `p:peach` (all share one rainbow slot — only one renders per project) | `p:crust` bold |
  | connection (wifi/eth)   | `p:yellow`                            | `p:crust` bold      |
  | cpu (sysinfo)           | `p:green`                             | `p:crust` bold      |
  | disk (df /)             | `p:teal`                              | `p:crust` bold      |
  | battery (>50)           | `p:sky` (rainbow default)             | `p:crust` bold      |
  | battery (≤50)           | `p:yellow` (state override)           | `p:crust` bold      |
  | battery (≤30)           | `p:red` (state override)              | `p:crust` bold      |
  | exec time               | `p:sapphire`                          | `p:crust` bold      |
  | date                    | `p:lavender`                          | `p:crust` bold      |
  | clock                   | `p:mauve`                             | `p:crust` bold      |

  **Identity pills flipped to dark bgs in round 3** because pastel-text on
  pastel-pill failed readability at terminal sizes. Surface1 (#45475a) is
  a clear "dark gray, not black" and the bright role color stays
  saturated against it.

  **path is the left bar's anchor** — it sits last (rightmost), the eye's
  resting place before the `❯` input line. Lavender-on-surface0 reads
  softer + more considered. The folder icon is in peach (accent on dark
  pill — see "Icons pop" below).

### Color rules (HARD)

1. **Never** `#000000` or `#ffffff` anywhere — no exceptions.
2. **`p:crust` (#11111b) is the canonical fg on bright pastel pills.**
   Round 5 (2026-06-09) adopted the Starship Catppuccin convention —
   crust gives more visual weight than base on saturated bgs and is the
   official Catppuccin recommendation. The round-1 ban on crust is
   lifted; `p:base` is now the deprecated "pure black isn't cutting it"
   value.
3. `p:text` (#cdd6f4) is allowed on *dark* bgs only (surface0, surface1,
   mantle). Never on bright pastel pills — contrast slips into "blurry
   white on light".
5. **Git counter exception (Round 8 — 2026-06-09).** The `git` segment's
   `+N` (added) and `-N` (deleted) counters are deliberately hardcoded
   to `<#22c55e>` / `<#ef4444>` — bright traditional git-diff
   green/red. Catppuccin `p:green` / `p:red` wash out on the yellow
   "dirty" git pill, defeating the whole point of an at-a-glance status
   indicator. This is the ONLY palette-bypass in the config.
4. Every block segment uses a bright Catppuccin accent bg cycling
   through the rainbow walk (mauve → red → peach → yellow → green →
   sapphire on lprompt; pink → peach → yellow → green → teal → sky →
   sapphire → blue → lavender → mauve on rprompt). The dark surface0 /
   surface1 anchors that previously held identity/info pills are gone —
   every pill carries a different accent.

### Icons pop rule

On `surface0` / `surface1` pills (dark), color the icon in a contrasting
accent (peach for path's folder, mauve for mem, lavender for clock,
green for battery, peach for exec time). On bright pastel pills (git,
runtime, aws, kubectl), text + icon stay in `p:base` because the pill
itself is already loud — an icon-accent color would clash.

Prefer Material Design glyphs (`nf-md-*`, BMP and SMP ranges) over the
thin font-awesome variants. They render with more visual weight at the
same cell size — that's what makes them "pop".

### Capsule grammar (Round 7 — block-level caps)

The whole top row of each prompt block is ONE continuous chain of
diamond-style pills.

- **All segments**: `style: "diamond"`.
- **Lprompt segments**: `leading_diamond: ""` (empty), `trailing_diamond:
  ""` (U+E0B0 right-pointing solid arrow joint) — segments grow
  rightward toward the typing area.
- **Rprompt segments (Round 8 — 2026-06-09)**: `leading_diamond: ""`
  (U+E0B2 left-pointing solid arrow joint), `trailing_diamond: ""`
  (empty). Mirrors lprompt: sharp arrows point INWARD (toward center)
  as more rprompt segments are appended from the right edge. Same rule
  applies to tooltips — they live in the rprompt slot and must match.
- **Block-level for lprompt** `leading_diamond: ""` (U+E0B6 rounded
  LEFT cap), `trailing_diamond: ""` (U+E0B4 rounded RIGHT cap).
- **Block-level for rprompt (Round 8 — 2026-06-09)** `leading_diamond:
  ""` (U+E0B2 left arrow — the leftmost visual edge sharp-points
  into the void on the left), `trailing_diamond: ""` (U+E0B4 rounded
  right cap — soft anchor against the screen edge).
- **Why block-level**: OMP draws the block-level cap regardless of
  which segment ends up first/last *visible*. This solves the previous
  problem where conditional first/last segs (music, root, runtime
  langs) being hidden killed the outer cap. The docs say block-level
  cap is for the case "you always want to start the block with the same
  leading diamond, regardless of which segment is enabled or not"
  (https://ohmyposh.dev/docs/configuration/block).
- **No `powerline_symbol`** anywhere — diamond `trailing_diamond`
  carries the joint. Powerline-style on a `command`-type segment
  crashes OMP v29.14.0 with a nil-pointer SIGSEGV under `--force`;
  stick to diamond style throughout.
- **Weight (Round 8 — 2026-06-09)**: bold is now reserved for the
  *anchor* elements only — the `path` segment's `{{ .Path }}` and the
  bottom-line `❱` prompt character (`<b>❱</b> ` — U+2771, the heavy
  sibling of `❯`). Every other segment was de-bolded; emphasis flows
  from color, not weight. Icons stay non-bold either way.

### Programmatic editing pattern

Every Round-5 edit to capsule shapes / colors goes through a Python
script that reads the JSON, walks segments, and writes back with
`json.dump(..., ensure_ascii=False, indent=2)`. **Use `chr(0xE0B0)` /
`chr(0xE0B4)` / `chr(0xE0B6)` for the powerline glyphs** — literal
glyphs in source code get stripped by Claude Code's message layer
before reaching bash, while `chr()` and `\uXXXX` escapes survive
reliably.

## Responsive tiers

`min_width` is a top-level segment field that hides the segment when
`COLUMNS < N`. Tiers (cumulative):

| Tier | min_width | Left segments added                | Right segments added                                                |
|------|-----------|------------------------------------|---------------------------------------------------------------------|
| 0    | always    | os · vi-mode · path · git          | executiontime                                                       |
| 1    | 80        | + ssh (if SSHSession) · + root (if elevated) | + clock · + music (if media loaded — Round 8)                |
| 2    | 120       | (no add)                           | + battery                                                           |
| 3    | 160       | (no add)                           | + runtime (node/python/go/rust) · + connection · + cpu · + memory · + disk · + date |

**Round 4 (2026-06-09)** layout: identity row on the left (os, ssh,
root, vi-mode) all on `surface1`; anchor (path) and live state (git) on
the right of that; ephemeral / live status on the right block.

The **79-column single-row rule from `~/.config/CLAUDE.md` still
applies** to tier 0. Anything added to tier 0 must keep the visible
left-block width ≤ ~70 chars on a long-path home directory.

## Schema modernization (Round 6 — v4 hardening)

The config now tracks the current v29 schema, not legacy v3 shapes:

- **`options` (NOT `properties`)** — every segment uses the new name. The
  `properties` field is `deprecated: true` in `themes/schema.json` and will
  be removed. If you write a new segment, use `options`.
- **`type: "rprompt"`** for the right block — not `type: "prompt"` +
  `alignment: "right"` + `newline: false`. The dedicated `rprompt` block
  type uses zsh's native `RPSx` slot, renders independently of `PROMPT`,
  and survives line redraws cleanly (vi-mode pill refresh, transient
  prompt). Only ONE `rprompt` block is allowed per config.
- **`async: true`** at top level — zsh starts accepting input as soon as
  the cached / fast prompt frame is rendered; slow segments resolve in
  background and the prompt redraws when they're ready.
- **`streaming: 120`** at top level — segments still computing after
  120ms get their `placeholder` text in the first render and are filled
  in via `_omp_async_handler` (see `~/.cache/oh-my-posh/init.*.zsh`).
  100ms is OMP's minimum recommendation; we use 120 for a comfort buffer
  on slower terminals (Blink over mosh).
- **`placeholder: " … "`** on every subprocess / network / git segment —
  music (`media-control`), disk (`df`), connection (wifi probe), sysinfo
  (system call), battery, runtime langs (lockfile parse), git
  (`fetch_status`), aws/k8s/docker/terraform tooltips. Without it OMP
  shows generic `...` during streaming gaps.

### Editing rule

When adding a new segment that touches I/O (subprocess, network, disk),
also add a `placeholder` field. Without it the streaming gap shows `...`
which breaks the visual rhythm of the rainbow.

## Performance budget

The prompt fires on every command. Hard rules:

1. Every segment that touches disk, network, or subprocess must set a
   segment-level `cache: { duration, strategy }` (the new shape — the
   legacy `cache_duration` inside `properties` still works but is
   deprecated). `strategy` is `folder`, `session`, or `device`.
2. Git is the most expensive — keep `fetch_status: true` but never drop
   the `5m / folder` cache. Per-keystroke remote lookups will tank the
   prompt.
3. Runtime segments (`node`, `python`, `go`, `rust`) use
   `display_mode: "files"` so they only fire inside a project. Don't
   switch to `always`.
4. `aws` / `kubectl` are gated behind both `min_width: 160` AND
   `display_default: false` / non-empty context — they cost nothing in a
   blank shell.
5. **Music widget** is a `command`-type segment that runs
   `media-control get | jq ...` every 3s (`strategy: session`). The
   template is gated with `{{ if .Output }}` so the pill disappears the
   moment audio stops — empty stdout from a `command` segment is NOT
   auto-hidden by OMP. **Round 8 (2026-06-09)**: the jq filter gates on
   `.title` presence (not `.playing`). Chrome's MediaRemote leaves
   `playing: false` even while audio plays in a YouTube tab / YTM-Player
   Electron app — so `.playing` is unreliable. Title-presence is the
   real "is media loaded" signal. The widget prefixes `▶` when playing
   and `⏸` when paused, so the play state is still visible at a glance.
   `min_width` is also lowered to 80 so it shows on narrower terminals
   (Blink mosh sessions, side-by-side tmux panes).
6. **`executiontime`** runs with `always_enabled: true` and `threshold: 0`
   so `.FormattedMs` is always populated for the transient prompt's
   cross-ref `{{ .Segments.Executiontime.FormattedMs }}`. The right-side
   pill itself is template-gated with `{{ if gt .Ms 2000 }}` so it still
   only renders for commands slower than 2s. If you change the threshold,
   change the template guard — not `properties.threshold` — or the
   transient prompt loses its duration on quick commands.

When adding any segment that calls out, target a `oh-my-posh debug`
budget of **≤ 50ms** per segment after cache warmup.

## Tooltips vs persistent segments (Round 7)

Directory-bound tools render as PERSISTENT rprompt segments, not
tooltips:

- **`git`, `node`, `python`, `go`, `rust`** — already persistent via
  `display_mode: "files"`, fire when a lockfile or `.git/` is detected.
- **`docker`** — persistent, fires when `Dockerfile` / `compose.yml`
  is in cwd. Template uses `.Context` (NOT `.Namespace` — docker
  segment only exposes `.Context`; the old tooltip template with
  `.Namespace` errors with "unable to create text based on template").
- **`terraform`** — persistent, fires when `*.tf` is in cwd. Uses
  `.WorkspaceName`. Set `fetch_version: true` to expose `.Version`.

Tooltips remain only for **env-driven** tools that aren't bound to a
directory:

- **`aws`** — fires when typing `aws` / `terraform` / `sam` / `cdk`.
- **`kubectl`** — fires when typing `kubectl` / `k` / `helm`.

Rule: if the tool's relevance can be derived from cwd, make it a
persistent rprompt segment with `display_mode: "files"`. Otherwise
(profile/context env vars only) keep it as a tooltip.

## Editing workflow

1. Read this file.
2. Read the parent `~/.config/CLAUDE.md`.
3. Draft the change.
4. **Validate before saving** with the `oh-my-posh` MCP server:
   `mcp__oh-my-posh__validate_config` on the full JSON, or
   `mcp__oh-my-posh__validate_segment` on a single segment.
5. Write the file.
6. Sanity-render: `oh-my-posh print primary --config
   ~/.config/ohmyposh/config.json --shell zsh`.
7. Width sweep — these widths matter:
   ```
   stty cols 40  && exec zsh   # iPhone portrait worst case
   stty cols 79  && exec zsh   # parent CLAUDE.md baseline
   stty cols 80  && exec zsh   # tier-1 threshold
   stty cols 120 && exec zsh   # tier-2 threshold
   stty cols 160 && exec zsh   # tier-3 threshold (Ghostty wide)
   ```
   Reset with `stty cols $(tput cols)` or open a fresh pane.
8. Render in **both** real terminals before declaring done.

## Files in this directory

| File                  | Used by                                    |
|-----------------------|--------------------------------------------|
| `config.json`         | zsh primary prompt (`plugins.zsh:36`)      |
| `*.bak.*`             | rollback artifacts; keep latest, prune old |
| `CLAUDE.md`           | this file                                  |
| `README.md`           | human-facing overview + mockups            |

(`tmux.omp.json` was removed 2026-06; tmux uses `catppuccin/tmux` modules
directly, styled to match this prompt — see `~/.config/tmux/CLAUDE.md`.)

The zsh init line lives at `~/.config/zsh/plugins.zsh:36`:
```sh
zsh_eval_cache oh-my-posh oh-my-posh init zsh --config ~/.config/ohmyposh/config.json
```

## Cross-references

- `~/.config/CLAUDE.md` — parent rules (single-row, width gating).
- `~/.config/zsh/CLAUDE.md` — where the eval lives and how the shell
  boot path treats it.
- `~/.config/zsh/plugins.zsh` — sources zsh-vi-mode AND exports the
  `OMP_VI_MODE` env var the vi-mode pill reads. The
  `zvm_after_select_vi_mode` hook fires on every mode change
  (i/Esc/v/V/R) and updates the var. `INSERT` is bootstrapped before
  zvm loads so the first prompt render is correct.
- `~/.config/zsh/functions.zsh` — has a `preexec` hook
  (`_omp_capture_command`) that exports `$OMP_LAST_COMMAND` so the
  transient prompt can show the just-typed command (oh-my-posh has no
  visibility into the command buffer itself).
- `~/.config/tmux/CLAUDE.md` — the tmux status bar is styled via
  `catppuccin/tmux` modules using the same role table above. Nvim's
  lualine is intentionally left at the LazyVim default (round 2: we
  tried `vim-tpipeline` and the lualine override, they didn't pay off).

## External installs

- `brew install media-control` — powers the music widget. Bridges into
  macOS MediaRemote via the `mediaremote-adapter` framework, so it
  works on Sequoia 15.4+ and Tahoe where `nowplaying-cli` is broken.
  Covers Apple Music, Spotify, YouTube Music Desktop, Chrome YouTube
  tabs, podcasts — anything publishing to MediaRemote.
