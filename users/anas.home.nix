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
  ];

  programs.home-manager.enable = true;
  # Using Bluetooth headset buttons to control media player
  services.mpris-proxy.enable = true;
  # mewo :3
  nixowos.enable = true;
  nixowos.overlays.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin/"
  ];
}
