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
      noctalia-shell # Noctalia v5 CLI (`noctalia msg`) for wallpaper + theme IPC
      glib # gsettings + gdbus (ghostty reload)
      libnotify
      neovim
      tmux
    ];
    text = ''exec bash "${dotfiles}/themes/theme.sh" "$@"'';
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
    # darkman and Hyprland start together; wait for hyprsunset's socket instead
    # of emitting a transient startup error when darkman wins the race.
    attempt=0
    while [ "$attempt" -lt 25 ]; do
      if ${pkgs.hyprland}/bin/hyprctl hyprsunset ${cmd} >/dev/null 2>&1; then
        exit 0
      fi
      attempt=$((attempt + 1))
      sleep 0.2
    done
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
      # tmux: same rule — programs.tmux generates ~/.config/tmux/tmux.conf,
      # which tmux loads AFTER ~/.tmux.conf, silently overriding it
      # (mouse off, emacs keys, history 2000...)
      tmux

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

      # Gaming tools
      prismlauncher
      protonup-qt
    ] ++ [
      # Theme switching (see config/themes/; wallpaper picker is noctalia's)
      themeCli
    ];

    # ==========================================================================
    # SESSION VARIABLES
    # ==========================================================================
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
      TERMINAL = "ghostty";
      # man pages through bat: syntax highlighting + theme
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c"; # stop man-db emitting SGR escapes that garble bat
    };

    # ==========================================================================
    # DOTFILE SYMLINKS (out-of-store, editable in place)
    # ==========================================================================
    file = {
      ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
      ".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
      ".config/helix".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/helix";
      ".config/zed".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zed";

      ".config/noctalia/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/noctalia/config.toml";
      ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship/starship.toml";
      ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/tmux/tmux.conf";

      # Nix delivers tmux plugins at stable paths; config/tmux/tmux.conf
      # loads them directly, with no TPM or store hashes in the live config.
      ".local/share/tmux-plugins/sensible".source =
        "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
      ".local/share/tmux-plugins/resurrect".source =
        "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
      ".local/share/tmux-plugins/continuum".source =
        "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";
      ".local/share/tmux-plugins/yank".source =
        "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";

      # btop: NOT a repo symlink on purpose — btop rewrites its config on every
      # exit, which would constantly dirty the repo. Read-only store file; the
      # theme follows the same current-theme symlink as everything else
      # (config/themes/*/btop.theme), picked up on next btop launch.
      # force: a pre-existing (or btop-rewritten) plain btop.conf otherwise
      # fails the whole HM activation with "would be clobbered" — in-app btop
      # tweaks reset on rebuild, that's the accepted trade.
      ".config/btop/btop.conf" = {
        force = true;
        text = ''
          color_theme = "/home/${username}/.config/theme/current/btop.theme"
          theme_background = False
          vim_keys = True
        '';
      };
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

  # Reproducible launch behavior from Noctalia, Thunar, and downloaded files.
  # Force replaces the small pre-Nix mimeapps.list; all of its handlers are
  # preserved below.
  xdg = {
    configFile."mimeapps.list".force = true;
    mimeApps = {
      enable = true;
      associations.added = {
        "text/csv" = [ "dev.zed.Zed.desktop" ];
        "text/markdown" = [ "dev.zed.Zed.desktop" ];
        "text/plain" = [ "dev.zed.Zed.desktop" ];
      };
      defaultApplications = {
        "application/pdf" = [ "firefox.desktop" ];
        "image/jpeg" = [ "imv-dir.desktop" ];
        "image/png" = [ "imv-dir.desktop" ];
        "image/webp" = [ "imv-dir.desktop" ];
        "inode/directory" = [ "thunar.desktop" ];
        "text/csv" = [ "dev.zed.Zed.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/markdown" = [ "dev.zed.Zed.desktop" ];
        "text/plain" = [ "dev.zed.Zed.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
        "x-scheme-handler/discord-409416265891971072" = [ "discord-409416265891971072.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
    };
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
      Wants = [
        "graphical-session-pre.target"
        "app-com.mitchellh.ghostty.service"
      ];
      After = [ "graphical-session-pre.target" ];
    };
  };

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
    [ -f "$themeState/theme" ] || echo gruvbox > "$themeState/theme"
    [ -f "$themeState/mode" ] || echo dark > "$themeState/mode"
    [ -f "$themeState/polarity" ] || echo dark > "$themeState/polarity"
    [ -e "$HOME/.config/theme/current" ] || ln -sfnT "${dotfiles}/themes/gruvbox/dark" "$HOME/.config/theme/current"
  '';


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

  # GitHub CLI. Also makes git use it for github.com logins, so push/pull to
  # private repos (groundwork) just works over HTTPS after `gh auth login`.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "https";
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
      # sudo nixos-rebuild switch --flake ~/nixos#erewhon)
      nrs = "nh os switch";
      nrb = "nh os boot";
      nrt = "nh os test";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Misc
      ff = "fastfetch";
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
    # Atuin owns Ctrl-R; fzf remains available for explicit fuzzy searches.
    historyWidget.command = "";
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

  # Atuin owns Ctrl-R and Up-arrow for searchable command history.
  # Import existing shell history once with `atuin import auto`.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
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

}
