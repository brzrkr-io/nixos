# theme — runtime theme switcher (Omarchy-style). Wrapped by writeShellApplication
# in home/default.nix (which provides set -euo pipefail + runtime deps on PATH).
#
# Layout: config/themes/<name>/<dark|light>/ holds per-app color fragments.
# A stable symlink (~/.config/theme/current) points at the active variant;
# apps that can't follow a symlink flip get their config regenerated instead.

repo="$HOME/nixos"
themes_dir="$repo/config/themes"
wallpapers_dir="$repo/config/wallpapers"
state_dir="$HOME/.local/state/theme"
link="$HOME/.config/theme/current"

mkdir -p "$state_dir" "$HOME/.config/theme"

# Hooks (darkman, systemd) run outside the compositor's environment — recover
# the session handles so hyprctl/awww/dbus calls still land.
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$runtime/hypr" ]; then
  sig="$(find "$runtime/hypr" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | head -n1 || true)"
  if [ -n "$sig" ]; then export HYPRLAND_INSTANCE_SIGNATURE="$sig"; fi
fi
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  wd="$(find "$runtime" -mindepth 1 -maxdepth 1 -name 'wayland-*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -n1 || true)"
  if [ -n "$wd" ]; then export WAYLAND_DISPLAY="$wd"; fi
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"
fi

usage() {
  cat <<'USAGE'
theme — runtime theme switcher
  theme list                      available themes
  theme current                   active theme / mode / polarity
  theme set <name>                switch theme (keeps light/dark mode)
  theme mode <light|dark|system>  system = follow sunrise/sunset (darkman)
  theme toggle                    flip light/dark (leaves system mode)
  theme wallpaper [file]          no arg: re-apply theme wallpaper
                                  file: set it (mapped files switch theme too)
  theme apply                     re-apply current state to all apps
USAGE
}

read_state() { # <name> <default>
  if [ -f "$state_dir/$1" ]; then cat "$state_dir/$1"; else echo "$2"; fi
}

toml_get() { # <file> <key>  (flat `key = "value"` lines)
  grep -Po "^$2\\s*=\\s*\"\\K[^\"]*" "$1" 2>/dev/null || true
}

list_themes() {
  find "$themes_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

resolve_polarity() {
  local mode
  mode="$(read_state mode dark)"
  case "$mode" in
    light | dark) echo "$mode" ;;
    *) read_state polarity dark ;;
  esac
}

set_wallpaper() { # [file]
  local file line mt mp wp
  file="${1:-}"
  if [ -n "$file" ]; then
    if [ ! -f "$wallpapers_dir/$file" ]; then
      echo "theme: no wallpaper '$file' in config/wallpapers" >&2
      return 1
    fi
    line="$(grep -E "^${file}[[:space:]]" "$themes_dir/wallpaper-map.conf" 2>/dev/null || true)"
    if [ -n "$line" ]; then
      read -r _ mt mp <<<"$line"
      echo "$mt" >"$state_dir/theme"
      if [ "$(read_state mode dark)" = system ]; then
        echo "$mp" >"$state_dir/polarity" # temporary; next darkman flip wins
      else
        echo "$mp" >"$state_dir/mode"
      fi
      apply nowall
    fi
    awww img "$wallpapers_dir/$file" --transition-type fade >/dev/null 2>&1 || true
    return 0
  fi
  wp="$(toml_get "$(readlink -f "$link")/theme.toml" wallpaper)"
  if [ -n "$wp" ]; then
    awww img "$wallpapers_dir/$wp" --transition-type fade >/dev/null 2>&1 || true
  fi
}

