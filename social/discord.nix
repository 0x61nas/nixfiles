{ pkgs-unstable, ... }: {
  home.packages = with pkgs-unstable; [
    vesktop
    (writeShellScriptBin "discord" ''
      ${vesktop}/bin/vencorddesktop "$@"
    '')
    # (discord.override {
    #   withOpenASAR = false;
    #   withVencord = true;
    # })
  ];
}
