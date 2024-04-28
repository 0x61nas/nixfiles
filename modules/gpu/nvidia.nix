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
    boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
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
      EGL_PLATFORM = "wayland";
      };


    # hardware.opengl.extraPackages = with pkgs;  [
    #     nvidia-vaapi-driver
    # ];

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];
    # systemd.services.nvidia-resume.enable = true;
    # systemd.services.nvidia-hibernate.enable = true;
    # systemd.services.nvidia-suspend.enable = true;

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


    prime = {
	# Make sure to use the correct Bus ID values for your system!
	intelBusId = "PCI:0:2:0";
	nvidiaBusId = "PCI:1:0";
 };

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

  };
}
