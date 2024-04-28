{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.workarounds.pulseaudio-mic-boost;
  pulseaudio_with_mic_boost_disabled =
    let
      constantVolume = 100;
    in
    pkgs.pulseaudio.overrideAttrs (old: {
      # name = "pulseaudio-patched";
      name = "${old.name}-patched-without-mic-boost";
      # Instead of overriding some post-build action, which would require a
      # pulseaudio rebuild, we override the entire `buildCommand` to produce
      # its outputs by copying the original package's files (much faster).
      buildCommand = ''
        set -euo pipefail

        ${# Copy original files, for each split-output (`out`, `dev` etc.).
          lib.concatStringsSep "\n"
            (map
              (outputName:
                ''
                  echo "Copying output ${outputName}"
                  set -x
                  cp -a ${pkgs.pulseaudio.${outputName}} ''$${outputName}
                  set +x
                ''
              )
              old.outputs
            )
        }

        # Replace:
        #     [Element Capture]
        #     switch = mute
        #     volume = merge
        # by:
        #     [Element Capture]
        #     switch = mute
        #     volume = ${toString constantVolume}
        # The target file `analog-input-internal-mic.conf` should be determined
        # by the output of `pacmd list-sources` for the relevant microphone `index:`,
        # which for my microphone is:
        #     active port: <analog-input-internal-mic>
        set -x
        INFILE=$out/share/pulseaudio/alsa-mixer/paths/analog-input-internal-mic.conf
        cat $INFILE \
          | ${pkgs.python3}/bin/python -c 'import re,sys; print(re.sub(r"\[Element Capture\]\nswitch = mute\nvolume = merge", "[Element Capture]\nswitch = mute\nvolume = ${toString constantVolume}", sys.stdin.read()))' \
          > tmp.conf
        # Ensure file changed (something was replaced)
        ! cmp tmp.conf $INFILE
        chmod +w $out/share/pulseaudio/alsa-mixer/paths/analog-input-internal-mic.conf
        cp tmp.conf $INFILE
        set +x
      '';
    });
in
{
  options.workarounds.pulseaudio-mic-boost.enable = mkEnableOption "Disbale pulseaudio mic boost";
  config = mkIf (config.hardware.pulseaudio.enable && cfg.enable) {
    hardware.pulseaudio.package = pulseaudio_with_mic_boost_disabled;
  };
}
