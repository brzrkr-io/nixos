# Home Manager Configuration
# User environment, shell, and dotfile symlinks
{ config, pkgs, lib, inputs, username, ... }:

let
  dotfiles = "/home/${username}/nixos/config";

  # Runtime theme switcher. The PATH commands are thin wrappers that exec the
  # scripts out of the repo (same philosophy as the out-of-store config
  # symlinks): editing config/themes/*.sh applies immediately, no rebuild.
  # Nix only pins the dependencies onto PATH.
  themeCli = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnugrep
      gnused
      procps
      awww
      glib # gsettings + gdbus (ghostty reload)
      libnotify
      dunst # dunstctl
      neovim
      tmux
    ];
    text = ''exec bash "${dotfiles}/themes/theme.sh" "$@"'';
  };

  themePicker = pkgs.writeShellApplication {
    name = "theme-picker";
    runtimeInputs = [ themeCli ];
    text = ''exec bash "${dotfiles}/themes/theme-picker.sh" "$@"'';
  };

  # Night light: darkman hooks run outside the compositor's env, so recover the
  # Hyprland instance signature (same trick as theme.sh) before talking to the
  # hyprsunset daemon (autostarted by hyprland.lua).
  nightlight = cmd: pkgs.writeShellScript "nightlight-${lib.replaceStrings [" "] ["-"] cmd}" ''
    runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$runtime/hypr" ]; then
      HYPRLAND_INSTANCE_SIGNATURE="$(ls "$runtime/hypr" | head -n1)"
      export HYPRLAND_INSTANCE_SIGNATURE
    fi
    ${pkgs.hyprland}/bin/hyprctl hyprsunset ${cmd} || true
  '';
