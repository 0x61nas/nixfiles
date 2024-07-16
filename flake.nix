{
  description = "OS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nur = {
      url = "github:0x61nas/nur";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # nixpkgs-7d69e.url = "nixpkgs/7d69e528a70b434e276e17578e8ef5c5dbc2ef5b";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien.url = "github:thiagokokada/nix-alien";
    impermanence.url = "github:nix-community/impermanence";

    nix-ld-rs.url = "github:nix-community/nix-ld-rs";
    nix-ld-rs.inputs.nixpkgs.follows = "nixpkgs";

    lqth.url = "github:0x61nas/lqth";
    archy-dwm.url = "github:archy-linux/archy-dwm";

    # flake-parts.url = "github:hercules-ci/flake-parts";
    # utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nur, home-manager, ... } @inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config = { allowUnfree = true; }; };
      # pkgs-7d69e = import nixpkgs-7d69e { inherit system; config = { allowUnfree = true; }; };
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      nixosConfigurations = {
        Mayuri = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit pkgs;
            inherit pkgs-unstable;
            inherit nur;
          };
          modules = [
            ./cache.nix
            ./configuration.nix
            ./services
            inputs.impermanence.nixosModules.impermanence

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.anas = import ./users/anas.home.nix;

              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit pkgs;
                inherit pkgs-unstable;
                inherit nur;

              };
            }
          ];
        };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
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
      });
    };
}
