{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.gpu.nvidia;
in
{
  options.gpu.nvidia.enable = mkEnableOption ("Use Nvidia dGPU");
  options.gpu.nvidia.isTuring = mkOption {
    type = types.bool;
    default = false;
  };
  options.gpu.nvidia.useOpenDrivers = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      # The kernel module i915 for intel or amdgpu for AMD may interfere with the Nvidia driver.
      # This may result in a black screen when switching to the virtual terminal, or when exiting the X session.
      "module_blacklist=i915"
    ];
    environment.variables = {
      # Necessary to correctly enable va-api (video codec hardware
      # acceleration). If this isn't set, the libvdpau backend will be
      # picked, and that one doesn't work with most things, including
      # Firefox.
      LIBVA_DRIVER_NAME = "nvidia";
      # Required to run the correct GBM backend for nvidia GPUs on wayland
      GBM_BACKEND = "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Hardware cursors are currently broken on nvidia
      WLR_NO_HARDWARE_CURSORS = "1";

      # Required to use va-api it in Firefox. See
      # https://github.com/elFarto/nvidia-vaapi-driver/issues/96
      MOZ_DISABLE_RDD_SANDBOX = "1";
      # It appears that the normal rendering mode is broken on recent
      # nvidia drivers:
      # https://github.com/elFarto/nvidia-vaapi-driver/issues/213#issuecomment-1585584038
      NVD_BACKEND = "direct";
      # Required for firefox 98+, see:
      # https://github.com/elFarto/nvidia-vaapi-driver#firefox
      #EGL_PLATFORM = "wayland";
    };


    # hardware.opengl.extraPackages = with pkgs;  [
    #     nvidia-vaapi-driver
    # ];

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];
    systemd.services.nvidia-resume.enable = true;
    systemd.services.nvidia-hibernate.enable = true;
    systemd.services.nvidia-suspend.enable = true;

    hardware.nvidia = {
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = true;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = cfg.isTuring;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = cfg.useOpenDrivers;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # package = config.boot.kernelPackages.nvidiaPackages.production;
      package =
        let
          rcu_patch = pkgs.fetchpatch {
            url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
            hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
          };
        in
        config.boot.kernelPackages.nvidiaPackages.mkDriver {
          # version = "535.86.05";
          #  sha256_64bit = "sha256-QH3wyjZjLr2Fj8YtpbixJP/DvM7VAzgXusnCcaI69ts=";
          #  sha256_aarch64 = "sha256-ON++eWPDWHnm/NuJmDSYkR4sKKvCdX+kwxS7oA2M5zU=";
          #  openSha256 = "sha256-qCYEQP54cT7G+VrLmuMT+RWIwuGdBhlbYTrCDcztfNs=";
          #  settingsSha256 = "sha256-0NAxQosC+zPz5STpELuRKDMap4KudoPGWKL4QlFWjLQ=";
          #  persistencedSha256 = "sha256-Ak4Wf59w9by08QJ0x15Zs5fHOhiIatiJfjBQfnY65Mg=";

          version = "535.154.05";
          sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
          sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
          openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
          settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
          persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

          #version = "550.40.07";
          #sha256_64bit = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
          #sha256_aarch64 = "sha256-AV7KgRXYaQGBFl7zuRcfnTGr8rS5n13nGUIe3mJTXb4=";
          #openSha256 = "sha256-mRUTEWVsbjq+psVe+kAT6MjyZuLkG2yRDxCMvDJRL1I=";
          #settingsSha256 = "sha256-c30AQa4g4a1EHmaEu1yc05oqY01y+IusbBuq+P6rMCs=";
          #persistencedSha256 = "sha256-11tLSY8uUIl4X/roNnxf5yS2PQvHvoNjnd2CB67e870=";

          patches = [ rcu_patch ];
        };
      # package = config.boot.kernelPackages.nvidiaPackages.beta;
      #package = pkgs.linuxKernel.packages.linux_zen.nvidia_x11_production;
    };

  };
}
