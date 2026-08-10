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
#    nur.packages.${pkgs-unstable.system}.ducker
    onefetch
    nixfmt-rfc-style
    android-tools
    zed-editor
    lua
    go
  ];
}
