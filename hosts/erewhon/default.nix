# Host: erewhon (i7-11700K, RTX 3070)
# Host-level config only - desktop/gpu/gaming live in modules/.
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ===========================================================================
  # BOOT
  # ===========================================================================
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      # Skip the menu entirely; HOLD SPACE during boot to bring it up
      # (that's how you reach older generations for rollback)
      timeout = 0;
    };

    # Silent boot: splash covers the console; only critical kernel messages
    # may print (everything still reaches the journal)
    plymouth.enable = true;
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=2"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=2"
      "udev.log_priority=2"
      "boot.shell_on_fail"
    ];

    kernelModules = [ "rtl8xxxu" ]; # RTL8188GU wifi dongle

    # Quiet stage-1 boot (independent of the dropped Plymouth)
    consoleLogLevel = 0;
    initrd.verbose = false;

    # systemd-based stage 1: parallel initrd, cleaner LUKS passphrase prompt
    initrd.systemd.enable = true;

    # TPM auto-unlock: tries the TPM2 keyslot first, falls back to the
    # passphrase prompt if none is enrolled or the TPM balks. Enroll with:
    #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/nvme0n1p2
    initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];

    supportedFilesystems = [ "ext4" "btrfs" "ntfs" ];
    tmp.cleanOnBoot = true;
  };

  # This desktop has zram and 32 GiB RAM; systemd-oomd's cgroup IO-pressure
  # hooks are unsupported by this kernel setup and log threshold errors during
  # every login. Keep kernel OOM handling and remove the broken extra daemon.
  systemd.oomd.enable = false;

  # ===========================================================================
  # MEMORY (no disk swap partition exists — compressed RAM swap instead)
  # ===========================================================================
  # Boot speed: this desktop doesn't need to block on "network fully online"
  # (it alone cost 10.6s of every boot; docker etc. come up fine without it)
  systemd.services.NetworkManager-wait-online.enable = false;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    # This machine has Wi-Fi/Ethernet, not a cellular modem. Keep
    # ModemManager out of the boot/session service graph.
    modemmanager.enable = false;
    wireguard.enable = true;
    firewall = {
      enable = true;
      # SSH is tailnet-only: tailscale0 is trusted below, while the physical
      # interface exposes no SSH, DNS, or unused WireGuard port.
      allowedUDPPorts = [ 41641 ]; # Tailscale direct connections
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # ===========================================================================
  # TIME & LOCALE
  # ===========================================================================
  time.timeZone = "America/Chicago";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  console = {
    # No virtual-console font is needed on this graphical-only host.
    # Keeping useXkbConfig preserves the keyboard layout for TTY fallback.
    useXkbConfig = true;
  };

  # ===========================================================================
  # USER
  # ===========================================================================
  users.users.${username} = {
    isNormalUser = true;
    description = "Parker Anderson";
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.zsh;
  };

  # ===========================================================================
  # PROGRAMS
  # ===========================================================================
  programs = {
    zsh.enable = true;
    git.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    # Run non-nix binaries (terraform providers, vendor CLIs, go/cargo installs
    # that link libc) without patchelf — nix-ld provides the missing dynamic
    # loader at the standard FHS path
    nix-ld.enable = true;

    # Nicer rebuild UX: `nh os switch` = nixos-rebuild with clean build output
    # (nix-output-monitor) + a package-level diff of what changed (nvd), both
    # bundled with nh. The nrs/nrb/nrt aliases point here (home/default.nix).
    # Garbage collection stays with nix.gc below — nh clean would duplicate it.
    nh = {
      enable = true;
      flake = "/home/${username}/nixos";
    };
  };

  # ===========================================================================
  # DOCKER
  # ===========================================================================
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    # Don't start dockerd at boot; the socket starts it on first `docker` use
    enableOnBoot = false;
  };

  # ===========================================================================
  # TRUST
  # ===========================================================================
  # FireMon Global Root CA (OU=Infrastructure): signs Vault PKI and every
  # internal *.firemon.net cluster certificate.
  # SHA-256 FF:29:B5:95:F2:C0:1E:7C:0C:BD:C1:56:7B:8B:AE:B1:10:F5:06:3D:CD:89:79:D4:85:C2:71:88:8A:7D:B0:9F
  security.pki.certificateFiles = [ ./firemon-global-root-ca.pem ];
  # Firefox on Linux ignores the system store; install the root via policy.
  programs.firefox.policies.Certificates.Install = [ "${./firemon-global-root-ca.pem}" ];

  # ===========================================================================
  # SERVICES
  # ===========================================================================
  services = {
    openssh = {
      enable = true;
      openFirewall = false; # tailscale0 is already trusted above
      settings = {
        PasswordAuthentication = false;
        # PasswordAuthentication does not disable PAM challenge/response.
        # Keep this false so SSH is genuinely key-only.
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Tailscale VPN — daemon + CLI; authenticate once with `sudo tailscale up`
    tailscale.enable = true;

    # Firmware updates from LVFS (run `fwupdmgr update` occasionally)
    fwupd.enable = true;

    # Monthly online checksum verification for the Btrfs root filesystem.
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };

    # Bound persistent logs without sacrificing a month of diagnostics.
    journald.settings.Journal = {
      SystemMaxUse = "512M";
      MaxRetentionSec = "1month";
    };

    # Mode-switch the RTL8188GU dongle from storage to wifi
    udev.extraRules = ''
      ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -K -v 0bda -p 1a2b"
    '';
  };

  environment.systemPackages = with pkgs; [
    usb-modeswitch
  ];

  # ===========================================================================
  # NIX
  # ===========================================================================
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Keep rebuilds fast; deduplicate the store in a weekly maintenance job
      # instead of making every build hash/compare the entire store.
      auto-optimise-store = false;
      # nix-community publishes cached builds for Hyprland-adjacent packages
      # that cache.nixos.org does not always carry.
      substituters = lib.mkForce [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = lib.mkForce [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
