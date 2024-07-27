{ pkgs, nur, ... }: {
  home.packages = with nur; [
    packages.${pkgs.system}.lpl
    pkgs.pkg-config
    pkgs.alsa-lib

  ];
}
