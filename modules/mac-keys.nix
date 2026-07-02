# Mac-style Cmd (SUPER) shortcuts inside GUI apps via xremap.
# Linux apps hardcode Ctrl as the accelerator; xremap translates SUPER+<key>
# to CTRL+<key> — but ONLY while one of the listed apps is focused, so SUPER
# stays the tiling key everywhere else. Terminals are deliberately excluded
# (Ctrl+C would kill the running command); ghostty has native super+c/v
# binds in its own config instead.
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  services.xremap = {
    enable = true;
    withHypr = true; # read the focused window from Hyprland's IPC
    serviceMode = "user";
    userName = username;

    config.keymap = [
      {
        name = "mac-cmd-in-apps";
        application.only = [ "firefox" "obsidian" "dev.zed.Zed" "spotify" ];
        remap = {
          # Editing
          "Super-c" = "C-c";
          "Super-v" = "C-v";
          "Super-x" = "C-x";
          "Super-z" = "C-z";
          "Super-Shift-z" = "C-Shift-z";
          "Super-a" = "C-a";
          # Browser/app navigation (mac-correct: Cmd+T tab, Cmd+W close tab,
          # Cmd+L url bar, Cmd+F find, Cmd+R reload — these intentionally
          # shadow the Hyprland binds while these apps are focused)
          "Super-t" = "C-t";
          "Super-Shift-t" = "C-Shift-t";
          "Super-w" = "C-w";
          "Super-l" = "C-l";
          "Super-f" = "C-f";
          "Super-r" = "C-r";
          "Super-n" = "C-n";
        };
      }
    ];
  };
}
