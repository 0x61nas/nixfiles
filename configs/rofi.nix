{ lib, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    #theme = "gruvbox-dark";
    extraConfig = {
      modi = "drun,emoji,ssh";
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
  };
}
