# Gaming: Steam, GameMode, launchers and Proton tooling
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==========================================================================
  # STEAM + GAMEMODE
  # ==========================================================================
  programs.steam.enable = true;
  programs.gamemode.enable = true;

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
    mangohud
  ];

  # ==========================================================================
  # ENVIRONMENT
  # ==========================================================================
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    MANGOHUD = "1";
  };
}
