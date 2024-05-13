{pkgs, ...}: let
  tmux-gruvbox = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "gruvbox";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "archy-linux";
      repo = "tmux-gruvbox";
      rev = "3f9e38d7243179730b419b5bfafb4e22b0a969ad";
      sha256 = "sha256-jvGCrV94vJroembKZLmvGO8NknV1Hbgz2IuNmc/BE9A=";
    };
  };
in {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    terminal = "xterm-256color";
    escapeTime = 0;
    keyMode = "vi";
    # prefix = "C-B";
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [
      # {
      #   plugin = catppuccin;
      #   extraConfig = builtins.readFile ./catppuccin.conf;
      # }
      {
        plugin = tmux-gruvbox;
        # extraConfig = builtins.readFile ./tmux-gruvbox-dark.conf;
      }
      # {
      #   plugin = rose-pine;
      #   extraConfig = builtins.readFile ./rose-pine.conf;
      # }
      yank
      tmux-fzf
      vim-tmux-navigator
    ];
    extraConfig = builtins.readFile ./tmux.conf;
  };

  home.packages = with pkgs; [
    gitmux
    # https://github.com/edr3x/tmux-sessionizer?tab=readme-ov-file#tmux-sessionizer
    tmux-sessionizer
    # Script to find files with tmux in vim
    (writeShellScriptBin "tmux-sessionizer-script" ''
      if [[ $# -eq 1 ]]; then
          selected=$1
      else
          selected=$(find ~/projects ~/tests ~/ztm -mindepth 1 -maxdepth 1 -type d | fzf)
      fi

      if [[ -z $selected ]]; then
          exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
          tmux new-session -s $selected_name -c $selected
          exit 0
      fi

      if ! tmux has-session -t=$selected_name 2> /dev/null; then
          tmux new-session -ds $selected_name -c $selected
      fi

      if [[ -z $TMUX ]]; then
          nvim "$selected"
          tmux kill-session -t $selected_name
      else
          nvim "$selected"
          tmux kill-session -t $selected_name
      fi
    '')
  ];
}
