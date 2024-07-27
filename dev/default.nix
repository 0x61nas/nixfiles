{ pkgs, nur, ... }: {
  imports = [
    ./nvim
    ./cargo
    ./direnv.nix
    # ./devenv.nix
  ];

  home.packages = with pkgs; [
    neovide
    heh
    hex
    ida-free
    nur.packages.${pkgs.system}.ducker
    onefetch
    loc
    tokei
    nur.packages.${pkgs.system}.tokei-pie
    nixfmt-rfc-style
    android-tools
    zed-editor
    lua
    go
  ];
}
