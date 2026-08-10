{ pkgs, nur, ... }: {
  home.packages = with nur; [

    pkgs.pkg-config
    pkgs.alsa-lib

  ];
}
