{ config, pkgs, ... }:

let
  customDwm = pkgs.stdenv.mkDerivation {
    name = "archy-dwm";
    src = pkgs.fetchFromGitHub {
      owner = "archy-linux";
      repo = "archy-dwm";
      rev = "aurora";
      hash = "sha256-i4h6aNKR85r0KBPIrPExCJcp22Iv9NI/5Qr0pi80iRc=";
    };
     buildInputs = with pkgs; [ xorg.libX11 xorg.libXft xorg.libXinerama ];
    installPhase = ''
      echo "Listing build directory contents:"
      ls -la
      mkdir -p $out/bin
      cp ./build/archy-dwm $out/bin/
    '';
  };
in
{
  imports = [
    ./X11.nix
  ];

  environment.systemPackages = with pkgs; [ customDwm sxhkd dmenu slock ];

  services.xserver.windowManager = {dwm.enable = true;  # Ensures dwm is recognized
 # services.xserver.displayManager.lightdm.enable = false;
      bspwm.sxhkd.configFile = builtins.getEnv "HOME" + "/.config/sxhkd/sxhkdrc";
      };

  services.xserver = {
      displayManager = {
        lightdm.enable = false;
        startx.enable = true;
      };
  };

#   services.xserver.displayManager.lightdm.sessions = [
#     {
#       name = "archy-dwm";
#       desktopName = "archy-dwm";
#       startScript = pkgs.writeScript "start-dwm.sh" ''
#         #!${pkgs.runtimeShell}
#         ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
#         ${pkgs.sxhkd}/bin/sxhkd &  # Start sxhkd in the background
#         exec ${customDwm}/bin/archy-dwm
#       '';
#     }
#   ];
}
