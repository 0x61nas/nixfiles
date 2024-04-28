{
  description = "NextJS Template";

  inputs = {
    nixpkgs.url = "nixpkgs";
    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    { nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pname = ""; # <same as package.json name>
      buildInputs = with pkgs; [
        nodejs_20
        nodePackages_latest.pnpm
      ];
    in
    {
      devShells.default = pkgs.mkShell {
        inherit buildInputs;
        shellHook = ''
          #!/usr/bin/env bash

          ${pkgs.nodePackages_latest.pnpm}/bin/pnpm i

          bin=${pkgs.tmux}/bin/tmux
          $bin new-session -As "${pname}:1" -n code  -d "${pkgs.neovim}/bin/nvim ."
          $bin new-window  -t  "${pname}:2" -n build -d "${pkgs.nodePackages_latest.pnpm}/bin/pnpm run dev"
          $bin new-window  -t  "${pname}:3" -n shell

          $bin attach -t${pname}:1
        '';
      };
    });
}
