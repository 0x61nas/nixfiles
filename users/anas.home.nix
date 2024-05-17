{ inputs, lib, pkgs, config, ... }:

let
  base16Theme = [ "Gruvbox" "Dark" "Hard" ];
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ../system
    ../dev
    ../configs/dunst.nix
    ../configs/gnupg.nix
    ../configs/git.nix
    ../configs/btop.nix
    ../configs/sxhkd.nix
    ../configs/x11
    ../configs/rofi.nix
    ../configs/cargo
    ../configs/bat.nix
    ../configs/tmux
    ../configs/zoxide.nix
    ../virtualization
    # ../configs/thunar.nix
    ../configs/xdg.nix
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
