{
  imports = [
    ./workarounds/default.nix
    ./bootloader.nix
    ./locale.nix
    ./networking.nix
    ./gpu/default.nix
    ./nix-ld.nix
    ./X11.nix
    ./st.nix
    #./dmenu.nix
    ./archy-slstatus.nix
    ./fonts.nix
  ];
}
