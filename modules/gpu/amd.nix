{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.gpu.amd;
in
{
  options.gpu.amd.enable = mkEnableOption ("Use amd gpu");

  config = mkIf cfg.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];

    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.opengl.extraPackages = with pkgs; [
      amdvlk
    ];
    # For 32 bit applications 
    hardware.opengl.extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
}
