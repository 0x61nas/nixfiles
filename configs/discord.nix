{pkgs, ...}: {
  home.packages = with pkgs; [
    vesktop
    (writeShellScriptBin "discord" ''
      ${pkgs.vesktop}/bin/vencorddesktop "$@"
    '')
    # (discord.override {
    #   withOpenASAR = false;
    #   withVencord = true;
    # })
  ];
}
