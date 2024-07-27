{ pkgs, ... }: {
  programs.gitui = {
    enable = true;
    package = pkgs.gitui;
    # theme = ''
    #
    # '';
  };
}
