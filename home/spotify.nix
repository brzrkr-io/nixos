# Spotify via spicetify: the client is patched at build time, so the theme is
# part of the derivation — changing it means a rebuild. Rose Pine is supplied
# as a native custom color scheme because spicetify-nix has no Rose Pine theme.
{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  themeDefault = import ../config/themes/nix-default.nix;

  rosepineColors = {
    text = "e0def4";
    subtext = "908caa";
    main = "191724";
    sidebar = "1f1d2e";
    player = "1f1d2e";
    card = "26233a";
    shadow = "191724";
    "selected-row" = "403d52";
    button = "eb6f92";
    "button-active" = "ebbcba";
    "button-disabled" = "6e6a86";
    "tab-active" = "403d52";
    notification = "c4a7e7";
    "notification-error" = "eb6f92";
    misc = "6e6a86";
  };

  # Existing schemes remain available when switching the build-time default.
  spice = {
    tokyonight = {
      theme = spicePkgs.themes.tokyoNight;
      colorScheme = { dark = "Night"; light = "Light"; }.${themeDefault.polarity};
    };
    gruvbox = {
      theme = spicePkgs.themes.text;
      colorScheme = "Gruvbox";
    };
    rosepine = {
      theme = spicePkgs.themes.default;
      colorScheme = "custom";
      customColorScheme = rosepineColors;
    };
  }.${themeDefault.theme};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    inherit (spice) theme colorScheme;
    customColorScheme = spice.customColorScheme or { };
  };
}
