# Hardware Configuration
# =====================
# THIS FILE IS A PLACEHOLDER
#
# During NixOS installation, run:
#   nixos-generate-config --root /mnt
#
# Then copy the generated hardware-configuration.nix here:
#   cp /mnt/etc/nixos/hardware-configuration.nix ~/dotfiles/nixos/
#
# The generated file will contain:
# - Detected filesystems and mount points
# - Kernel modules for your hardware
# - CPU microcode updates
# - Boot device configuration

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Placeholder boot configuration
  # This will be auto-detected during installation
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystems are managed by disko.nix - do not define here

  swapDevices = [ ];

  # Intel CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Networking (placeholder - will be auto-detected)
  networking.useDHCP = lib.mkDefault true;
}
