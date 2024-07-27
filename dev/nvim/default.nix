{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    tree-sitter
    nodejs_22
    # nasmfmt
    # typos

  ];
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
