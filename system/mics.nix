{ pkgs, nur, ... }: {
  home.packages = with nur; [
    packages.${pkgs.system}.lpl
  ];
}
