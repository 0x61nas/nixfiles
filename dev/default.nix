{ pkgs, ... }: {
  imports = [
    ./nvim
    ./cargo
    ./direnv.nix
    # ./devenv.nix
  ];

  home.packages = with pkgs; [ neovide ];
}
