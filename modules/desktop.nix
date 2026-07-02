# Desktop: Hyprland + greetd/tuigreet, audio, bluetooth, fonts, packages
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==========================================================================
  # HYPRLAND (nixpkgs 0.55.x, native Lua config)
  # ==========================================================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ==========================================================================
  # LOGIN (greetd + tuigreet)
  # ==========================================================================
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session "
      + "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  };

  # ==========================================================================
  # XDG PORTALS (hyprland portal added by programs.hyprland)
  # ==========================================================================
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # ==========================================================================
  # AUDIO (PipeWire)
  # ==========================================================================
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # ==========================================================================
  # BLUETOOTH
  # ==========================================================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ==========================================================================
  # SECURITY (polkit; the user agent runs via home-manager)
  # ==========================================================================
  security.polkit.enable = true;

  # ==========================================================================
  # FONTS
  # ==========================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      monaspace
      nerd-fonts.monaspace
      nerd-fonts.jetbrains-mono
      font-awesome
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "JetBrainsMono Nerd Font" ];
      serif = [ "JetBrainsMono Nerd Font" ];
    };
  };

  # ==========================================================================
  # WAYLAND SESSION VARIABLES
  # ==========================================================================
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_SCALE_FACTOR = "0.9"; # Smaller menus and UI elements
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # ==========================================================================
  # DESKTOP PACKAGES
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    # Shell / launcher / notifications
    quickshell
    wofi
    dunst
    libnotify

    # Wallpaper, lock, idle
    awww
    hyprlock
    hypridle

    # Screenshots
    grim
    slurp
    swappy

    # Clipboard
    wl-clipboard
    cliphist

    # Polkit agent binary (service defined in home-manager)
    polkit_gnome

    # Files / media
    thunar
    thunar-archive-plugin
    thunar-volman
    imv
    mpv

    # Controls
    brightnessctl
    pavucontrol
    playerctl
    networkmanagerapplet

    # Theming
    phinger-cursors
    adwaita-icon-theme

    # Apps
    firefox
    obsidian
    custom.linear
    ghostty
    zed-editor

    # ========================================================================
    # CLI / DEVELOPMENT PACKAGES
    # ========================================================================
    # Core utilities
    vim
    wget
    curl
    git
    git-lfs
    unzip
    zip
    file
    tree
    htop
    btop
    killall

    # Modern CLI replacements
    eza # ls
    bat # cat
    ripgrep # grep
    fd # find
    fzf # fuzzy finder
    zoxide # cd
    jq # JSON
    yq # YAML
    ncdu # disk usage
    duf # df

    # Languages & build tools
    go
    rustup
    python3
    nodejs_22
    gcc
    gnumake
    cmake
    pkg-config

    # DevOps / cloud
    docker-compose
    kubectl
    kubernetes-helm
    k9s
    terraform
    ansible
    awscli2
    azure-cli
    google-cloud-sdk

    # Code quality & LSPs
    shellcheck
    nil
    rust-analyzer
    gopls
    pyright
    terraform-ls
    yaml-language-server
    lua-language-server
    typescript-language-server
    bash-language-server

    # Networking
    httpie
    doggo
    speedtest-cli
    openvpn
    protonvpn-gui

    # System tools
    pciutils
    usbutils
    lshw
    smartmontools
    nvme-cli
    fastfetch

    # AI coding
    claude-code

    # Archives
    p7zip
    unrar
  ];
}
