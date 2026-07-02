#!/usr/bin/env bash
# Power menu via walker dmenu. Bound to SUPER+Backspace in hyprland.lua.
set -euo pipefail

choice=$(printf '  Lock\n󰍃  Logout\n󰤄  Suspend\n󰜉  Reboot\n󰐥  Shutdown\n' \
  | walker --dmenu --placeholder "power" --maxheight 300) || exit 0

case "$choice" in
  *Lock)     hyprlock ;;
  *Logout)   loginctl terminate-session "${XDG_SESSION_ID:-}" ;;
  *Suspend)  systemctl suspend ;;
  *Reboot)   systemctl reboot ;;
  *Shutdown) systemctl poweroff ;;
esac
