{
  description = "OS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nur = {
      url = "github:0x61nas/nur";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # nixpkgs-7d69e.url = "nixpkgs/7d69e528a70b434e276e17578e8ef5c5dbc2ef5b";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    lqth = {
      url = "github:0x61nas/lqth";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    archy-dwm = {
      url = "github:archy-linux/archy-dwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins = {
      url = "github:nix-community/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    declarative-jellyfin = {
      url = "github:Sveske-Juice/declarative-jellyfin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    jellyfin-ultrachromic-src = {
      flake = false;
      owner = "CTalvio";
      repo = "Ultrachromic";
      type = "github";
    };

    # flake-parts.url = "github:hercules-ci/flake-parts";
    # utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nur
    , home-manager
    , nix-fast-build
    , nix-jetbrains-plugins
    , ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      # pkgs-7d69e = import nixpkgs-7d69e { inherit system; config = { allowUnfree = true; }; };
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
            };
          }
        );

      commonSpecialArgs = {
        inherit inputs pkgs-unstable nur;
      };
      commonHomeExtraSpecialArgs = {
        inherit inputs pkgs-unstable nur nix-jetbrains-plugins;
      };
    in
    {
      hosts = {
        mayuri = {
          hostPlatform = "x86_64-linux";
          large = false;
        };
        kurisu = {
          hostPlatform = "x86_64-linux";
          large = false;
        };
      };

      nixosConfigurations = {
        mayuri = lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            inherit (inputs) jellyfin-ultrachromic-src;
          };
          modules = [
            {
              nixpkgs.pkgs = pkgs;
            }
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ nur.overlays.default ];
            })

            ./cache.nix
            ./configuration.nix
            inputs.declarative-jellyfin.nixosModules.default
            ./services
            ./hosts/mayuri.nix
            inputs.impermanence.nixosModules.impermanence

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.anas = import ./users/anas.home.nix;

              home-manager.extraSpecialArgs = commonHomeExtraSpecialArgs;
            }
          ];
        };
        kurisu = lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [
            {
              nixpkgs.pkgs = pkgs;
            }
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ nur.overlays.default ];
            })

            ./cache.nix
            ./configuration.nix
            # ./services
            ./services/tailscale.nix
            ./hosts/kurisu.nix
            inputs.impermanence.nixosModules.impermanence

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.anas = import ./users/anas.home.nix;

              home-manager.extraSpecialArgs = commonHomeExtraSpecialArgs;
            }
          ];
        };
      };

      packages = forEachSupportedSystem (
        { pkgs, system }: {
          jq = pkgs.jq;
          mayuri = self.nixosConfigurations.mayuri.config.system.build.toplevel;
          kurisu = self.nixosConfigurations.kurisu.config.system.build.toplevel;
          nix-fast-build = nix-fast-build.packages.${system}.default;
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, ... }: {
          default = pkgs.mkShell {
            name = "nix-config";

            nativeBuildInputs = with pkgs; [
              # Nix
              # agenix
              nil
              nix-melt
              nix-output-monitor
              nix-tree
              nixpkgs-fmt

              # Lua
              # stylua
              # (luajit.withPackages (p: with p; [ luacheck ]))
              # lua-language-server

              # Shell
              shellcheck
              shfmt

              # GitHub Actions
              act
              actionlint
              python3Packages.pyflakes
              shellcheck

              # Misc
              jq
              pre-commit
              just
              fzf
            ];
            shellHook = ''
              #!/usr/bin/env bash
              if ! grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
                  pre-commit install
              fi
              ${pkgs.git}/bin/git status .
            '';
          };
        }
      );
    };
}
