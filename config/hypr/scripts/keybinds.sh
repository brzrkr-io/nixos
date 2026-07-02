#!/usr/bin/env bash
# Keybind cheatsheet: reads live binds (+ descs) from Hyprland and shows
# them in wofi. Bound to SUPER+SHIFT+/ in hyprland.lua.
set -euo pipefail

hyprctl binds -j | jq -r '
  def mods:
    [ (if (.modmask % 128 >= 64) then "SUPER" else empty end),
      (if (.modmask % 8  >= 4)  then "CTRL"  else empty end),
      (if (.modmask % 16 >= 8)  then "ALT"   else empty end),
      (if (.modmask % 2  >= 1)  then "SHIFT" else empty end) ] | join("+");
  .[]
  | select(.description != "")
  | "\(mods + (if mods == "" then "" else "+" end) + .key)\t\(.description)"
' | sort -u | column -t -s $'\t' | walker --dmenu --placeholder keybinds >/dev/null || true
