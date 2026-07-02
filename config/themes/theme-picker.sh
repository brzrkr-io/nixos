# theme-picker — walker dmenu over themes + wallpapers (SUPER+CTRL+T).
# Picking a wallpaper also switches to its mapped theme (wallpaper-map.conf).

entries() {
  theme list | sed 's/^/theme: /'
  find "$HOME/nixos/config/wallpapers" -maxdepth 1 -type f \
    \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
    -printf '%f\n' 2>/dev/null | sort | sed 's/^/wallpaper: /'
}

sel="$(entries | walker --dmenu)" || exit 0

case "$sel" in
  "theme: "*) theme set "${sel#theme: }" ;;
  "wallpaper: "*) theme wallpaper "${sel#wallpaper: }" ;;
esac
