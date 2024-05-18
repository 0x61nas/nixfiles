{
  description = "OS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nix-alien.url = "github:thiagokokada/nix-alien";
    sops-nix.url = "github:Mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";

    nix-ld-rs.url = "github:nix-community/nix-ld-rs";
    nix-ld-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... } @inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config = { allowUnfree = true; }; };
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
            inputs.sops-nix.nixosModules.sops
            inputs.impermanence.nixosModules.impermanence
          ];
        };
      };

      homeConfigurations = {
        anas = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit pkgs;
            inherit pkgs-unstable;
            inherit inputs;
          };
          modules = [
            ./users/anas.home.nix
            ({ config, pkgs-unstable, ... }:
              let
                iconTheme = {
                  name = "Gruvbox-Plus-Dark";
                  package = pkgs-unstable.gruvbox-plus-icons;
                };
              in
              {
                gtk.iconTheme.name = iconTheme.name;
                gtk.iconTheme.package = iconTheme.package;
                services.dunst.iconTheme.name = iconTheme.name;
                services.dunst.iconTheme.package = iconTheme.package;
              })
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
            nix
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
