# Mac-style Cmd (SUPER) shortcuts inside GUI apps via xremap.
# Linux apps hardcode Ctrl as the accelerator; xremap translates SUPER+<key>
# to CTRL+<key> in GUI apps except the compositor-owned bindings below.
# Terminals are deliberately excluded (Ctrl+C would kill the running command).
#
# Workspace and focus keys stay compositor-owned in every app: SUPER+digits
# switches workspaces and SUPER+arrows moves focus. Do not remap those keys
# here or the first switch would work only while a terminal is focused.
#
# Mac muscle memory remains the single shortcut convention: SUPER is Cmd.
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  services.xremap = {
    enable = true;
    withHypr = true; # read the focused window from Hyprland's IPC
    serviceMode = "user";
    userName = username;
    # Bluetooth keyboards disappear while sleeping; re-grab them on reconnect.
    watch = true;

    config.keymap = [
      {
        name = "mac-cmd-in-gui-apps";
        # Blacklist, not whitelist: covers firefox/obsidian/zed/spotify/linear/
        # thunar and anything installed later, without maintaining a list.
        application.not = [
          "com.mitchellh.ghostty"
          "ghostty"
          "keybinds.cheatsheet" # the SUPER+SHIFT+/ float is a ghostty too
          "steam"
          "/^steam_app_/" # games
          "/(?i)runelite/"
          "org.prismlauncher.PrismLauncher"
          "/(?i)minecraft/"
        ];
        remap = {
          # --- Editing ---
          "Super-c" = "C-c";
          "Super-v" = "C-v";
          "Super-x" = "C-x";
          "Super-z" = "C-z";
          "Super-Shift-z" = "C-Shift-z";
          "Super-Shift-s" = "C-Shift-s"; # save as
          "Super-Shift-v" = "C-Shift-v"; # paste without formatting
          "Super-a" = "C-a";

          # --- Commands ---
          "Super-s" = "C-s"; # save
          "Super-o" = "C-o"; # open
          "Super-p" = "C-p"; # print
          "Super-Shift-p" = "C-Shift-p"; # command palette (zed) / private window (firefox)
          "Super-comma" = "C-comma"; # preferences (apps that support it)
          "Super-f" = "C-f"; # find
          "Super-g" = "C-g"; # find next
          "Super-Shift-g" = "C-Shift-g"; # find previous

          # --- Windows / tabs ---
          "Super-t" = "C-t"; # new tab
          "Super-Shift-t" = "C-Shift-t"; # reopen closed tab
          "Super-w" = "C-w"; # close tab
          "Super-Shift-w" = "C-Shift-w"; # close window
          "Super-q" = "C-q"; # quit application
          "Super-n" = "C-n"; # new window
          "Super-Shift-n" = "C-Shift-n"; # new incognito/private window
          "Super-r" = "C-r"; # reload
          "Super-l" = "C-l"; # url bar
          # Workspace digits and arrows belong to Hyprland, not app tabs.
          # Cmd+Shift+[ ] = prev/next tab, Cmd+[ ] = history back/forward
          "Super-Shift-leftbrace" = "C-pageup";
          "Super-Shift-rightbrace" = "C-pagedown";
          "Super-leftbrace" = "M-left";
          "Super-rightbrace" = "M-right";

          # --- Zoom ---
          "Super-equal" = "C-equal";
          "Super-minus" = "C-minus";

          # Option+arrows: word jumps (+selection); Option+Backspace: delete word.
          # (Firefox loses Alt+Left history-back; use Cmd+[ instead — mac-correct.)
          "M-left" = "C-left";
          "M-right" = "C-right";
          "M-Shift-left" = "C-Shift-left";
          "M-Shift-right" = "C-Shift-right";
          "M-backspace" = "C-backspace";
        };
      }
    ];
  };
}
