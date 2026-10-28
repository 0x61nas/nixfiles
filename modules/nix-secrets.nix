{ config
, inputs
, lib
, ...
}:
let
  cfg = config.nix-secrets;

  # Only secrets that are enabled on this host are handed to nix-secrets.
  enabledSecrets = lib.filterAttrs (_: secret: secret.enable) cfg.secrets;
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

    templates = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.content = lib.mkOption {
            type = lib.types.lines;
            description = "Content of the rendered template.";
          };
        }
      );
      default = { };
      description = ''
        Templates managed by nix-secrets. Use
        `security.nix-secrets.secrets.<name>` inside the content to insert a
        decrypted secret value.
      '';
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

        templates = lib.mapAttrs
          (_: template: {
            inherit (template) content;
          })
          cfg.templates;
      };
    })
  ];
}
