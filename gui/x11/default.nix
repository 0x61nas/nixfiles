{ pkgs-unstable, nur, ... }:
let
  wallpaper = ../../wallpapers/nix-chan-01.png;
  wallpapersDir = ../../wallpapers;
in
{
  imports = [
    ./sxhkd.nix
    nur.homeManagerModules.autolock
    nur.homeManagerModules.xsetwall
  ];

  services.autolock = {
    enable = true;
    package = nur.packages.${pkgs-unstable.stdenv.hostPlatform.system}.autolock;
    timeout = "300";
  };


  services.xsetwall = {
    enable = true;
    package = nur.packages.${pkgs-unstable.stdenv.hostPlatform.system}.xsetwall;
    whiteBorder = true;
    staticWallpaper = "${wallpaper}";
    mode = "random";
    directory = "${wallpapersDir}";
    interval = 600; # 10 min
  };

  home.packages = [
    nur.packages.${pkgs-unstable.stdenv.hostPlatform.system}.xsetwall
  ];

  home.file = {
    ".xprofile".source = ./xprofile.sh;
    ".xinitrc".source = ./xinitrc.sh;
    #".Xresources".source = ./Xresources;
    #".local/share/X11/base16-gruvbox-dark-hard-256.Xresources".source = ./base16-gruvbox-dark-hard-256.Xresources;
  };

  xresources = {
    properties = {
      #include "/home/anas/.themes/x/base16-gruvbox-dark-hard-256.Xresources"
      "*faceName" = "Public Sans";
      "xterm*faceSize" = 14;
      "*multiClickTime" = 300;
      "*international" = true;
      "Xcursor.theme" = "default";
      "Xcursor.size" = 16; # 32, 48 or 64 may also be good values
      # Xft settings ---------------------------------------------------------------
      "Xft.lcdfilter" = "lcddefault";
      "Xft.antialias" = true;
      "Xft.autohint" = false;
      "Xft.hinting" = true;
      "Xft.hintstyle" = "hintfull";
      "Xft.rgba" = "rgb";
      "Xft.dpi" = 110;
      # xterm ----------------------------------------------------------------------
      "xterm*geometry" = "100x25";
      "xterm*dynamicColors" = true;
      "xterm*utf8" = 1;
      "xterm*eightBitInput" = true;
      "xterm*saveLines" = 12000;
      "xterm*scrollTtyKeypress" = true;
      "xterm*scrollTtyOutput" = false;
      "xterm*jumpScroll" = true;
      "xterm*multiScroll" = true;
      "xterm*toolBar" = false;
      "xterm*termName" = "xterm-256color";
      "xterm*faceName" = "Noto Sans Mono";
    };
    extraConfig = builtins.readFile ./base16-gruvbox-dark-hard-256.Xresources;
  };
}