in
{
  imports = [
    ./spotify.nix
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";

    # ==========================================================================
    # USER PACKAGES
    # ==========================================================================
    packages = with pkgs; [
      # Editors: plain packages, NOT programs.neovim/helix HM modules — those
      # generate configs that collide with our out-of-store symlinks.
      # helix is on trial as a possible nvim replacement (zero-plugin IDE).
      neovim
      helix

      # Git tools
      lazygit
      delta

      # Database tools
      pgcli

      # Formatters
      stylua
      shfmt
      nixpkgs-fmt
      prettier
      fastfetch
      # Launcher (walker UI; elephant backend runs as a user service below)
      walker

      # Gaming tools
      prismlauncher
      protonup-qt
    ] ++ [
      # Theme switching (SUPER+CTRL+T picker; see config/themes/)
      themeCli
      themePicker
    ];

    # ==========================================================================
    # SESSION VARIABLES
    # ==========================================================================
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
      TERMINAL = "ghostty";
    };

    # ==========================================================================
    # DOTFILE SYMLINKS (out-of-store, editable in place)
    # ==========================================================================
    file = {
      ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
      ".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/quickshell";
      ".config/walker".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/walker";
      ".config/dunst".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/dunst";
      ".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
      ".config/helix".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/helix";
      ".config/zed".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zed";

      # Hyprland plugins at a stable path so hyprland.lua can load them without
      # hardcoding store hashes (NOT under .config/hypr — that's a repo symlink
      # home-manager can't write into)
      ".local/share/hypr-plugins/dynamic-cursors.so".source =
        "${pkgs.hyprlandPlugins.hypr-dynamic-cursors}/lib/libhypr-dynamic-cursors.so";
      # Workspace overview, Mission Control style (SUPER+` — bind in hyprland.lua)
      ".local/share/hypr-plugins/hyprspace.so".source =
        "${pkgs.hyprlandPlugins.hyprspace}/lib/libhyprspace.so";
      ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship/starship.toml";
      ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/tmux/tmux.conf";

      # btop: NOT a repo symlink on purpose — btop rewrites its config on every
      # exit, which would constantly dirty the repo. Read-only store file; the
      # theme follows the same current-theme symlink as everything else
      # (config/themes/*/btop.theme), picked up on next btop launch.
      ".config/btop/btop.conf".text = ''
        color_theme = "/home/${username}/.config/theme/current/btop.theme"
        theme_background = False
        vim_keys = True
      '';
    };
  };

  # ============================================================================
  # CURSOR, GTK & QT
  # ============================================================================
  # Cursor, GTK theme, and fonts are owned by stylix (modules/theme.nix).
  # The GTK portal reads GSettings/dconf, not settings.ini — keep the cursor
  # synced there so GTK apps never fall back to Adwaita (mkDefault: stylix
  # wins if it also writes these keys).
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = lib.mkDefault config.home.pointerCursor.name;
    cursor-size = lib.mkDefault config.home.pointerCursor.size;
  };

  # ============================================================================
  # USER SERVICES
  # ============================================================================
  # Session target bridge: Hyprland is launched bare by greetd (no UWSM, no HM
  # hyprland module), so nothing would otherwise activate graphical-session.target.
  # hyprland.lua starts this target on compositor startup.
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  # Wallpaper (awww daemon + image; awww is swww's successor in nixpkgs)
  systemd.user.services.wallpaper = {
    Unit = {
      Description = "Wallpaper service";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # Daemon in the foreground so systemd tracks it; image set once it responds
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      ExecStartPost = "${pkgs.writeShellScript "set-wallpaper" ''
        for _ in $(seq 1 50); do
          ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && break
          sleep 0.2
        done
        ${themeCli}/bin/theme wallpaper
      ''}";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Walker's data backend (apps, calc, files providers)
  services.elephant.enable = true;

  # Sunrise/sunset dark-mode daemon — drives `theme mode system` and the
  # hyprsunset night light. Static coordinates (no geoclue); TODO: set these
  # to your rough location.
  services.darkman = {
    enable = true;
    settings = {
      lat = 39.74;
      lng = -104.99;
      usegeoclue = false;
    };
    darkModeScripts.theme = "${themeCli}/bin/theme darkman-hook dark";
    lightModeScripts.theme = "${themeCli}/bin/theme darkman-hook light";
    # Night light rides the same sunset trigger: warm after dark, neutral by day
    darkModeScripts.nightlight = "${nightlight "temperature 4200"}";
    lightModeScripts.nightlight = "${nightlight "identity"}";
  };

  # Seed theme state + current-theme symlink so first login after a fresh
  # install isn't colorless (the `theme` CLI maintains these afterwards)
  home.activation.themeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    themeState="$HOME/.local/state/theme"
    mkdir -p "$themeState" "$HOME/.config/theme"
    [ -f "$themeState/theme" ] || echo tokyonight > "$themeState/theme"
    [ -f "$themeState/mode" ] || echo dark > "$themeState/mode"
    [ -f "$themeState/polarity" ] || echo dark > "$themeState/polarity"
    [ -e "$HOME/.config/theme/current" ] || ln -sfnT "${dotfiles}/themes/tokyonight/dark" "$HOME/.config/theme/current"
  '';

  # Volume/brightness on-screen display (media keys call swayosd-client)
  services.swayosd.enable = true;

  # Polkit authentication agent (GTK)
  systemd.user.services.polkit-gnome-agent = {
    Unit = {
      Description = "polkit-gnome authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ============================================================================
  # PROGRAMS
  # ============================================================================
  programs.home-manager.enable = true;

  # ----------------------------------------------------------------------------
  # GIT
  # ----------------------------------------------------------------------------
  programs.git = {
    enable = true;
    settings = {
      user.name = "Parker Anderson";
      user.email = "park.anderson96@gmail.com";
      core.editor = "nvim";
      pull.rebase = true;
      push.default = "simple";
      init.defaultBranch = "main";
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
      };
    };
  };

  # Delta (git pager)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "base16";
    };
  };

  # ----------------------------------------------------------------------------
  # ZSH
  # ----------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # Modern CLI replacements
      ll = "eza -la --icons --group-directories-first --git";
      lt = "eza --tree --icons --group-directories-first";
      cat = "bat --style=auto";
      vi = "nvim";
      vim = "nvim";
      grep = "rg";
      find = "fd";
      top = "btop";

      # Git
      g = "git";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate";

      # Docker
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";

      # Kubernetes
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get svc";

      # Terraform
      tf = "terraform";
      tfi = "terraform init";
      tfp = "terraform plan";
      tfa = "terraform apply";

      # NixOS (nh wraps nixos-rebuild: nom build output + nvd generation diff;
      # flake path comes from programs.nh.flake. Fallback if nh ever breaks:
      # sudo nixos-rebuild switch --flake ~/nixos#brzrkr)
      nrs = "nh os switch";
      nrb = "nh os boot";
      nrt = "nh os test";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Misc
      reload = "source ~/.zshrc";
      myip = "curl -s https://ipinfo.io/ip";
    };

    initContent = ''
      # Initialize tools
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
      eval "$(direnv hook zsh)"

      # History settings
      export HISTSIZE=50000
      export SAVEHIST=50000
      export HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY

      # Local bin
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    '';
  };

  # ----------------------------------------------------------------------------
  # SHELL TOOLING
  # ----------------------------------------------------------------------------
  programs.starship.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 60%"
      "--layout=reverse"
      "--border"
      "--preview 'bat --color=always --style=header,grid --line-range :300 {}'"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Ctrl+R only (up-arrow keeps plain zsh history — less muscle-memory churn).
  # Local database only; `atuin import auto` once to pull in existing history.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ----------------------------------------------------------------------------
  # EDITORS & MULTIPLEXER
  # ----------------------------------------------------------------------------

  programs.tmux.enable = true;
}
