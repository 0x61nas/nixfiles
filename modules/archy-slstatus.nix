{ config, pkgs, ... }:

let
  archy-slstatus = pkgs.stdenv.mkDerivation {
    name = "archy-slstatus";
  version = "1.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "archy-linux";
    repo = "archy-slstatus";
    rev = "1.0.1";
    hash = "sha256-UAG3la4IqTmPbMIFc2WXF8F5nyAQACs5Y4FZn7Zgrw8=";  # Use `nix-prefetch-url --unpack <url>` to get the hash
  };

  buildInputs = with pkgs; [ xorg.libX11 xorg.libXft ];


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
      cp ./build/archy-slstatus $out/bin/
    '';
  };
in
{
  environment.systemPackages = [ archy-slstatus ];
}
