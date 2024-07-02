{ pkgs-unstable, ... }: {
  programs.gitui = {
    enable = true;
    package = pkgs-unstable.gitui;
    # theme = ''
    #
    # '';
  };
}
