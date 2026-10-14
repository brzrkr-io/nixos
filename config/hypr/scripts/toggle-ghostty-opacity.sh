#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"
override="$state_dir/opacity.conf"
lock="$state_dir/opacity.lock"

mkdir -p "$state_dir"
exec 9>"$lock"
flock 9

if [[ -e "$override" ]]; then
    rm -- "$override"
else
    tmp="$(mktemp "$state_dir/.opacity.conf.XXXXXX")"
    trap 'rm -f -- "$tmp"' EXIT
    printf 'background-opacity = 1\n' >"$tmp"
    mv -- "$tmp" "$override"
    trap - EXIT
fi

busctl --user call \
    com.mitchellh.ghostty \
    /com/mitchellh/ghostty \
    org.gtk.Actions \
    Activate \
    'sava{sv}' \
    reload-config 0 0
