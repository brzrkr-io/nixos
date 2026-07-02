# Home Manager Configuration
# User environment, shell, and dotfile symlinks
{ config, pkgs, lib, inputs, username, ... }:

let
  dotfiles = "/home/${username}/nixos/config";
in
{
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";

    # ==========================================================================
    # USER PACKAGES
    # ==========================================================================
    packages = with pkgs; [
      # Git tools
      lazygit
      delta

      # Database tools
      pgcli

      # Formatters
      stylua
      shfmt
      nixpkgs-fmt
      nodePackages.prettier

      # Gaming tools
      prismlauncher
      protonup-qt
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
      ".config/wofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wofi";
      ".config/dunst".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/dunst";
      ".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
      ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship/starship.toml";
      ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/tmux/tmux.conf";
    };
  };

  # ============================================================================
  # CURSOR, GTK & QT
  # ============================================================================
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 9;
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    font="JetBrainsMono Nerd Font,9,-1,5,50,0,0,0,0,0"
  '';

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    font="JetBrainsMono Nerd Font,9,-1,5,50,0,0,0,0,0"
  '';

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

  # Wallpaper (swww daemon + image)
  systemd.user.services.wallpaper = {
    Unit = {
      Description = "Wallpaper service";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.writeShellScript "wallpaper-service" ''
        # Kill any existing swww processes
        ${pkgs.procps}/bin/pkill -f swww-daemon 2>/dev/null || true

        # Start daemon and set wallpaper
        ${pkgs.swww}/bin/swww-daemon &
        sleep 1
        ${pkgs.swww}/bin/swww img ${dotfiles}/wallpapers/linux_retro.png --transition-type fade

        # Keep service running by monitoring the daemon
        wait
      ''}";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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

      # NixOS
      nrs = "sudo nixos-rebuild switch --flake ~/nixos#brzrkr";
      nrb = "sudo nixos-rebuild boot --flake ~/nixos#brzrkr";
      nrt = "sudo nixos-rebuild test --flake ~/nixos#brzrkr";

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
      export PATH="$HOME/.local/bin:$PATH"
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

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ----------------------------------------------------------------------------
  # EDITORS & MULTIPLEXER
  # ----------------------------------------------------------------------------
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.tmux.enable = true;
}
