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
  pushKeyPath = "/etc/nix/peer-cache-push.key";

  pushScript = pkgs.writeShellScript "peer-cache-push" ''
    set -u
    export PATH="${lib.makeBinPath [ config.nix.package pkgs.coreutils pkgs.openssh ]}"
    if [ -z "''${OUT_PATHS:-}" ]; then
      exit 0
    fi
    echo "peer-cache: pushing to ${peerName}: $OUT_PATHS"
    NIX_SSHOPTS="-o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/etc/nix/peer-cache-known-hosts" \
      timeout 300 ${lib.getExe config.nix.package} copy \
        --to "ssh-ng://root@${peerName}?ssh-key=${pushKeyPath}" \
        $OUT_PATHS \
      || echo "peer-cache: push to ${peerName} failed (peer down?): $OUT_PATHS"
    exit 0
  '';
in
{
  options.peerCache.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Mutual binary cache: serve this store to the peer and push new builds to it.";
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

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVsNhll9dLWsDFn4x2Us9XyX0pCqXmGJbm3mNGdmFR6 peer-cache"
    ];

    nix.settings = {
      substituters = [ "http://${peerName}:${toString cachePort}" ];
      trusted-public-keys = [
        "mayuri.lan-1:SWBkvhDM0PspcdH0FnZSrE3dRxNWaM68ysGhlIV4IWo="
        "kurisu.lan-1:IUe58lwhb4jn9e8YNu+LD2eDflFQilhAUXnJSCHFHsE="
      ];
      post-build-hook = pushScript;
    };
  };
}
