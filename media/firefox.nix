{ pkgs-unstable, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs-unstable.firefox;

    profiles.default = {
      # everything in the set.
      #extensions.packages = pkgs.firefox-addons.all;

      # …or a hand-picked list.
      extensions.packages = with pkgs.firefox-addons; [
        ublock-origin
        foxytab
        keepassxc-browser
        sponsorblock
        single-file
        auto-tab-discard
        control-panel-for-twitter
        material-icons-for-github
        crxviewer
        pixiv-toolkit
        privacy-extension-for-whatsapp
        readeck
        styl-us
        tab-session-manager
        besttimetracker # Track time, analyze your habits and block addictive sites
        traduzir-paginas-web # Translate your page in real time using Google, Bing or Yandex.
        youtube-recommended-videos # Hide YouTube related videos, comments, video suggestions wall, homepage recommendations, trending tab, and other distractions.
        wayback-machine_new # Wayback Machine
        gruvbox-dark-theme
      ];
    };
  };
}
