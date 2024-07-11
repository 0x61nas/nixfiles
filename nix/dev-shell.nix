{ pkgs, ... }:
{
  default = pkgs.mkShell {
    name = "nix-config";

    nativeBuildInputs = with pkgs; [
      # Nix
      # agenix
      deploy-rs.deploy-rs
      nil
      nix-melt
      nix-output-monitor
      nix-tree
      nixpkgs-fmt

      # Lua
      # stylua
      # (luajit.withPackages (p: with p; [ luacheck ]))
      # lua-language-server

      # Shell
      shellcheck
      shfmt

      # GitHub Actions
      act
      actionlint
      python3Packages.pyflakes
      shellcheck

      # Misc
      jq
      pre-commit
      just
      fzf
    ];
    shellHook = ''
      #!/usr/bin/env bash
      if ! grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
          pre-commit install
      fi
      ${pkgs.git}/bin/git status .
    '';
  };
}
