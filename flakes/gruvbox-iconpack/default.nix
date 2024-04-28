# { config, pkgs, lib, ... }:
# with lib;
# let
#   cfg = config.programs.spotify-adblock;
# in pkgs
# {
#   options.programs.spotify-adblock = {
#     enable = mkEnableOption "Spotify Adblock";
#
#     client = mkOption {
#       type = types.package;
#       default = pkgs.spotify;
#       defaultText = literalExpression "pkgs.spotify";
#       description = "The spotify client to use";
#     };
#
#     generateDesktopFile = mkOption {
#       type = types.bool;
#       default = true;
#       description = "Generate desktop file";
#     };
#
#     configFile = mkOption {
#       type = types.path;
#       default = configFile;
#       description = "Config File";
#     };
#   };
#
#   config = mkIf cfg.enable {
#     home.file.".local/share/applications/spotify-adblock.desktop".text =
#       if cfg.generateDesktopFile then desktopFile cfg.client else "";
#     home.file.".config/spotify-adblock/config.toml".source = cfg.configFile;
#   };
# }

{ pkgs, inputs, ... }:
pkgs.stdenv.mkDerivation {
  name = "gruvbox-plus";

}
