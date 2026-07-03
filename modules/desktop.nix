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
  # Never restart the login manager on nixos-rebuild switch — that kills the
  # live Hyprland session mid-use (learned the hard way)
  systemd.services.greetd.restartIfChanged = false;

  services.greetd = {
    enable = true;
    # Fixed command instead of a session picker: the picker exposed a broken
    # "Hyprland (UWSM)" entry (ships with the hyprland package, needs uwsm we
    # don't install) and tuigreet's session memory kept re-selecting it.
    # No autologin: Parker wants the password prompt.
    # start-hyprland (not bare Hyprland): the 0.55+ launcher that prepares the
    # session env — bare launch triggers the "started without start-hyprland"
    # warning notification on every login
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
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

  # Required for dconf-based settings (GTK theme, cursor via GSettings) to apply
  programs.dconf.enable = true;

  # USB automount + trash/MTP/network shares in Thunar (thunar-volman needs these)
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # ==========================================================================
  # FONTS
  # ==========================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      maple-mono.NF
      nerd-fonts.jetbrains-mono # fallback
      font-awesome
    ];
    fontconfig.defaultFonts = {
      monospace = [ "Maple Mono NF" "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Maple Mono NF" "JetBrainsMono Nerd Font" ];
      serif = [ "Maple Mono NF" "JetBrainsMono Nerd Font" ];
    };
  };

  # ==========================================================================
  # WAYLAND SESSION VARIABLES
  # ==========================================================================
  # XDG_SESSION_* / XDG_CURRENT_DESKTOP come from the compositor and session
  # file — forcing them globally leaks into TTY/SSH sessions.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  # ==========================================================================
  # DESKTOP PACKAGES
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    # Shell / launcher / notifications (quickshell IS the notification daemon
    # and volume OSD — shell.qml; libnotify stays for notify-send)
    quickshell
    libnotify

    # Wallpaper, lock, idle, night light
    awww
    hyprlock
    hypridle
    hyprsunset

    # Screenshots (+ tesseract for the SUPER+SHIFT+T screen-OCR bind)
    grim
    slurp
    swappy
    tesseract

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
    # mpris script: without it mpv is invisible to playerctl (media keys) and
    # the bar's MPRIS pill
    (mpv.override { scripts = [ mpvScripts.mpris ]; })

    # Controls
    brightnessctl
    pavucontrol
    playerctl
    networkmanagerapplet

    # Theming
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
    tealdeer # tldr — community cheatsheets for CLI tools

    # Languages & build tools
    go
    rustup
    python3
    nodejs_22
    gcc
    tree-sitter # nvim-treesitter grammar builds
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
    proton-vpn

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
