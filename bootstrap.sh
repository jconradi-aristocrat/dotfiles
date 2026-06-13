#!/usr/bin/env bash
# bootstrap.sh — portable, fork-friendly one-shot for macOS, generic Linux,
# Devbox Cloud, or GitHub Codespaces.
#
# Override sources:
#   DOTFILES_REPO=owner/name        pull from a different GitHub repo
#   DOTFILES_BRANCH=name            pull from a non-default branch
#   DOTFILES_LOCAL_SOURCE=/path     init chezmoi from a local dir (VM testing)
#   DOTFILES_SKIP_BW=1              skip Bitwarden gate + remove private_*.tmpl
#                                   before apply (VM smoke testing)

set -euo pipefail

OS="$(uname -s)"
REPO="${DOTFILES_REPO:-jconradi-aristocrat/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-master}"
LOCAL_SOURCE="${DOTFILES_LOCAL_SOURCE:-}"
SKIP_BW="${DOTFILES_SKIP_BW:-0}"

IS_CLOUD=0
[ -n "${CODESPACES:-}" ]          && IS_CLOUD=1
[ -n "${DEVBOX_CLOUD:-}" ]        && IS_CLOUD=1
[ -n "${GITPOD_WORKSPACE_ID:-}" ] && IS_CLOUD=1
[ -n "${REMOTE_CONTAINERS:-}" ]   && IS_CLOUD=1

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# 1. Nix
if ! command -v nix >/dev/null 2>&1; then
  say "Installing Nix (Determinate Systems installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true

# 2. Devbox
if ! command -v devbox >/dev/null 2>&1; then
  say "Installing devbox"
  curl -fsSL https://get.jetify.com/devbox | bash -s -- -f
fi

# 3. Homebrew (macOS, non-cloud)
if [ "$OS" = "Darwin" ] && [ "$IS_CLOUD" -eq 0 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# 4. chezmoi
if ! command -v chezmoi >/dev/null 2>&1; then
  say "Installing chezmoi"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

# 5. Bitwarden CLI (skip if SKIP_BW)
if [ "$SKIP_BW" = "0" ] && ! command -v bw >/dev/null 2>&1; then
  say "Installing Bitwarden CLI"
  if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    brew install bitwarden-cli
  else
    nix profile install nixpkgs#bitwarden-cli
  fi
fi

# 6. Vault session gate
if [ "$SKIP_BW" = "0" ]; then
  if [ -z "${BW_SESSION:-}" ]; then
    if [ "$IS_CLOUD" -eq 1 ]; then
      echo "Cloud context detected but BW_SESSION is not set."
      echo "Set BW_SESSION as a workspace/Codespaces secret and re-run."
      exit 1
    fi
    echo
    echo "Run these in your shell, then re-run this script:"
    echo "  bw login"
    echo "  export BW_SESSION=\$(bw unlock --raw)"
    exit 1
  fi
  export BW_SESSION
fi

# 7. chezmoi init
if [ -n "$LOCAL_SOURCE" ]; then
  say "Initializing chezmoi from local source $LOCAL_SOURCE"
  # Make a writable copy at the chezmoi source dir so SKIP_BW can prune templates.
  mkdir -p "$HOME/.local/share/chezmoi"
  rsync -a --delete "$LOCAL_SOURCE/" "$HOME/.local/share/chezmoi/"
  if [ "$SKIP_BW" = "1" ]; then
    say "DOTFILES_SKIP_BW=1 — removing private_*.tmpl secret templates"
    find "$HOME/.local/share/chezmoi" -type f -name 'private_*.tmpl' -delete || true
    find "$HOME/.local/share/chezmoi" -type d -name 'private_*' -prune -exec rm -rf {} + || true
  grep -rlZ "{{[^}]*bitwarden" "$HOME/.local/share/chezmoi" 2>/dev/null | xargs -0 rm -f || true
  fi
  chezmoi init --apply
else
  say "Initializing chezmoi from $REPO@$BRANCH"
  if [ "$SKIP_BW" = "1" ]; then
    chezmoi init --branch "$BRANCH" "$REPO"
    find "$HOME/.local/share/chezmoi" -type f -name 'private_*.tmpl' -delete || true
    find "$HOME/.local/share/chezmoi" -type d -name 'private_*' -prune -exec rm -rf {} + || true
  grep -rlZ "{{[^}]*bitwarden" "$HOME/.local/share/chezmoi" 2>/dev/null | xargs -0 rm -f || true
    chezmoi apply
  else
    chezmoi init --apply --branch "$BRANCH" "$REPO"
  fi
fi

# 8. devbox globals
say "Installing devbox global packages"
SRC="$HOME/.local/share/chezmoi/devbox.json"
DEST_DIR="$(devbox global path 2>/dev/null || echo "$HOME/.local/share/devbox/global")"
mkdir -p "$DEST_DIR"
[ -f "$SRC" ] && cp "$SRC" "$DEST_DIR/devbox.json"
devbox global install || say "(devbox install reported errors — review above)"

say "Done. Open a new shell."
