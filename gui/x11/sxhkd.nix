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
      "super + w; {f,c,b,t}" = "{firefox,google-chrome,brave,tor-browser}";
      # applications
      "super + shift; {d,o,k}" = "{discord,obsidian,keepassxc}";
      ##---------- System Keys ----------##

      # Take a lqth-wrapper in the clipboard
      "shift + Print" = "lqth-wrapper -n -c";
      "Print" = "lqth-wrapper -r -n -c";
      "ctrl + Print" = "lqth-wrapper --activewindow -n -c";
      # Take a lqth-wrapper and save it
      "alt + shift + Print" = "lqth-wrapper -n";
      "alt + Print" = "lqth-wrapper -r -n";
      "alt + ctrl + Print" = "lqth-wrapper --activewindow -n";
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
