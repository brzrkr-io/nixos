# Single source of truth for BUILD-TIME theme consumers (stylix GTK + spicetify
# Spotify — the latter derives its theme from `theme`+`polarity` in
# home/spotify.nix). Runtime switching via the `theme` CLI is independent of
# this; edit here and rebuild when you want GTK/Spotify to converge.
# NOTE: keep flat `key = "value"` lines — theme.sh greps this file.
{
  theme = "tokyonight";
  polarity = "dark";
  base16 = "tokyo-night-dark"; # basename in ${pkgs.base16-schemes}/share/themes/
}
