# Host: brzrkr (i7-11700K, RTX 3070)
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

    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
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
    wireguard.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      allowedUDPPorts = [ 51820 53 41641 ]; # WireGuard, DNS, tailscale direct conns
      trustedInterfaces = [ "tailscale0" ]; # trust traffic arriving over the tailnet
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
    font = "Lat2-Terminus16";
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
  };

  # ===========================================================================
  # DOCKER
  # ===========================================================================
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # ===========================================================================
  # SERVICES
  # ===========================================================================
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Tailscale VPN — daemon + CLI; authenticate once with `sudo tailscale up`
    tailscale.enable = true;

    printing.enable = true;

    # Firmware updates from LVFS (run `fwupdmgr update` occasionally)
    fwupd.enable = true;

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
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
