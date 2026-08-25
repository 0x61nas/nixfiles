{ pkgs-unstable, nur, ... }: {
  imports = [
    ./nvim
    ./cargo
    ./direnv.nix
    # ./devenv.nix
  ];

  home.packages = with pkgs-unstable; [
    neovide
    heh
    hex
    nur.packages.${pkgs-unstable.stdenv.hostPlatform.system}.ducker
    nur.packages.${pkgs-unstable.stdenv.hostPlatform.system}.guitar
    onefetch
    nixfmt
    android-tools
    lua
    go
  ];
}
