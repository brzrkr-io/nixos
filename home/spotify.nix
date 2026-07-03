# Spotify via spicetify: the client is patched at build time, so the theme is
# part of the derivation — changing it means a rebuild, unlike the symlinked
# runtime configs. Tokyo Night to match nvim/ghostty/quickshell.
{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  # Follows the build-time default (runtime `theme` switches everything else;
  # Spotify converges on the next rebuild)
  themeDefault = import ../config/themes/nix-default.nix;

  # theme/polarity -> spicetify theme + color scheme. Scheme names must match
  # the [sections] in each theme's color.ini (verified against the pinned rev).
  spice = {
    tokyonight = {
      theme = spicePkgs.themes.tokyoNight;
      colorScheme = { dark = "Night"; light = "Light"; }.${themeDefault.polarity};
    };
    gruvbox = {
      # no dedicated gruvbox spicetify theme; the "text" theme ships a Gruvbox
      # scheme (dark only — light polarity gets it too, least-bad option)
      theme = spicePkgs.themes.text;
      colorScheme = "Gruvbox";
    };
  }.${themeDefault.theme};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    inherit (spice) theme colorScheme;
  };
}
