{ pkgs-unstable, ... }: {
  programs.mpv = {
    enable = true;
    # package = with pkgs-unstable; wrapMpv
    #   (mpv-unwrapped.override {
    #     vapoursynthSupport = true;
    #   })
    #   {
    #     youtubeSupport = true;
    #   };
    scripts = with pkgs-unstable.mpvScripts; [
      uosc
      thumbfast
    ];
    scriptOpts = {
      uosc = {
        border = "no";
      };
    };
  };
}