apply() { # [nowall]
  local t p v alt gtk s nd
  t="$(read_state theme tokyonight)"
  p="$(resolve_polarity)"
  v="$themes_dir/$t/$p"
  if [ ! -d "$v" ]; then
    if [ "$p" = dark ]; then alt=light; else alt=dark; fi
    if [ -d "$themes_dir/$t/$alt" ]; then
      v="$themes_dir/$t/$alt"
      p="$alt"
    else
      echo "theme: no variant $t/$p — available themes:" >&2
      list_themes >&2
      exit 1
    fi
  fi

  ln -sfnT "$v" "$link"

  # regenerate configs for apps that can't follow the symlink flip
  cp "$v/quickshell.qml" "$repo/config/quickshell/Colors.qml"
  cat "$repo/config/starship/starship.base.toml" "$v/starship.toml" \
    >"$repo/config/starship/starship.toml"
  cat "$v/walker.css" "$repo/config/walker/themes/current/style.base.css" \
    >"$repo/config/walker/themes/current/style.css"

  # live refresh — every step best-effort (app may simply not be running)
  gtk="$(toml_get "$v/theme.toml" gtk)"
  if [ -n "$gtk" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "$gtk" >/dev/null 2>&1 || true
  fi
  hyprctl reload >/dev/null 2>&1 || true
  dunstctl reload >/dev/null 2>&1 || true
  gdbus call --session --dest com.mitchellh.ghostty \
    --object-path /com/mitchellh/ghostty \
    --method org.gtk.Actions.Activate reload-config '[]' '{}' >/dev/null 2>&1 || true
  tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
  for s in "$runtime"/nvim.*.0; do
    if [ -S "$s" ]; then
      nvim --server "$s" \
        --remote-expr "execute('source ~/.config/theme/current/nvim.lua')" \
        >/dev/null 2>&1 || true
    fi
  done
  if pgrep -x walker >/dev/null 2>&1; then
    pkill -x walker >/dev/null 2>&1 || true
    hyprctl dispatch exec 'walker --gapplication-service' >/dev/null 2>&1 || true
  fi

  if [ "${1:-}" != nowall ]; then
    set_wallpaper ""
  fi

  # stylix GTK palette + Spotify are baked at build time from nix-default.nix
  nd="$(toml_get "$themes_dir/nix-default.nix" theme)"
  if [ -n "$nd" ] && [ "$nd" != "$t" ]; then
    echo "note: GTK/Spotify default is '$nd' — edit config/themes/nix-default.nix + rebuild to converge"
  fi

  notify-send -a theme "Theme" "$t ($p)" >/dev/null 2>&1 || true
  echo "applied: $t/$p"
}

case "${1:-}" in
  list)
    list_themes
    ;;
  current)
    echo "theme:    $(read_state theme tokyonight)"
    echo "mode:     $(read_state mode dark)"
    echo "polarity: $(resolve_polarity)"
    if [ -L "$link" ]; then echo "variant:  $(readlink -f "$link")"; fi
    ;;
  set)
    name="${2:-}"
    if [ -z "$name" ] || [ ! -d "$themes_dir/$name" ]; then
      echo "theme: unknown theme '$name' — available:" >&2
      list_themes >&2
      exit 1
    fi
    echo "$name" >"$state_dir/theme"
    apply
    ;;
  mode)
    m="${2:-}"
    case "$m" in
      light | dark)
        echo "$m" >"$state_dir/mode"
        ;;
      system)
        echo system >"$state_dir/mode"
        if command -v darkman >/dev/null 2>&1; then
          cur="$(darkman get 2>/dev/null || true)"
          case "$cur" in
            light | dark) echo "$cur" >"$state_dir/polarity" ;;
          esac
        fi
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    apply
    ;;
  toggle)
    if [ "$(resolve_polarity)" = dark ]; then np=light; else np=dark; fi
    echo "$np" >"$state_dir/mode"
    apply
    ;;
  wallpaper)
    set_wallpaper "${2:-}"
    ;;
  apply)
    apply
    ;;
  darkman-hook) # internal: darkman light/dark scripts land here
    if [ "$(read_state mode dark)" = system ]; then
      case "${2:-}" in
        light | dark)
          echo "$2" >"$state_dir/polarity"
          apply
          ;;
      esac
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
