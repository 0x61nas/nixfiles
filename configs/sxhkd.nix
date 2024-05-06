{ lib, ... }:
{
  services.sxhkd = {
    enable = true;
    extraOptions = "-m 1";
    keybindings = {
      "super + Return" = "$TERMINAL";
      # Lockscreen
      "super + shift + x" = "slock";
      ##---------- Applications ----------##

      # Lunchers (rofi, dmenu)
      # dmenu
     "super + p" = "rofi -show drun";
     "super + c" = "rofi -show calc";
      # Web browsers
      "super + w; {f,c,b,t}" = "nvidia-offload {firefox,google-chrome,brave,tor-browser}";
      # applications
      "super + shift; {d,o,k}" = "{discord,obsidian,keepassxc}";
      ##---------- System Keys ----------##

      # Take a screenshot in the clipboard
      "shift + Print" = "screenshot -n -c";
      "Print" = "screenshot -r -n -c";
      "ctrl + Print" = "screenshot --activewindow -n -c";
      # Take a screenshot and save it
      "alt + shift + Print" = "screenshot -n";
      "alt + Print" = "screenshot -r -n";
      "alt + ctrl + Print" = "screenshot --activewindow -n";
      "XF86MonBrightness{Up,Down}" = "xbacklight -{inc,dec} 5";
      # Manage Volume
      "XF86Audio{Raise,Lower}Volume" = "sh $HOME/.scripts/volume {up,down}";
      "XF86AudioMute" = "sh $HOME/.scripts/volume mute";
      # Music control
      "XF86Audio{Next,Prev,Play,Stop}" = "playerctl {next,previous,play-pause,stop}";
      # Player control
      "alt + {F1,F2,F3}" = "playerctl {volume 0.0,volume 0.1-, volume 0.1+}";
      "alt + {Left,Right}" = "playerctl {position 1-,position 1+}";
      # Mic mute
      "XF86AudioMicMute" = "sh $HOME/.scripts/toggle_mic";
      # kill window
      "ctrl + alt + Escape" = "xkill";
    };
  };
}
