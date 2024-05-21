{ inputs, pkgs, ... }: {
  services.xserver = {
    enable = true;
    layout = "us,ara";
    xkbVariant = "dvorak-l,";
    xkbOptions = "grp:win_space_toggle caps:swapescape keypad:pointerkeys";

  };

  programs.slock.enable = true;
  # programs.light.enable = true;

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
    # xorg.xf86videointel
    xclip
    nitrogen
    xorg.xbacklight
    xorg.xkill
    xrectsel
    xdo
    inputs.lqth.packages."${pkgs.system}".lqth
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
          [[ -n $NOTIFY ]] && $NOTIFY "Screenshot copyed to system clipbooard"
      else
          $CMD $ARGS | $PIPETO > $OUTFILE
          [[ -n $NOTIFY ]] && $NOTIFY "Screenshot saved at: $OUTFILE"
      fi
    '')
  ];
}
