{ config, pkgs, ... }:

let
  st = pkgs.stdenv.mkDerivation {
    name = "st";
  version = "0.8.4";

  src = pkgs.fetchFromGitHub {
    owner = "archy-linux";
    repo = "archy-st";
    rev = "7775631d43af165987280a9bb6715390d124e5ee";
    hash = "sha256-KCl9ip986xs7pLBalT/TDqlw/rCwlWolr9XcXGMW1eo=";
  };

  buildInputs = with pkgs; [ xorg.libX11 xorg.libXft pkg-config harfbuzz ];


  configurePhase = ''
    # Custom configure commands if any
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
      echo "Listing build directory contents:"
      ls -la
      mkdir -p $out/bin
      cp st $out/bin/
    '';
  };
in
{
  environment.systemPackages = [ st ];
}
