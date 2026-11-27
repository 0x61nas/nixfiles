{ config
, lib
, pkgs-unstable
, ...
}:
let
  cfg = config.multi-scrobbler;

  secretEnabled = name: config.nix-secrets.secrets.${name}.enable or false;
  secretsAvailable = config.nix-secrets.enable
    && secretEnabled cfg.adminSetupPasswordSecret
    && secretEnabled cfg.jellyfin.apiKeySecret
    && secretEnabled cfg.tealFm.appPasswordSecret;

  containerReady = cfg.enable && secretsAvailable;

  configMount = "/config";
  environmentMount = "/run/secrets/multi-scrobbler.env";
  jellyfinConfigMount = "${configMount}/jellyfin.json";
  tealFmConfigMount = "${configMount}/tealfm.json";

  jellyfinConfigTemplate = "multi-scrobbler-jellyfin-config";
  tealFmConfigTemplate = "multi-scrobbler-tealfm-config";

  extraEnvironment = lib.mapAttrsToList
    (name: value: "${name}=${toString value}")
    cfg.extraEnvironment;

  # Only runtime/persistent-directory settings stay in the environment. Sources
  # and clients are declared in JSON files below, using interpolation keys that
  # do not collide with multi-scrobbler's own ENV configuration names.
  environment = [
    "TZ=${cfg.timeZone}"
    "PORT=${toString cfg.port}"
    "BASE_URL=${cfg.baseUrl}"
    "CONFIG_DIR=${configMount}"
    "DATA_DIR=${configMount}"
    "LOGS_DIR=${configMount}/logs"
  ] ++ extraEnvironment;

  jellyfinConfig = builtins.toJSON [
    {
      name = cfg.jellyfin.name;
      id = cfg.jellyfin.id;
      enable = true;
      clients = [ ];
      data = {
        url = cfg.jellyfin.url;
        user = cfg.jellyfin.user;
        apiKey = "[[MS_JELLYFIN_API_KEY]]";
      };
    }
  ];

  tealFmConfig = builtins.toJSON [
    {
      name = cfg.tealFm.name;
      id = cfg.tealFm.id;
      configureAs = "client";
      data = {
        identifier = cfg.tealFm.identifier;
        appPassword = "[[MS_TEALFM_APP_PASSWORD]]";
      };
    }
  ];

  # Match on the container address, not iifname: nspawn truncates long veth
  # names (ve-multi-scrobbler becomes e.g. ve-multi-scqLsJ), so an iifname
  # match would silently never fire.
  # Keep the firewall allow-list and the container's /etc/hosts entry in sync
  # with the URL multi-scrobbler actually dials.
  jellyfinUrl =
    let
      match = builtins.match "[[:alpha:]][[:alnum:]+.-]*://([^/:]+)(:([0-9]+))?(/.*)?$" cfg.jellyfin.url;
    in
    if match == null then
      { host = null; port = null; }
    else
      {
        host = builtins.head match;
        port = if builtins.elemAt match 2 == null then null else builtins.fromJSON (builtins.elemAt match 2);
      };

  # Local ranges the isolated container must not reach. 100.64.0.0/10 covers
  # Tailscale's IPv4 range; fc00::/7 covers its IPv6 ULA range.
  localNetworks4 = lib.concatStringsSep ", " [
    "0.0.0.0/8"
    "10.0.0.0/8"
    "100.64.0.0/10"
    "127.0.0.0/8"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "224.0.0.0/4"
    "240.0.0.0/4"
  ];

  localNetworks6 = lib.concatStringsSep ", " [
    "::1/128"
    "fc00::/7"
    "fe80::/10"
    "ff00::/8"
    "2001:db8::/32"
  ];

  localTargets =
    lib.optional (cfg.jellyfin.address != null && jellyfinUrl.port != null) {
      address = cfg.jellyfin.address;
      port = jellyfinUrl.port;
    }
    ++ cfg.allowedLocalTargets;

  forwardRules = ''
    # The nixos-fw forward chain accepts established/related traffic and DNAT'd
    # connections before these rules, so replies and the forwarded web UI work.
    ${lib.concatStringsSep "\n" (map (target: ''
      ip saddr ${cfg.localAddress} ip daddr ${target.address} \
        tcp dport ${toString target.port} \
        accept comment "multi-scrobbler: allow ${target.address}:${toString target.port}"
    '') localTargets)}

    # Deny every other local/private destination, including other Tailscale
    # peers, the host itself and link-local/multicast ranges.
    ip saddr ${cfg.localAddress} ip daddr { ${localNetworks4} } \
      drop comment "multi-scrobbler: deny local IPv4"
    ip6 saddr fe80::/10 ip6 daddr { ${localNetworks6} } \
      drop comment "multi-scrobbler: deny local IPv6"

    # Anything else is internet traffic (teal.fm, Last.fm, public DNS, ...).
    ip saddr ${cfg.localAddress} accept comment "multi-scrobbler: allow internet"
    ip6 saddr fe80::/10 accept comment "multi-scrobbler: allow internet (IPv6)"
  '';
