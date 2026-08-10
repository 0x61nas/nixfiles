{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    lua-language-server
    nil
    rust-analyzer
    stylua
    asm-lsp
    # nodePackages_latest.lua-fmt
    luaformatter
    #python312Packages.python-lsp-server
    gopls
    #zls
    #pylint
    tree-sitter
    #nodejs_22
    # nasmfmt
    # typos

  ];
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
