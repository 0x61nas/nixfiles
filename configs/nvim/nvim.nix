{ pkgs, ... }:
{
  home.packages = with pkgs; [
      lua-language-server
      nil
      nixpkgs-fmt
      rust-analyzer
      stylua
      nodePackages.bash-language-server
      asm-lsp
  ];
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
