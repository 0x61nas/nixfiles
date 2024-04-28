{ inputs, lib, pkgs, ... }:

let
  base16Theme = [ "Gruvbox" "Dark" "Hard" ];
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    #inputs.spotify-adblock.homeManagerModules.spotify-adblock
    ../configs/shell/zsh.nix
    ../configs/shell/aliases.nix
    ../configs/nvim/nvim.nix
    ../configs/dunst.nix
    ../configs/gnupg.nix

  ];
  home.username = "anas";
  home.homeDirectory = "/home/anas";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    pfetch-rs
    btop
    nvtop
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
    gh
    eza
    bat
    gitmux
    keepassxc
    pavucontrol
    jellyfin
    jellycli
    jellyfin-web
    playerctl
    # notification daemon
    dunst
    libnotify
  ];

  # theme
  colorScheme = inputs.nix-colors.colorSchemes.${lib.strings.toLower (lib.strings.concatStringsSep "-" base16Theme)};

  programs.git = {
    enable = true;
    userName = "0x61nas";
    userEmail = "anas.elgarhy.dev@gmail.com";
    ignores = [ "*~" ];
    signing = {
      #signByDefault = true;
      key = "0x83E03DC6F3834086";
    };
    aliases = {
      logline = "log --graph --oneline --decorate";
      # allows you to switch branches quickly. For example, `git co master` instead of `git checkout master`
      co = "checkout";
      # simplifying the commit process. For example, `git ci -m "Commit message"` instead of `git commit -m "Commit message"`
      ci = "commit";
      # helping you create branches faster. For example, `git br feature` instead of `git branch feature`.
      br = "branch";
      st = "status";
      df = "diff";
      lg = "log --pretty=\"%C(magenta)%h%Creset %C(yellow)%d%Creset%s %C(bold cyan)(%ar)%Creset\"";
      lgg = "lg --abbrev-commit --all --graph";
      unstage = "reset HEAD";
      last = "log -1 HEAD";
      undo = "reset HEAD~";
      pushf = "push --force";
      squash = "!git rebase -i HEAD~$1";
      amend = "commit --amend -S";
      aliases = "config --get-regexp alias";
      brl = "!git for-each-ref --format='%(refname:short) %(objectname:short)' refs/heads/";
      uncommit = "reset HEAD^";
      hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      ff = "merge --ff-only";
      shelve = "!git stash && git checkout";
      unshelve = "stash apply && git stash drop";
      sync = "!git fetch && git rebase origin/$(git symbolic-ref --short HEAD)";
      upstream = "branch --set-upstream-to";
      ignore = "!echo '$1' >> .gitignore";
      rebase = "rebase -S";
      addp = "add --patch";
    };
    extraConfig = {
      init.defaultBranch = "aurora";
      diff.tool = "nvimdiff";
      difftool.prompt = false;
      difftool."nvimdiff".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
      interactive.diffFilter = "delta --color-only";
      github.user = "0x61nas";

      merge.tool = "nvimdiff";
      mergetool.prompt = true;
      mergetool."nvimdiff".cmd =
        "nvim -d \"$LOCAL\" \"$REMOTE\" \"$MERGED\" -c 'wincmd w' -c 'wincmd J'";

      push.autoSetupRemote = true;
    };
  };

  #programs.spotify-adblock = {
    #enable = true;
    #client = pkgs.spotify;
    #generateDesktopFile = true;
  #};

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    #extraPackges = [ pkgs.gitmux ];
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    newSession = true;
    extraConfig = builtins.readFile ../configs/tmux/tmux.conf;
  };
  
  programs.home-manager.enable = true;

  xdg.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
  };
}
