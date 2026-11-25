{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.tor-router;

  keyMountDir = "/var/lib/tor-onion-keys";

  enabledSites = lib.filterAttrs (_: site: site.enable) cfg.sites;

  secretEnabled = name: config.nix-secrets.secrets.${name}.enable or false;

  keySecrets = lib.mapAttrsToList (_: site: site.keySecret) enabledSites;
  secretsAvailable = config.nix-secrets.enable && builtins.all secretEnabled keySecrets;

  containerReady = cfg.enable && cfg.externalInterface != null && secretsAvailable;

  onionServices = lib.mapAttrs
    (
      name: site: {
        secretKey = "${keyMountDir}/${name}-key";
        map = [
          {
            port = site.port;
            target = {
              addr = site.target;
              port = if site.targetPort == null then site.port else site.targetPort;
            };
          }
        ];
        authorizedClients = site.authorizedClients;
        settings = site.settings;
      }
    )
    enabledSites;

  keyBindMounts = lib.listToAttrs (
    lib.mapAttrsToList
      (name: site: {
        name = "${keyMountDir}/${name}-key";
        value = {
          hostPath = config.security.nix-secrets.secrets.${site.keySecret}.path;
          isReadOnly = true;
        };
      })
      enabledSites
  );
in
{
  options.tor-router = {
    enable = lib.mkEnableOption "Tor daemon with declarative onion services in a NixOS container";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tor;
      defaultText = lib.literalExpression "pkgs.tor";
      description = "Tor package to run inside the container.";
    };

    externalInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "enp44s0";
      description = ''
        Host interface used for NAT. Required when the router is enabled.
      '';
    };

    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.236.0.1";
      description = "Host-side address of the private container network. Onion service backends on the host are reached at this address.";
    };

    localAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.236.0.2";
      description = "Container-side address of the private container network.";
    };

    network = lib.mkOption {
      type = lib.types.str;
      default = "10.236.0.0/24";
      description = "Private container network in CIDR notation, used for NAT.";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1.1.1.1" "1.0.0.1" ];
      description = "DNS servers used inside the container.";
    };

    extraLoopbackIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "100.98.50.57" ];
      description = ''
        Extra addresses allowed to reach the forwarded SOCKS port, in addition
        to 127.0.0.1. Add this host's Tailscale address so other hosts in the
        PAC fallback list can use this proxy.
      '';
    };

    socks = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 9050;
        description = "SOCKS port, reachable from the host at 127.0.0.1.";
      };
    };

    sites = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "this onion service" // { default = true; };

              port = lib.mkOption {
                type = lib.types.port;
                description = "Port exposed by the onion service.";
              };

              target = lib.mkOption {
                type = lib.types.str;
                default = cfg.hostAddress;
                defaultText = lib.literalExpression "cfg.hostAddress";
                description = ''
                  Address of the local backend service as seen from the
                  container. Defaults to the host's container address; use
                  127.0.0.1 for a backend running inside the container.
                '';
              };

              targetPort = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
                description = "Backend port. Null uses the same value as port.";
              };

              authorizedClients = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "descriptor:x25519:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ];
                description = "Public keys of clients allowed to access this v3 onion service.";
              };

              settings = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.oneOf [
                    lib.types.str
                    lib.types.int
                    lib.types.bool
                    (lib.types.listOf lib.types.str)
                  ]
                );
                default = { };
                description = "Extra HiddenService* torrc settings for this service.";
              };

              keySecret = lib.mkOption {
                type = lib.types.str;
                default = "tor/sites/${name}/keys";
                description = ''
                  nix-secrets secret holding the v3 onion service's
                  `hs_ed25519_secret_key`. The .onion address is derived from
                  this key, so back it up.
                '';
              };
            };
          }
        )
      );
      description = ''
        Onion services hosted by this Tor instance. Each service needs its
        own key secret in nix-secrets.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || cfg.externalInterface != null;
          message = "tor-router.enable requires tor-router.externalInterface.";
        }
        {
          assertion = !cfg.enable || secretsAvailable;
          message = ''
            tor-router is enabled, but its secrets are not available on this host.
            Enable nix-secrets and make sure the keySecret of every enabled
            onion service is enabled.
          '';
        }
        {
          assertion = lib.length keySecrets == lib.length (lib.unique keySecrets);
          message = "tor-router onion services must not share the same keySecret.";
        }
        {
          assertion = builtins.all
            (name: builtins.match "[A-Za-z0-9_-]+" name != null)
            (builtins.attrNames cfg.sites);
          message = "tor-router onion service names may only contain letters, digits, underscores and dashes.";
        }
      ];
    }

    # Declare secrets as soon as the router is enabled so `nix-secrets edit`
    # can create them before the first successful rebuild.
    (lib.mkIf cfg.enable {
      nix-secrets.secrets = lib.listToAttrs (
        lib.mapAttrsToList
          (name: site: {
            name = site.keySecret;
            value = { };
          })
          enabledSites
      );
    })

    (lib.mkIf containerReady {
      networking.nat = {
        enable = true;
        inherit (cfg) externalInterface;
        internalIPs = [ cfg.network ];
        forwardPorts = [
          {
            sourcePort = cfg.socks.port;
            destination = "${cfg.localAddress}:${toString cfg.socks.port}";
            loopbackIPs = [ "127.0.0.1" ] ++ cfg.extraLoopbackIPs;
          }
        ];
      };

      containers.tor-router = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = cfg.hostAddress;
        localAddress = cfg.localAddress;

        bindMounts = keyBindMounts;

        config =
          { lib, ... }:
          {
            system.stateVersion = "26.05";

            networking = {
              useHostResolvConf = lib.mkForce false;
              nameservers = cfg.dns;
              firewall = {
                enable = true;
                allowedTCPPorts = [ cfg.socks.port ];
              };
            };

            services.tor = {
              enable = true;

              client = {
                enable = true;
                socksListenAddress = {
                  addr = "0.0.0.0";
                  port = cfg.socks.port;
                  IsolateDestAddr = true;
                };
              };

              relay.onionServices = onionServices;

              settings = {
                ExitPolicy = [ "reject *:*" ];
              };
            };

            # The container already isolates the daemon; keep the host's bind
            # mounts visible to Tor instead of using the module's own chroot.
            systemd.services.tor.serviceConfig.RootDirectory = lib.mkForce "";
          };
      };
    })
  ];
}
