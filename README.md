# brzrkr — NixOS config

Barebones NixOS + Hyprland (native Lua config) + Quickshell bar. Tokyo Night everywhere.

## The map — where everything lives

```
~/nixos/
├── flake.nix               # THE entry point: inputs (nixpkgs, home-manager,
│                           # disko, stylix) + the module list below
├── flake.lock              # pinned versions of everything (nix flake update)
├── KEYBINDS.txt            # keybind cheatsheet (live version: SUPER+SHIFT+/)
│
├── hosts/brzrkr/
│   ├── default.nix         # MACHINE: boot, networking/firewall, user account,
│   │                       # SERVICES (ssh, tailscale, docker, printing), nix gc
│   ├── hardware-configuration.nix   # generated at install — don't edit
│   └── disko.nix           # disk layout (LUKS + ext4) — install-time only
│
├── modules/
│   ├── desktop.nix         # Hyprland, greetd login, audio, bluetooth, fonts,
│   │                       # ALL system packages (desktop apps + CLI/dev tools + LSPs)
│   ├── nvidia.nix          # GPU driver (open kernel module) + Wayland env
│   ├── gaming.nix          # Steam, RuneLite, Lutris, gamemode, mangohud
│   └── theme.nix           # stylix: base16 Tokyo Night → GTK/cursor/fonts
│
├── home/default.nix        # YOUR USER: user packages, zsh + aliases, git,
│                           # dotfile symlinks, user services (wallpaper,
│                           # polkit agent, elephant)
│
├── pkgs/                   # custom packages not in nixpkgs (linear)
│
└── config/                 # ← LIVE-EDITABLE dotfiles. Symlinked into ~/.config,
    │                       #   changes apply WITHOUT rebuild (hot-reload/restart app)
    ├── hypr/
    │   ├── hyprland.lua    # the compositor config (Lua, Hyprland 0.55+)
    │   ├── hl.meta.lua     # LSP stubs → autocomplete for the hl.* API in nvim
    │   ├── scripts/        # keybinds.sh (cheatsheet)
    │   └── hypridle/hyprlock.conf
    ├── quickshell/shell.qml  # bar + notifications + volume OSD (QML, hot-reloads)
    ├── walker/             # launcher config
    ├── nvim/               # kickstart.nvim (edit init.lua, own it)
    ├── ghostty/ starship/ tmux/  # app configs, carried over
    └── wallpapers/         # incl. tokyonight-nix.png (+ .svg source)
```

## The three files you'll actually touch

| I want to… | Edit | Then |
|---|---|---|
| add a program | `modules/desktop.nix` (system) or `home/default.nix` (user) | `nrs` |
| enable a service/daemon | `hosts/brzrkr/default.nix` | `nrs` |
| change keybinds/looks | `config/hypr/hyprland.lua` | auto-reloads (or `hyprctl reload`) |
| tweak the bar | `config/quickshell/shell.qml` | hot-reloads on save |
| configure nvim | `config/nvim/init.lua` | restart nvim |

## Commands

- `nrs` / `nrt` / `nrb` — rebuild switch / test / boot (aliases)
- `nix flake update && nrs` — upgrade everything to latest unstable
- `sudo nix-collect-garbage` — free disk (old generations)
- Find packages/options: https://search.nixos.org (Options tab for services!)

## Rules of the house

- **Nothing is installed imperatively** — every change is a line here, applied by `nrs`, undone by `git revert` + `nrs`
- Old generations stay bootable from the systemd-boot menu
- `~/dotfiles` is the retired pre-rewrite config (delete when confident)