in
{
  options.multi-scrobbler = {
    enable = lib.mkEnableOption "multi-scrobbler in a host-network NixOS container";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs-unstable.multi-scrobbler;
      defaultText = lib.literalExpression "pkgs-unstable.multi-scrobbler";
      description = "multi-scrobbler package from the nixpkgs-unstable input.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9078;
      description = "Port for the web UI and API, bound on the host network.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Africa/Cairo";
      example = "UTC";
      description = "Timezone passed to multi-scrobbler as TZ.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:9078";
      example = "http://mayuri:9078";
      description = "Public URL passed to multi-scrobbler as BASE_URL.";
    };

    hostConfigDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/multi-scrobbler/config";
      description = ''
        Host directory bind-mounted at /config in the container. It is created
        with uid/gid ownership before the service starts and holds the config,
        database, credentials and logs written by multi-scrobbler.
      '';
    };

    uid = lib.mkOption {
      type = lib.types.ints.u32;
      default = 1000;
      description = "Numeric UID the service runs as, matching Docker's user directive.";
    };

    gid = lib.mkOption {
      type = lib.types.ints.u32;
      default = 1001;
      description = "Numeric GID the service runs as, matching Docker's user directive.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler";
      description = "User name created inside the container for the service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler";
      description = "Group name created inside the container for the service.";
    };

    adminSetupPasswordSecret = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler/admin-setup-password";
      description = ''
        nix-secrets secret containing ADMIN_SETUP_PW, used to create the
        initial admin account on first setup.
      '';
    };

    jellyfin = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Mayuri Jellyfin";
        description = "Friendly name for the Jellyfin source in jellyfin.json.";
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8096";
        description = "Jellyfin URL written to jellyfin.json.";
      };

      address = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "100.126.74.4";
        description = ''
          IPv4 address of the Jellyfin server (Mayuri's Tailscale address). It
          is the only local destination allowed on the URL's port and is pinned
          in the container's /etc/hosts. Set to null if Jellyfin is online.
        '';
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "anas";
        description = "Jellyfin username written to jellyfin.json.";
      };

      id = lib.mkOption {
        type = lib.types.str;
        default = "Mayuri-Jellyfin";
        description = "multi-scrobbler source identifier written to jellyfin.json.";
      };

      apiKeySecret = lib.mkOption {
        type = lib.types.str;
        default = "multi-scrobbler/jellyfin-apikey";
        description = "nix-secrets secret containing the Jellyfin API key.";
      };
    };

    tealFm = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "TealFm";
        description = "Friendly name for the Teal.fm client in tealfm.json.";
      };

      id = lib.mkOption {
        type = lib.types.str;
        default = "myTeal";
        description = "multi-scrobbler client identifier written to tealfm.json.";
      };

      identifier = lib.mkOption {
        type = lib.types.str;
        default = "anelgarhy.bsky.social";
        description = "Teal.fm account identifier written to tealfm.json.";
      };

      appPasswordSecret = lib.mkOption {
        type = lib.types.str;
        default = "multi-scrobbler/teal-fm-app-password";
        description = "nix-secrets secret containing the Teal.fm app password.";
      };
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = { };
      example = {
        LASTFM_APIKEY = "0123456789abcdef";
        MALOJA_URL = "https://maloja.example";
      };
      description = "Additional environment variables for multi-scrobbler.";
    };

    environmentTemplate = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler/environment";
      description = "nix-secrets template used to pass secret environment variables.";
    };

    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.1";
      description = "Host side of the container's private veth pair.";
    };

    localAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.2";
      description = "Container side of the container's private veth pair.";
    };

    dnsServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = ''
        Public resolvers used inside the isolated container. The host's stub
        resolver is not reachable from its own network namespace.
      '';
    };

    allowedLocalTargets = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          address = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address or CIDR of the allowed local destination.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            description = "TCP port allowed on that destination.";
          };
        };
      });
      default = [ ];
      example = [ { address = "192.168.1.10"; port = 8000; } ];
      description = ''
        Additional local/Tailscale destinations the container may reach. All
        other local traffic is dropped; internet traffic is always allowed.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || secretsAvailable;
          message = ''
            multi-scrobbler is enabled, but its secrets are not available on this host.
            Enable nix-secrets and make sure ${cfg.adminSetupPasswordSecret},
            ${cfg.jellyfin.apiKeySecret} and ${cfg.tealFm.appPasswordSecret}
            are enabled.
          '';
        }
        {
          assertion = !cfg.enable || builtins.substring 0 1 cfg.hostConfigDir == "/";
          message = "multi-scrobbler.hostConfigDir must be an absolute path.";
        }
      ];
    }

    # Declare secrets as soon as the service is enabled so `nix-secrets edit`
    # can create them before the first successful switch.
    (lib.mkIf cfg.enable {
      nix-secrets.secrets = {
        "${cfg.adminSetupPasswordSecret}" = { };
        "${cfg.jellyfin.apiKeySecret}" = { };
        "${cfg.tealFm.appPasswordSecret}" = { };
      };

      nix-secrets.templates."${cfg.environmentTemplate}" = {
        content = ''
          ADMIN_SETUP_PW=${config.security.nix-secrets.secrets.${cfg.adminSetupPasswordSecret}}
          MS_JELLYFIN_API_KEY=${config.security.nix-secrets.secrets.${cfg.jellyfin.apiKeySecret}}
          MS_TEALFM_APP_PASSWORD=${config.security.nix-secrets.secrets.${cfg.tealFm.appPasswordSecret}}
        '';
        path = "/var/lib/multi-scrobbler/environment.env";
        mode = "0440";
        owner = "root";
        group = cfg.gid;
        isSymlink = false;
      };

      # Declarative, non-secret JSON config. Credentials stay as interpolation
      # placeholders until multi-scrobbler reads them at startup. nix-secrets
      # copies non-symlink templates into place as root, so these files are
      # world-readable for the unprivileged service inside the container.
      nix-secrets.templates.${jellyfinConfigTemplate} = {
        content = jellyfinConfig;
        mode = "0644";
        owner = cfg.uid;
        group = cfg.gid;
        isSymlink = false;
      };

      nix-secrets.templates.${tealFmConfigTemplate} = {
        content = tealFmConfig;
        mode = "0644";
        owner = cfg.uid;
        group = cfg.gid;
        isSymlink = false;
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      # Docker creates a missing bind-mount source; systemd-nspawn does not.
      # Pre-create it with the same numeric ownership the service uses.
      systemd.tmpfiles.rules = [
        "d /var/lib/multi-scrobbler 0750 root root -"
        "d ${cfg.hostConfigDir} 0750 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.hostConfigDir}/logs 0750 ${toString cfg.uid} ${toString cfg.gid} -"
      ];
    })

    (lib.mkIf containerReady {
      containers.multi-scrobbler = {
        autoStart = true;

        privateNetwork = true;
        hostAddress = cfg.hostAddress;
        localAddress = cfg.localAddress;

        forwardPorts = [
          {
            containerPort = cfg.port;
            hostPort = cfg.port;
            protocol = "tcp";
          }
        ];

        bindMounts = {
          "${configMount}" = {
            hostPath = cfg.hostConfigDir;
            isReadOnly = false;
          };
          "${jellyfinConfigMount}" = {
            hostPath = config.security.nix-secrets.templates.${jellyfinConfigTemplate}.path;
            isReadOnly = true;
          };
          "${tealFmConfigMount}" = {
            hostPath = config.security.nix-secrets.templates.${tealFmConfigTemplate}.path;
            isReadOnly = true;
          };
          "${environmentMount}" = {
            hostPath = config.security.nix-secrets.templates.${cfg.environmentTemplate}.path;
            isReadOnly = true;
          };
        };

        config =
          { lib, ... }:
          {
            system.stateVersion = "26.05";

            networking.firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.port ];
            };

            # Public DNS plus a pinned Jellyfin hostname: MagicDNS and the
            # host's 127.0.0.53 stub are unavailable inside this netns.
            networking.nameservers = cfg.dnsServers;
            networking.extraHosts = lib.optionalString
              (cfg.jellyfin.address != null
                && jellyfinUrl.host != null
                && builtins.match "[0-9.]+" jellyfinUrl.host == null)
              "${cfg.jellyfin.address} ${jellyfinUrl.host}\n";

            users.groups.${cfg.group}.gid = cfg.gid;
            users.users.${cfg.user} = {
              uid = cfg.uid;
              group = cfg.group;
              isSystemUser = true;
              createHome = false;
            };

            systemd.services.multi-scrobbler = {
              description = "Multi-Scrobbler";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/multi-scrobbler";
                User = cfg.user;
                Group = cfg.group;
                Environment = environment;
                EnvironmentFile = environmentMount;
                Restart = "always";
                RestartSec = 5;
                NoNewPrivileges = true;
              };
            };
          };
      };
      # start after the tailscaled service so the host names resolve
      systemd.services."container@multi-scrobbler" = {
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
    };
    networking.nftables.enable = true;
    networking.firewall = {
      filterForward = true;
      extraForwardRules = forwardRules;
    };

    # systemd-networkd is disabled on these hosts, so the ve-* interface never
    # gets its usual IPMasquerade=both. NAT the container's address explicitly
    # or neither the internet nor Tailscale replies would make it back.
    networking.nftables.tables."multi-scrobbler-nat" = {
      family = "ip";
      content = ''
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ip saddr ${cfg.localAddress} masquerade comment "multi-scrobbler: outbound NAT"
        }
      '';
    };
    })
  ];
}
