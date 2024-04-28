{
  description = "Spotify Adblock";
  inputs = {
    spotify-adblock = {
      url = "github:abba23/spotify-adblock";
      flake = false;
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      bin = (pkgs.rustPlatform.buildRustPackage {
        name = "spotify-adblock";
        src = inputs.spotify-adblock.outPath;
        cargoLock = {
          lockFile = inputs.spotify-adblock.outPath + "/Cargo.lock";
        };
      }).outPath + "/lib/libspotifyadblock.so";
      desktopFile = client: ''
        [Desktop Entry]
        Type=Application
        Name=Spotify (adblock)
        GenericName=Music Player
        Icon=spotify-client
        TryExec=${client}/bin/spotify
        Exec=env LD_PRELOAD=${bin} ${client}/bin/spotify %U
        Terminal=false
        MimeType=x-scheme-handler/spotify;
        Categories=Audio;Music;Player;AudioVideo;
        StartupWMClass=spotify
      '';
      configFile = inputs.spotify-adblock.outPath + "/config.toml";
    in
    {
      homeManagerModules.spotify-adblock = import ./default.nix { inherit desktopFile; inherit configFile; };
      homeManagerModule = self.homeManagerModules.spotify-adblock;
      packages = forAllSystems (system:
        import ./default.nix { inherit desktopFile; inherit configFile; } {
          pkgs = import nixpkgs { inherit system; };
        }
      );
    };
}
