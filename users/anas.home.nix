{ inputs, lib, pkgs, config, ... }:

let
  base16Theme = [ "Gruvbox" "Dark" "Hard" ];
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
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
    jellyfin
    jellycli
    jellyfin-web
    playerctl
    heroic
    #protonup-qt
    wine64Packages.stagingFull
    inlyne
  ];

  # theme
  colorScheme = inputs.nix-colors.colorSchemes.${lib.strings.toLower (lib.strings.concatStringsSep "-" base16Theme)};

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

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
