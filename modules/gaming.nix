# Gaming: Steam, GameMode, launchers and Proton tooling
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==========================================================================
  # STEAM + GAMEMODE
  # ==========================================================================
  programs.steam.enable = true;
  programs.gamemode = {
    enable = true;
    # Hyprland has no screensaver; the inhibitor only spams DBus errors
    settings.general.inhibit_screensaver = 0;
  };

  # Without this group, gamemoded can't switch the CPU governor (stays on powersave)
  users.users.${username}.extraGroups = [ "gamemode" ];

  # ==========================================================================
  # PACKAGES
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    runelite
    lutris
    # wine dropped: Lutris manages its own runners, Steam uses Proton
    # (re-add wineWowPackages.stable once the nixpkgs pin is cached on Hydra)
    protontricks
    gamescope
    # Opt in per game with `MANGOHUD=1 %command%` in Steam. Setting MANGOHUD
    # globally injects the overlay into unrelated Vulkan apps such as Zoom.
    mangohud
  ];
  # ==========================================================================
  # ENVIRONMENT
  # ==========================================================================
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    # Stop the NVIDIA driver from garbage-collecting compiled Vulkan shader
    # pipelines between sessions (shader-stutter fix, esp. for CS2)
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
  };
}
