{ pkgs, ... }: {
  imports = [
    ./discord.nix
  ];

  home.packages = with pkgs; [ telegram-desktop ];
}
