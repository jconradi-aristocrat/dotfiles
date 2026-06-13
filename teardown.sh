#!/usr/bin/env bash
set -euo pipefail
OS="$(uname -s)"
say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

say "Removing chezmoi-managed files"
chezmoi purge --force 2>/dev/null || true

say "Uninstalling devbox globals"
if command -v devbox >/dev/null 2>&1; then
  devbox global rm --all 2>/dev/null || true
fi

say "Wiping Nix profile history"
if command -v nix >/dev/null 2>&1; then
  nix profile wipe-history 2>/dev/null || true
  nix-collect-garbage -d 2>/dev/null || true
fi

if [ "$OS" = "Darwin" ] && [ -f "$HOME/.local/share/chezmoi/Brewfile.darwin" ]; then
  say "Brew bundle cleanup"
  brew bundle cleanup --force --file "$HOME/.local/share/chezmoi/Brewfile.darwin" || true
fi
say "Done."
