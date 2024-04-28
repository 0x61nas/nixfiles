{
  description = "Gruvbox Iconpack";

  inputs = {
    iconpack = {
      url = "github:SylEleuth/gruvbox-plus-icon-pack";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system:
        import ./default.nix {
          pkgs = import nixpkgs { inherit system; };
        }
      );
    };
}
