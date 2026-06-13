#!/usr/bin/env bash
# Run inside `devbox cloud shell` to materialize the rest of the dotfiles.
set -euo pipefail
REPO="${DOTFILES_REPO:-jconradi-aristocrat/dotfiles}"
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
chezmoi init --apply "$REPO"
