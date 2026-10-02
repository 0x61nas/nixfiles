{ config, lib, pkgs-unstable, ... }:
with lib;
let
  cfg = config;
in
{
  options.gamingHost = mkEnableOption ("Enable the gaming related configurations");

  config.programs.steam = mkIf cfg.gamingHost {
    enable = true;
    package = pkgs-unstable.steam;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };
}
