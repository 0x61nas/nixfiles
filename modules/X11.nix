{ inputs, pkgs, ... }: {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us,ara";
      variant = "dvorak-l,";
      options = "grp:win_space_toggle caps:swapescape keypad:pointerkeys";
    };
  };

  programs.slock.enable = true;
  # programs.light.enable = true;

  services.xserver.windowManager = {
    dwm.enable = true; # Ensures dwm is recognized
    bspwm.sxhkd.configFile = builtins.getEnv "HOME" + "/.config/sxhkd/sxhkdrc";
  };

  services.xserver = {
    displayManager = {
      lightdm.enable = false;
      startx.enable = true;
    };
  };

  # Xorg started via `startx` needs to open /dev/tty0 (to query VT settings)
  # and /dev/ttyN (as its console). NixOS doesn't ship systemd's default udev
  # rules, so /dev/tty* end up 0600 root:tty; grant the tty group read/write
  # and make sure the user is a member (see configuration.nix).
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="tty[0-9]*", GROUP="tty", MODE="0660"
  '';

  environment.systemPackages = with pkgs; [
    inputs.archy-dwm.packages."${pkgs.stdenv.hostPlatform.system}".archy-wm
    sxhkd
    # libx11
    # libx11.dev
    # libxcb
    # libxft
    # libxinerama
    xinit
    xinput
    xorg-server
    xf86-input-evdev
    # xf86-video-intel
    xclip
    nitrogen
    xbacklight
    xkill
    xrectsel
    xdo
    inputs.lqth.packages."${pkgs.stdenv.hostPlatform.system}".lqth
    (writeShellScriptBin "lqth-wrapper" ''
        #!/bin/env bash
        CMD=lqth
        ARGS=""
        PIPETO=${pkgs.farbfeld}/bin/ff2png
        NOTIFY=
        OUTFILE="$HOME/Pictures/screenshot.png"
        SELTOOL=
        COPY=

        usage() {
            echo "Usage: $0 [--region|--activewindow|--notify|--output <output_file>|--copy]" >&2
            echo "The default output file: $OUTFILE" >&2
            exit 1
        }

        while [ $# -gt 0 ]; do
            arg="$1"
            if [[ $1 == "-"* ]]; then
                arg="''${arg#-}"
            else
                echo "Invalid argument $1" >&2
                exit 1
            fi
            case $arg in
                o | output)
                    shift
                  if [[ $# -eq 0 ]]; then
                      echo "Missing file path" >&2
                      exit 1
                  fi
                  OUTFILE=$1
                  ;;
              r | region)
                  SELTOOL=${pkgs.xrectsel}/bin/xrectsel;;
              w | activewindow)
                  ARGS="-w $(printf "%d" $(${pkgs.xdo}/bin/xdo id))" 2>/dev/null;;
              n | notify)
                  NOTIFY="notify-send --urgency=low --expire-time=900 --app-name=$0";;
              c | copy)
                  COPY="${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i";;
              *)
                  usage;;
          esac
          shift
      done

      if [[ -n $SELTOOL ]]; then
          [[ -n $NOTIFY ]] && $NOTIFY "Select an region to take a screenshot for"
          ARGS="-r $($SELTOOL "x:%x,y:%y,w:%w,h:%h")"
      fi

      if [[ -n $COPY ]]; then
          $CMD $ARGS | $PIPETO | $COPY
          [[ -n $NOTIFY ]] && $NOTIFY "Screenshot copied to system clipbooard"
      else
          $CMD $ARGS | $PIPETO > $OUTFILE
          [[ -n $NOTIFY ]] && $NOTIFY "Screenshot saved at: $OUTFILE"
      fi
    '')
  ];
}
