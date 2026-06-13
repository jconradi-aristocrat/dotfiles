# Provisioning a generic Linux VM

For any Ubuntu/Debian VM you can SSH into:

```sh
ssh user@your-vm
bw login                          # one-time per VM
export BW_SESSION=$(bw unlock --raw)
curl -fsSL https://raw.githubusercontent.com/jconradi-aristocrat/dotfiles/master/bootstrap.sh | bash
```

If you forked, replace the URL or set `DOTFILES_REPO` first.

## Quick local test with Multipass (macOS)

```sh
~/.local/share/chezmoi/.devbox/test-in-vm.sh
```

(See `test-in-vm.sh` in the repo for the canonical recipe.)
