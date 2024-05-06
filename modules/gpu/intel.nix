{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.gpu.intel;
in
{
  options.gpu.intel.enable = mkEnableOption ("Use integrated  intel gpu");

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "modesetting" ];
    #boot.initrd.kernelModules = [ "amdgpu" ];
  };
}
