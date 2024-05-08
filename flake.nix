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

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config = { allowUnfree = true; }; };
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

      devShells.${system}.default = pkgs.mkShell
        {
          shellHook = ''
            #!/usr/bin/env bash
            bin=${pkgs.tmux}/bin/tmux
            $bin new-session -As "configs:1" -n code  -d "${pkgs.neovim}/bin/nvim ."
            $bin new-window  -t  "configs:2" -n shell

            $bin attach -t configs:1
          '';
        };

      templates = {
        nextjs-pkg = {
          path = ./templates/nextjs;
          description = "Basic nextjs app ready to be compiled";
          welcomeText = ''
            - To Compile Run The Bash Script `./dist.sh`

            - To Add Lincense
            ```nix-shell -p licensor --command "licensor SPDX > LICENSE"```
          '';
        };
      };
    };
}
