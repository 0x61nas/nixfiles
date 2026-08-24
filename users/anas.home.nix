{ pkgs, ... }: {
  imports = [
    ../system
    ../dev
    ../gui
    ../virtualization
    ../social
    ../media
  ];
  home.username = "anas";
  home.homeDirectory = "/home/anas";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    pfetch-rs
    thunderbird
    tree
    yt-dlp
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
  # Using Bluetooth headset buttons to control media player
  services.mpris-proxy.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin/"
  ];
}
