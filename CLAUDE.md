# CLAUDE.md — brzrkr NixOS repo

Read README.md for the full repo map. Rules for working here:

## The two-speed model (label every change!)
- ⚡ **Live now**: anything under `config/` — symlinked into ~/.config, hot-reloads
  (hyprland.lua via `hyprctl reload`, quickshell/walker on restart, ghostty on
  Ctrl+Shift+comma). No rebuild.
- 🔧 **Needs `nrs`**: any `.nix` file. Claude CANNOT sudo here (sandbox sets
  no-new-privileges) — build with
  `nix build .#nixosConfigurations.brzrkr.config.system.build.toplevel -o result`
  to verify, then Parker runs `nrs` in his own terminal. ALWAYS tell him when
  changes are stacked waiting on nrs.

## House rules
- Barebones ethos: no frameworks, no unused packages, prefer deleting to adding.
- Every logical change = one commit, ordinary commit message, explain the *why*.
- Aesthetic choices: SHOW, don't describe — apply live (hyprctl setcursor,
  font swap + reload, awww img) or screenshot; Parker decides with his eyes.
- Verify with real commands (systemd-analyze, hx --health, headless nvim, grim
  screenshots) instead of asserting.
- Mac muscle memory is law: SUPER=Cmd, xremap handles GUI apps
  (modules/mac-keys.nix), ghostty has native super binds.

## Concurrency
A second Claude session often works this repo simultaneously. Before editing:
`git status` + expect "file modified since read" errors. Respect the runtime
theme system (config/themes/, `theme` CLI, generated files like
quickshell Colors.qml and walker themes/current/) — edit SOURCES (style.base.css,
fragments), never just generated output.

## Known traps (details: ~/.claude memory brzrkr-machine-gotchas)
- pkgs.swww is `awww` now (binaries renamed)
- hyprctl dispatch/keyword parse as Lua on Hyprland 0.55+; use `hyprctl eval`
- .config/hypr and other config dirs are repo symlinks — home-manager CANNOT
  write files inside them (use .local/share/... instead)
- mason doesn't work on NixOS: nvim/helix LSP binaries come from
  modules/desktop.nix; add both places when adding a language
- `pkill -x <app>` misses nix-wrapped binaries — comm is `.<app>-wrapped`
- launcher app index lives in elephant.service (user unit), NOT walker —
  after an nrs that adds apps: `systemctl --user restart elephant`
- ESP is 512MB: NVIDIA stays OUT of initrd; keep generations pruned
