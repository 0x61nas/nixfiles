{ pkgs, ... }: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "gruvbox_dark_v2";
      vim_keys = true;
    };
  };
  xdg.configFile."btop/btop.conf".force = true;
}
