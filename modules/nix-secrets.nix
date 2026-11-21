{ config
, inputs
, lib
, ...
}:
let
  cfg = config.nix-secrets;

  # Only secrets that are enabled on this host are handed to nix-secrets.
  enabledSecrets = lib.filterAttrs (_: secret: secret.enable) cfg.secrets;
  enabledTemplates = lib.filterAttrs (_: template: template.enable) cfg.templates;

  # Optional pass-through to security.nix-secrets for secrets/templates that
  # need a custom location or ownership (for example a service's key file).
  placementOptions = {
    path = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.addCheck lib.types.str (path: builtins.substring 0 1 path == "/")
      );
      default = null;
      description = ''
        Absolute path where to place the decrypted file. Null uses the
        nix-secrets default. Use a string, not a Nix path, so the file is not
        copied into the store.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Permissions of the decrypted file, e.g. \"0400\". Null uses the default.";
    };

    owner = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.int lib.types.str);
      default = null;
      description = "Owner of the decrypted file. Null uses the default.";
    };

    group = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.int lib.types.str);
      default = null;
      description = "Group of the decrypted file. Null uses the default.";
    };

    isSymlink = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Whether to symlink the file instead of writing it in place. Null uses the default.";
    };
  };

  # Drop null values so they don't override nix-secrets' own defaults.
  placementAttrs = item:
    lib.filterAttrs (_: value: value != null) {
      inherit (item) path mode owner group isSymlink;
    };
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
          } // placementOptions;
        }
      );
      description = "Secrets managed by nix-secrets. Each entry can be disabled per host.";
    };

    templates = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this template is managed on this host.";
            };

            content = lib.mkOption {
              type = lib.types.lines;
              description = "Content of the rendered template.";
            };
          } // placementOptions;
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
            (lib.optionalAttrs (secret.recipients != [ ]) {
              inherit (secret) recipients;
            })
            // placementAttrs secret
          )
          enabledSecrets;

        templates = lib.mapAttrs
          (_: template: {
            inherit (template) content;
          } // placementAttrs template)
          enabledTemplates;
      };
    })
  ];
}
