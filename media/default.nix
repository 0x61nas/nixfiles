{ pkgs-unstable, ... }:
{
  imports = [
    ./mpv.nix
    ./sioyek.nix
  ];

  home.packages = with pkgs-unstable; [ trackma-qt spotify ];
}
