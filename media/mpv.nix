{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
      mpv-cheatsheet
    ];
    scriptOpts = {
      uosc = {
        border = "no";
      };
    };
  };
}
