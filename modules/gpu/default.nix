{lib, ...}:
with lib;
 {
  imports = [ ./nvidia.nix ];
  config = {
    hardware.opengl = {
      enable = mkDefault true;
      driSupport = mkDefault true;
      driSupport32Bit = mkDefault true;
    };
  };
}
