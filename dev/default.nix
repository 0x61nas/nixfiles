{ pkgs, pkgs-unstable, ... }: {
  imports = [
    ./nvim
    ./cargo
    ./direnv.nix
    # ./devenv.nix
  ];

  home.packages = with pkgs; [
    neovide
    pkgs-unstable.ida-free
  ];
}
