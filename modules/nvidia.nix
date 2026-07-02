# NVIDIA RTX 3070 (proprietary driver, Wayland)
{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==========================================================================
  # KERNEL
  # ==========================================================================
  boot = {
    kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
    ];
    blacklistedKernelModules = [ "nouveau" ];
    # NVIDIA deliberately NOT in initrd: early KMS only mattered for Plymouth
    # (removed), and it bloats every initrd by ~200MB on a 512MB ESP.
  };

  # ==========================================================================
  # DRIVER
  # ==========================================================================
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    # Open kernel module: NVIDIA's recommended default for Turing+ since v560
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ==========================================================================
  # ENVIRONMENT
  # ==========================================================================
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # ==========================================================================
  # PACKAGES
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring
    nvidia-vaapi-driver # Hardware video acceleration
    libva-utils # VA-API diagnostics
    gpu-screen-recorder
  ];
}
