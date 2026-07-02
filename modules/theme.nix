# Stylix: one base16 scheme as the single source of truth for GTK, cursor, and
# fonts. autoEnable is OFF — hand-crafted configs (hyprland.lua, quickshell,
# dunst, ghostty, nvim) get their colors from the runtime theme system
# (config/themes/, `theme` CLI); stylix only themes what we explicitly enable.
{ config, pkgs, lib, inputs, username, hostname, ... }:

let
  # Build-time default (runtime switching is handled by the `theme` CLI;
  # edit config/themes/nix-default.nix + rebuild to move GTK here too)
  themeDefault = import ../config/themes/nix-default.nix;
in
{
  stylix = {
    enable = true;
    autoEnable = false;

    # Palette source (also doubles as the wallpaper stylix knows about)
    image = ../config/wallpapers/tokyonight-nix.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${themeDefault.base16}.yaml";
    polarity = themeDefault.polarity;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };
      sansSerif = config.stylix.fonts.monospace;
      serif = config.stylix.fonts.monospace;
      sizes = {
        applications = 9;
        terminal = 12;
      };
    };

    targets = {
      gtk.enable = true;
    };
  };
}
