{ config
, jellyfin-flake
, jellyfin-ultrachromic-src
, lib
, pkgs
, pkgs-unstable
, ...
}:
let
  inherit (lib) hasAttr fileContents optionals;
  inherit (config.vars) mainUser;

  optionalGroup = name:
    optionals
      (hasAttr name config.users.groups)
      [ config.users.groups.${name}.name ];
  jfPackages = jellyfin-flake.packages.${pkgs.system};
  jellyPkgs = jfPackages // lib.optionalAttrs config.gpu.nvidia.enableCUDA {
    jellyfin-ffmpeg = jfPackages.jellyfin-ffmpeg-cuda;
  };

in
{
  imports = [
    jellyfin-flake.nixosModules.default
  ];
  # To use use NVENC for hardware encoding. To use this, CUDA must be enabled
  users.users."jellyfin".extraGroups =
    optionalGroup mainUser
    ++ optionalGroup "input"
    ++ optionalGroup "media"
    ++ optionalGroup "render"
    ++ optionalGroup "video";

  services.jellyfin = {
    enable = true;
    package = jellyPkgs.jellyfin;
    webPackage = jellyPkgs.jellyfin-web.override {
      forceEnableBackdrops = true;
    };
    ffmpegPackage = jellyPkgs.jellyfin-ffmpeg;

    # dataDir = "/mnt/data/media/jellyfin/var"
    #hardwareAcceleration = {
    # enable = true;
    #type = "nvenc";
    #device = "/dev/dri/renderD128";
    #};

    settings = {
      system = {
        serverName = "Mayuri";
        quickConnectAvailable = false;
        isStartupWizardCompleted = true;

        enableExternalContentInSuggestions = false;

        pluginRepositories = [
          {
            name = "Jellyfin Stable";
            url = "https://repo.jellyfin.org/releases/plugin/manifest-stable.json";
          }
          {
            name = "Intro Skipper";
            url = "https://raw.githubusercontent.com/jumoog/intro-skipper/master/manifest.json";
          }
          {
            name = "Merge Versions Plugin";
            url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
          }
        ];

        enableSlowResponseWarning = false;
      };

      branding =
        let
          jellyTheme = pkgs.stdenv.mkDerivation {
            name = "Ultrachromic";
            src = jellyfin-ultrachromic-src;
            postInstall = "cp -ar $src $out";
          };

          importFile = file: fileContents "${jellyTheme}/${file}";
        in
        {
          customCss = ''
            /* Base theme */
            ${importFile "base.css"}
            ${importFile "accentlist.css"}
            ${importFile "fixes.css"}

            ${importFile "type/dark_withaccent.css"}

            ${importFile "rounding.css"}
            ${importFile "progress/floating.css"}
            ${importFile "titlepage/title_banner-logo.css"}
            ${importFile "header/header_transparent.css"}
            ${importFile "login/login_frame.css"}
            ${importFile "fields/fields_border.css"}
            ${importFile "cornerindicator/indicator_floating.css"}

            /* Style backdrop */
            .backdropImage {filter: blur(18px) saturate(120%) contrast(120%) brightness(40%);}

            /* Custom Settings */
            :root {--accent: 145,75,245;}
            :root {--rounding: 12px;}

            /* https://github.com/CTalvio/Ultrachromic/issues/79 */
            .skinHeader {
              color: rgba(var(--accent), 0.8);;
            }
            .countIndicator,
            .fullSyncIndicator,
            .mediaSourceIndicator,
            .playedIndicator {
              background-color: rgba(var(--accent), 0.8);
            }
          '';
        };

      encoding = {
        hardwareAccelerationType = "nvenc";
        hardwareDecodingCodecs = [
          "h264"
          "hevc"
          "mpeg2video"
          "mpeg4"
          "vc1"
          "vp8"
          "vp9"
          "av1"
        ];
        allowHevcEncoding = config.gpu.nvidia.enableCUDA;
        enableThrottling = false;
        enableTonemapping = true;
        downMixAudioBoost = 1;
      };
    };
  };

  environment.systemPackages = with pkgs-unstable; [ feishin ] ++ (with config.services.jellyfin; [
    finalPackage
    webPackage
    ffmpegPackage
  ]);
}
