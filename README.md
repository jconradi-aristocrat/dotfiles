# dotfiles

Portable, fork-friendly developer environment managed by
[chezmoi](https://chezmoi.io) + [devbox](https://www.jetify.com/devbox) +
[Bitwarden](https://bitwarden.com).

One repo. One bootstrap command. Rebuild your full setup on:

- a fresh macOS host,
- a generic Linux VM,
- a Devbox Cloud shell,
- a GitHub Codespace or any devcontainer.

Tear it down just as fast. No secrets in the repo. No identifying info
hardcoded. Fork it, point the bootstrap at your fork, and go.

---

## What's in the repo

| Layer | Owns | File |
| --- | --- | --- |
| **chezmoi** | Dotfiles, scripts, templates | `dot_*`, `*.tmpl` |
| **devbox** | Cross-OS CLI tools (every shell-level binary that isn't a GUI app) | `devbox.json` |
| **Homebrew** | macOS GUI apps + Mac-only utilities | `Brewfile.darwin` |
| **Bitwarden** | Plaintext secrets — gh tokens, ssh keys, .npmrc, .mcp.json | Referenced via `{{ bitwarden ... }}` template funcs |
| **chezmoi prompts** | Your name, email, GitHub handle, signing key | `.chezmoi.toml.tmpl` |

---

## Prerequisites

- A Bitwarden account with the [Bitwarden CLI](https://bitwarden.com/help/cli/)
  reachable as `bw`. The bootstrap installs it, but you'll need vault creds.
- The vault must contain the items listed in [Vault contract](#vault-contract).
  Stub them with placeholder strings if you don't need every secret.
- On macOS only: ~10 GB free for Nix + Homebrew + casks.

---

## One-line install

```sh
curl -fsSL https://raw.githubusercontent.com/jconradi-aristocrat/dotfiles/master/bootstrap.sh | bash
```

If you've forked this repo, override the source:

```sh
DOTFILES_REPO=your-handle/dotfiles curl -fsSL \
  https://raw.githubusercontent.com/your-handle/dotfiles/master/bootstrap.sh | bash
```

Useful env-var overrides:

| Variable | Effect |
| --- | --- |
| `DOTFILES_REPO=owner/name` | Pull templates from a different GitHub repo (your fork). |
| `DOTFILES_BRANCH=name` | Pull from a non-default branch. |
| `DOTFILES_LOCAL_SOURCE=/path/to/dir` | Init chezmoi from a local directory instead of GitHub — used by the VM smoke test. |
| `DOTFILES_SKIP_BW=1` | Skip the Bitwarden gate AND delete `private_*.tmpl` files before apply. Used by the VM smoke test. |

The bootstrap will:

1. Install Nix (Determinate Systems installer, if missing).
2. Install devbox (if missing).
3. Install Homebrew on macOS (skipped in cloud contexts).
4. Install chezmoi.
5. Install the Bitwarden CLI (unless `DOTFILES_SKIP_BW=1`).
6. Gate on `bw login` + an unlocked `$BW_SESSION` (unless skipped).
7. Run `chezmoi init --apply` — prompts you for name, email, GitHub handle,
   signing key, personal-vs-work, cloud-target.
8. Run `devbox global install` to materialize the cross-OS toolchain.

Time on a clean machine: ~10 min on Linux, ~15 min on a fresh Mac.

---

## Vault contract

The repo's templates reference Bitwarden items **by name**. Create these
items in your own vault before first apply.

| Item name | Field | Used by |
| --- | --- | --- |
| `gh-token` | `login.password` | `~/.config/gh/hosts.yml` |
| `npmrc` | `login.password` | `~/.npmrc` |
| `mcp-json` | `notes` (full JSON body) | `~/.mcp.json` |
| `slack-mcp-tokens` | `notes` (full JSON body) | `~/.slack-mcp-tokens.json` |
| `ssh-id_ed25519` | `attachment: id_ed25519` | `~/.ssh/id_ed25519` |
| `ssh-id_ed25519` | `attachment: id_ed25519.pub` | `~/.ssh/id_ed25519.pub` |
| `gcloud-application-default` | `notes` (full ADC JSON body) | `~/.config/gcloud/application_default_credentials.json` |

Missing an item? The corresponding `private_*.tmpl` will fail to render —
either create the vault item, delete the template, or use `DOTFILES_SKIP_BW=1`.

---

## Cloud targets

### GitHub Codespaces / devcontainers

Add `BW_SESSION` as a Codespaces user secret. The included
`.devcontainer/devcontainer.json` runs `bootstrap.sh` in `postCreateCommand`.

### Devbox Cloud

```sh
devbox cloud shell
```

`.devbox/cloud-init.sh` runs `chezmoi init --apply` against this repo.

### Generic Linux VM

```sh
curl -fsSL https://raw.githubusercontent.com/jconradi-aristocrat/dotfiles/master/bootstrap.sh | bash
```

See [`docs/PROVISION-VM.md`](./docs/PROVISION-VM.md) for the longhand.

---

## Daily use

```sh
chezmoi diff
chezmoi re-add ~/.zshrc
chezmoi add ~/path/file
chezmoi apply
chezmoi update
```

---

## Teardown

```sh
~/.local/share/chezmoi/teardown.sh
```

---

## Layout

```
~/.local/share/chezmoi/
├── README.md
├── LICENSE
├── bootstrap.sh
├── teardown.sh
├── devbox.json
├── Brewfile.darwin
├── .chezmoi.toml.tmpl
├── .chezmoiignore.tmpl
├── .chezmoidata/
├── .chezmoiscripts/
├── .devcontainer/
├── .devbox/
├── docs/
├── dot_zshrc
├── dot_tmux.conf
├── dot_gitconfig.tmpl
├── dot_config/
├── dot_claude/
├── dot_hammerspoon/             (darwin)
├── dot_agent-deck/
├── private_dot_*.tmpl           (Bitwarden-templated)
└── run_*_*.sh.tmpl
```

License: MIT.
