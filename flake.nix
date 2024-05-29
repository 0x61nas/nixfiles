{
  description = "OS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # nixpkgs-7d69e.url = "nixpkgs/7d69e528a70b434e276e17578e8ef5c5dbc2ef5b";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien.url = "github:thiagokokada/nix-alien";
    impermanence.url = "github:nix-community/impermanence";

    nix-ld-rs.url = "github:nix-community/nix-ld-rs";
    nix-ld-rs.inputs.nixpkgs.follows = "nixpkgs";

    lqth.url = "github:0x61nas/lqth";
    archy-dwm.url = "github:archy-linux/archy-dwm";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... } @inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config = { allowUnfree = true; }; };
      # pkgs-7d69e = import nixpkgs-7d69e { inherit system; config = { allowUnfree = true; }; };
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

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

              # TODO replace ryan with your own username
              home-manager.users.anas = import ./users/anas.home.nix;

              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit pkgs;
                inherit pkgs-unstable;

              };
            }
          ];
        };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            git
            nixpkgs-fmt
            just
            pre-commit
            # nix
            jq
            fzf
          ];
          shellHook = ''
            #!/usr/bin/env bash
            ${pkgs.git}/bin/git status .
          '';
        };
      });

      # devShells = forAllSystems (system:
      #   let
      #     pkgs = nixpkgsFor.${system};
      #   in
      #   {
      #     shellHook = ''
      #       #!/usr/bin/env bash
      #       bin=${pkgs.tmux}/bin/tmux
      #       $bin new-session -As "configs:1" -n code  -d "${pkgs.neovim}/bin/nvim ."
      #       $bin new-window  -t  "configs:2" -n shell
      #
      #       $bin attach -t configs:1
      #     '';
      #   });

    };
}
