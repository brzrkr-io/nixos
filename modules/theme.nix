# Stylix: one base16 scheme (Tokyo Night) as the single source of truth for
# GTK, cursor, and fonts. autoEnable is OFF — hand-crafted configs (hyprland.lua,
# quickshell, dunst, ghostty, nvim's tokyonight plugin) keep ownership of their
# own colors; stylix only themes what we explicitly enable.
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  stylix = {
    enable = true;
    autoEnable = false;

    # Palette source (also doubles as the wallpaper stylix knows about)
    image = ../config/wallpapers/tokyonight-nix.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    polarity = "dark";

    cursor = {
      package = pkgs.apple-cursor;
      name = "macOS";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
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
