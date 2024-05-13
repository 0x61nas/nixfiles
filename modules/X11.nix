{ pkgs, ... }: {
  services.xserver = {
      enable = true;
      layout = "us,ara";
      xkbVariant = "dvorak-l,";
      xkbOptions = "grp:win_space_toggle caps:swapescape keypad:pointerkeys";
      
  };

  programs.slock.enable = true;

  environment.systemPackages = with pkgs; [
      xorg.libX11
      xorg.libX11.dev
      xorg.libxcb
      xorg.libXft
      xorg.libXinerama
      xorg.xinit
      xorg.xinput
      xorg.xorgserver
      xorg.xf86inputevdev
      xorg.xf86videointel
      xclip
      nitrogen
      xorg.xbacklight
      xorg.xkill
      xrectsel
      xdo
  ];
}
