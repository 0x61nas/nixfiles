{ pkgs, ... }: {
  home.packages = with pkgs; [
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
