{ config
, inputs
, lib
, ...
}:
let
  cfg = config.nix-secrets;

  # Only secrets that are enabled on this host are handed to nix-secrets.
  enabledSecrets = lib.filterAttrs (_: secret: secret.enable) cfg.secrets;

  openvpnCredentialsEnabled =
    enabledSecrets ? "openvpn/username"
    && enabledSecrets ? "openvpn/password";
in
{
  imports = [ inputs.nix-secrets.nixosModules.default ];

  options.nix-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to activate nix-secrets on this host.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this secret is managed on this host.";
            };

            recipients = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Recipients for this secret. When empty,
                security.nix-secrets.defaultRecipients is used.
              '';
            };
          };
        }
      );
      description = "Secrets managed by nix-secrets. Each entry can be disabled per host.";
    };

    identityPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Age identity files used to decrypt secrets on this host.";
    };

    recipientAliases = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.either lib.types.str (lib.types.listOf lib.types.str)
      );
      default = { };
      description = "Recipient aliases used by this host's secrets.";
    };
  };

  config = lib.mkMerge [
    {
      # Define the known secrets at normal priority so host-level overrides
      # such as `nix-secrets.secrets."openvpn/config".enable = false` merge
      # instead of replacing the whole set.
      nix-secrets.secrets = {
        "openvpn/config" = { };
        "openvpn/username" = { };
        "openvpn/password" = { };
      };

      security.nix-secrets = {
        storage = ../secrets;
        storagePath = "/home/anas/nixfiles/secrets";
        inherit (cfg) identityPaths recipientAliases;
        defaultRecipients = [ "anas" ];
      };
    }

    (lib.mkIf cfg.enable {
      security.nix-secrets = {
        enable = true;

        secrets = lib.mapAttrs
          (_: secret:
            lib.optionalAttrs (secret.recipients != [ ]) {
              inherit (secret) recipients;
            }
          )
          enabledSecrets;

        templates = lib.mkIf openvpnCredentialsEnabled {
          "openvpn/credentials".content = ''
            ${config.security.nix-secrets.secrets."openvpn/username"}
            ${config.security.nix-secrets.secrets."openvpn/password"}
          '';
        };
      };
    })
  ];
}
