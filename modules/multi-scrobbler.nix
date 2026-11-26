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
      # placeholders until multi-scrobbler reads them at startup.
      nix-secrets.templates.${jellyfinConfigTemplate} = {
        content = jellyfinConfig;
        mode = "0640";
        owner = cfg.uid;
        group = cfg.gid;
        isSymlink = false;
      };

      nix-secrets.templates.${tealFmConfigTemplate} = {
        content = tealFmConfig;
        mode = "0640";
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

        # Equivalent to Docker's `network_mode: host`: the app binds the host's
        # port 9078 directly and can reach Jellyfin at 127.0.0.1:8096.
        privateNetwork = false;

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

            # The container shares the host's network namespace, so the host's
            # firewall owns port 9078.
            networking.firewall.enable = false;

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
    })
  ];
}
