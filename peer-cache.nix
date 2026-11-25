{ config, lib, pkgs, ... }:
let
  cfg = config.peerCache;

  nodes = {
    mayuri = { interface = "enp7s0"; };
    kurisu = { interface = "enp44s0"; };
  };

  nodeName = lib.toLower config.networking.hostName;
  self = nodes.${nodeName}
    or (throw "peer-cache: unsupported hostName '${config.networking.hostName}'");
  peerName = "${lib.head (lib.attrNames (lib.filterAttrs (n: _: n != nodeName) nodes))}";

  cachePort = 5000;
  signKeyPath = "/etc/nix/peer-cache.key";
in
{
  options.peerCache.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Serve this store to the peer and pull from its cache; builds are not pushed automatically.";
  };

  config = lib.mkIf cfg.enable {
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ signKeyPath ];
      # lower (more preferred) than cache.nixos.org (40) and cachix (41)
      settings.priority = 20;
    };

    services.avahi = {
      enable = true;
      allowInterfaces = [ self.interface ];
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    networking.firewall.interfaces.${self.interface}.allowedTCPPorts = [ cachePort ];

    nix.settings = {
      substituters = [ "http://${peerName}:${toString cachePort}" ];
      trusted-public-keys = [
        "mayuri.lan-1:SWBkvhDM0PspcdH0FnZSrE3dRxNWaM68ysGhlIV4IWo="
        "kurisu.lan-1:IUe58lwhb4jn9e8YNu+LD2eDflFQilhAUXnJSCHFHsE="
      ];
    };
  };
}
