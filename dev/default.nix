{ pkgs, pkgs-unstable, nur, ... }: {
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
    pkgs-unstable.ida-free
    nur.packages.${pkgs.system}.ducker
  ];
}
