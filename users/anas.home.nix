{ inputs, lib, pkgs, config, ... }:

let
  base16Theme = [ "Gruvbox" "Dark" "Hard" ];
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ../configs/shell/zsh.nix
    ../configs/shell/aliases.nix
    ../configs/nvim/nvim.nix
    ../configs/dunst.nix
    ../configs/gnupg.nix
    ../configs/git.nix
    ../configs/btop.nix
    ../configs/sxhkd.nix
    ../configs/x11/xinit.nix
    ../configs/rofi.nix
    ../configs/cargo/cargo.nix
    ../configs/bat.nix
    ../configs/tmux
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
    cmus
    just
    gnupg
    discord
    #dorion
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
    # notification daemon
    dunst
    libnotify
    wine64Packages.stagingFull
  ];

  # theme
  colorScheme = inputs.nix-colors.colorSchemes.${lib.strings.toLower (lib.strings.concatStringsSep "-" base16Theme)};

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin/"
  ];
}
