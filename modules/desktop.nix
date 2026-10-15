# Desktop: Hyprland + Noctalia Greeter, audio, bluetooth, fonts, packages
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==========================================================================
  # HYPRLAND (native Lua config)
  # ==========================================================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ==========================================================================
  # LOGIN (Noctalia Greeter)
  # ==========================================================================
  # Noctalia Greeter owns the greetd login surface; the shell's in-session
  # lockscreen remains wired through `noctalia msg session lock`.
  # Never restart greetd on nixos-rebuild switch — that kills the live session.
  systemd.services.greetd = {
    restartIfChanged = false;
    # The NixOS module creates greeter.toml as a store symlink. Noctalia
    # migrates runtime preferences into that file, so materialize a writable
    # copy immediately before the greeter starts.
    preStart = lib.mkAfter ''
      cfg=/var/lib/noctalia-greeter/greeter.toml
      wallpaper=/home/pjanderson/Downloads/wallhaven-k81oj1_3840x2160.png
      wallpaper_target=/var/lib/noctalia-greeter/wallpaper.png
      if [ -L "$cfg" ]; then
        tmp="$cfg.tmp"
        cp --dereference "$cfg" "$tmp"
        chown greeter:greeter "$tmp"
        chmod 0644 "$tmp"
        mv -f "$tmp" "$cfg"
      fi
      if [ -r "$wallpaper" ]; then
        cp --reflink=auto "$wallpaper" "$wallpaper_target"
        chown greeter:greeter "$wallpaper_target"
        chmod 0644 "$wallpaper_target"
      fi
    '';
  };

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "Hyprland";
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
      };
      keyboard.layout = "us";
      appearance = {
        scheme = "Synced";
        theme_mode = "dark";
        hide_logo = true;
        power_buttons_position = "bottom-right";
        scheme_selector_position = "top-right";
        font_family = "IosevkaTerm Nerd Font Mono";
        corner_radius_scale = 1.1;
        wallpaper = {
          path = "/var/lib/noctalia-greeter/wallpaper.png";
          fill_mode = "crop";
          fill_color = "#191724";
        };
        palette = {
          primary = "#c4a7e7";
          on_primary = "#191724";
          secondary = "#9ccfd8";
          on_secondary = "#191724";
          tertiary = "#ebbcba";
          on_tertiary = "#191724";
          error = "#eb6f92";
          on_error = "#191724";
          surface = "#191724";
          on_surface = "#e0def4";
          surface_variant = "#1f1d2e";
          on_surface_variant = "#908caa";
          outline = "#403d52";
          shadow = "#191724";
          hover = "#ebbcba";
          on_hover = "#191724";
        };
      };
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
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
    # Experimental exposes Device1.PreferredBearer. AirPods are dual-mode and
    # get bonded over both BR/EDR and LE; reconnecting over LE yields
    # "Connected" with no A2DP audio. Pin them with:
    #   busctl --system set-property org.bluez /org/bluez/hci0/dev_<MAC> \
    #     org.bluez.Device1 PreferredBearer s bredr
    # (persisted by bluetoothd). ControllerMode stays "dual": the NuPhy
    # keyboard is LE-only.
    settings.General.Experimental = true;
  };

  # Logitech HID++ support: udev permissions plus the Solaar tray/service for
  # receiver, DPI, button, battery, and haptic settings.
  programs.solaar = {
    enable = true;
    userService.enable = true;
  };

  # ==========================================================================
  # SECURITY (polkit; the user agent runs via home-manager)
  # ==========================================================================
  security.polkit.enable = true;

  # Secret Service (org.freedesktop.secrets): Electron/Chromium apps store
  # OAuth/SSO tokens here — without it, desktop-app sign-ins (Okta et al)
  # succeed in the browser but the app loops back to the login screen.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  # PAM starts and unlocks the keyring once. Hide the package's XDG
  # autostarts, which otherwise launch a second secrets daemon after login.
  environment.etc."xdg/autostart/gnome-keyring-pkcs11.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Hidden=true
  '';
  environment.etc."xdg/autostart/gnome-keyring-secrets.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Hidden=true
  '';

  # Required for dconf-based settings (GTK theme, cursor via GSettings) to apply
  programs.dconf.enable = true;

  # Restore browser windows and tabs after login/reboot. This is an unlocked
  # enterprise policy: Firefox still exposes its normal startup controls.
  programs.firefox = {
    enable = true;
    policies.Homepage = {
      StartPage = "previous-session";
      NewTabOnRestore = false;
    };
  };

  # Module rather than a bare package: it wires the Hyprland portal and
  # PipeWire into Zoom's FHS sandbox, which screen sharing needs on Wayland.
  programs.zoom-us.enable = true;

  # USB automount + trash/MTP/network shares in Thunar (thunar-volman needs these)
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # ==========================================================================
  # FONTS
  # ==========================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka-term
      nerd-fonts.jetbrains-mono # fallback
    ];
    fontconfig.defaultFonts = {
      monospace = [ "IosevkaTerm Nerd Font Mono" "JetBrainsMono Nerd Font" ];
      sansSerif = [ "IosevkaTerm Nerd Font Mono" "JetBrainsMono Nerd Font" ];
      serif = [ "IosevkaTerm Nerd Font Mono" "JetBrainsMono Nerd Font" ];
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
    # Noctalia owns the bar, notifications, OSD, launcher, clipboard,
    # wallpaper, and lock screen. Its upstream package includes its shell
    # runtime, so no separate shell packages are needed.
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    libnotify

    # Idle + night light (wallpaper/lock are noctalia's now)
    hypridle
    hyprsunset

    # Screenshots (+ tesseract for the Cmd+Option+O screen-OCR bind)
    grim
    slurp
    swappy
    tesseract

    # Clipboard and screen OCR
    wl-clipboard

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

    # Theming
    adwaita-icon-theme
    glib # gsettings used by the runtime theme switcher

    # Apps
    obsidian
    ghostty
    zed-editor
    jetbrains.goland
    vscode
    slack

    # ========================================================================
    # CLI / DEVELOPMENT PACKAGES
    # ========================================================================
    # Core utilities
    wget
    curl
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
    jq # JSON
    yq # YAML
    nmap
    ncdu # disk usage
    duf # df
    tealdeer # tldr — community cheatsheets for CLI tools

    # Languages & build tools
    go_1_27 # latest stable Go release in the current nixpkgs lock
    rustup
    python3
    nodejs # latest Node.js package in the current nixpkgs lock
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
    vault
    ansible
    awscli2

    # Code quality & LSPs
    shellcheck
    nil
    gopls
    go-tools # staticcheck and related Go analysis tools
    govulncheck # official Go dependency vulnerability scanner
    delve # Go debugger, used by nvim-dap-go
    pyright
    terraform-ls
    yaml-language-server
    lua-language-server
    # nixos-unstable 7fd4004 predates upstream's corrected pnpm dependency hash.
    # Remove after https://github.com/NixOS/nixpkgs/commit/ac7b1aaed03db4b794502641cdeed685ed777889 reaches the channel.
    (typescript-language-server.overrideAttrs (oldAttrs: {
      pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (_: {
        outputHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
      });
    }))
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
    codex # official OpenAI Codex CLI
    claude-code
    inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp

    # Archives
    p7zip
    unrar
  ];
}
