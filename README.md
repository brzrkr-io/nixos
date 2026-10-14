# erewhon — NixOS config

Barebones NixOS + Hyprland (native Lua config) + Noctalia shell. Gruvbox and IosevkaTerm Nerd Font Mono everywhere.

## The map — where everything lives

```
~/nixos/
├── flake.nix               # THE entry point: inputs (nixpkgs, home-manager,
│                           # disko, stylix) + the module list below
├── flake.lock              # pinned versions of everything (nix flake update)
│
├── hosts/erewhon/
│   ├── default.nix         # MACHINE: boot, networking/firewall, user account,
│   │                       # SERVICES (ssh, tailscale, docker), nix gc
│   ├── hardware-configuration.nix   # detected boot-critical hardware modules
│   └── disko.nix           # disk layout (LUKS + Btrfs) — install-time only
│
├── modules/
│   ├── desktop.nix         # Hyprland, greetd login, audio, bluetooth, fonts,
│   │                       # ALL system packages (desktop apps + CLI/dev tools + LSPs)
│   ├── nvidia.nix          # GPU driver (open kernel module) + Wayland env
│   ├── gaming.nix          # Steam, RuneLite, Lutris, gamemode, mangohud
│   ├── mac-keys.nix        # Cmd-style GUI shortcuts; watches keyboard reconnects
│   └── theme.nix           # stylix: base16 Gruvbox → GTK/cursor/fonts
│
├── home/default.nix        # YOUR USER: user packages, zsh + aliases, git,
│                           # dotfile symlinks, user services (polkit agent,
│                           # darkman)
│
└── config/                 # ← LIVE-EDITABLE dotfiles. Symlinked into ~/.config,
    │                       #   changes apply WITHOUT rebuild (hot-reload/restart app)
    ├── hypr/
    │   ├── hyprland.lua    # the compositor config (Lua, Hyprland 0.55+)
    │   ├── hl.meta.lua     # LSP stubs → autocomplete for the hl.* API in nvim
    │   ├── scripts/        # keybinds.sh (cheatsheet)
    │   └── hypridle.conf
    ├── nvim/               # kickstart.nvim (edit init.lua, own it)
    ├── ghostty/ starship/ tmux/  # app configs, carried over
    └── wallpapers/         # wallpapers used by the theme switcher
```

## The three files you'll actually touch

| I want to… | Edit | Then |
|---|---|---|
| add a program | `modules/desktop.nix` (system) or `home/default.nix` (user) | `nrs` |
| enable a service/daemon | `hosts/erewhon/default.nix` | `nrs` |
| change keybinds/looks | `config/hypr/hyprland.lua` | auto-reloads (or `hyprctl reload`) |
| tweak the bar/shell | `config/noctalia/config.toml` or Noctalia settings GUI | live; runtime state is `~/.local/state/noctalia/settings.toml` |
| configure nvim | `config/nvim/init.lua` | restart nvim |

Noctalia generates `config/nvim/lua/matugen.lua`; its Base16 renderer is declared
in `config/nvim/init.lua` and pinned by `config/nvim/nvim-pack-lock.json`.

## Commands

- `nrs` / `nrt` / `nrb` — rebuild switch / test / boot (aliases)
- `nix flake update && nrs` — upgrade everything to latest unstable
- `sudo nix-collect-garbage -d` — free disk after removing old generations
- `nix store optimise` — manually deduplicate the store; weekly automation is enabled
- Find packages/options: https://search.nixos.org (Options tab for services!)

## Deployment policy

- `cache.nixos.org` and the official `nix-community.cachix.org` binary cache are enabled.
- Store deduplication runs weekly instead of during every build, keeping deployments responsive.
- Build outputs stay in `/tmp`; do not leave a `result` symlink in the repo because it pins a full system closure as a garbage-collection root.

## Go workflow

Neovim is the primary Go editor here: it is already configured with the
official `gopls`, format-on-save, staticcheck-backed diagnostics, Telescope
navigation, and Nix-provided Delve debugging. VS Code remains a good secondary
choice when a GUI debugger or extension marketplace matters more than a
reproducible editor configuration.

Inside a Go module:

```sh
gofmt -w .
go test -race ./...
go vet ./...
staticcheck ./...
govulncheck ./...
```

These follow the Go team's core guidance: standard formatting, tests including
the race detector, vetting, vulnerability scanning, and reviewable exported
APIs. References: [gopls](https://go.dev/gopls),
[Effective Go](https://go.dev/doc/effective_go), and
[Code Review Comments](https://go.dev/wiki/CodeReviewComments).

## Rules of the house

- **Nothing is installed imperatively** — every change is a line here, applied by `nrs`, undone by `git revert` + `nrs`
- Old generations stay bootable from the systemd-boot menu
- `~/dotfiles` is the retired pre-rewrite config (delete when confident)
