# Single source of truth for BUILD-TIME theme consumers (stylix GTK + spicetify
# Spotify). Runtime switching via the `theme` CLI is independent of this; edit
# here and rebuild when you want GTK/Spotify to converge on a new default.
{
  theme = "tokyonight";
  polarity = "dark";
  base16 = "tokyo-night-dark"; # basename in ${pkgs.base16-schemes}/share/themes/
  spicetify = "tokyoNight"; # spicePkgs.themes attr (no gruvbox theme exists; use "text" + customColorScheme)
}
