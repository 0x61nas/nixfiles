{ config, pkgs, ... }:

let
  st = pkgs.stdenv.mkDerivation {
    name = "st";
  version = "0.8.4";

  src = pkgs.fetchFromGitHub {
    owner = "archy-linux";
    repo = "archy-st";
    rev = "aurora";
    hash = "sha256-QxmXqfFGtgwFcOq6oFxSueEEFz7Lg+e29XRchv+1kIE=";  # Use `nix-prefetch-url --unpack <url>` to get the hash
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
