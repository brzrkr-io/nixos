# Spotify via spicetify: the client is patched at build time, so the theme is
# part of the derivation — changing it means a rebuild, unlike the symlinked
# runtime configs. Tokyo Night to match nvim/ghostty/quickshell.
{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.tokyoNight;
  };
}
