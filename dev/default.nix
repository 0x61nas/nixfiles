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
    ida-free
    nur.packages.${pkgs-unstable.system}.ducker
    onefetch
    loc
    tokei
    nur.packages.${pkgs-unstable.system}.tokei-pie
    nixfmt-rfc-style
    android-tools
    zed-editor
    lua
    go
  ];
}
