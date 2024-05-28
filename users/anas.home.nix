{ pkgs, ... }: {
  imports = [
    ../system
    ../dev
    ../gui
    ../virtualization
    ../social
  ];
  home.username = "anas";
  home.homeDirectory = "/home/anas";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    pfetch-rs
    thunderbird
    tree
    tor-browser
    youtube-dl
    vagrant
    plantuml
    gnupg
    gh
    #eza
    keepassxc
    pavucontrol
    jellycli
    playerctl
    heroic
    #protonup-qt
    wine64Packages.stagingFull
    inlyne
    anki
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin/"
  ];
}
