{lib, ...}:
with lib;
 {
  imports = [ ./nvidia.nix ./intel.nix ./amd.nix ];
  config = {
    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
    };
  };
}
