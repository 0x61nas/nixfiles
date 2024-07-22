{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    lua-language-server
    nil
    rust-analyzer
    stylua
    nodePackages.bash-language-server
    asm-lsp
    # nodePackages_latest.lua-fmt
    luaformatter
    python312Packages.python-lsp-server
    gopls
    zls
    pylint
    # nasmfmt
    # typos

  ];
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
