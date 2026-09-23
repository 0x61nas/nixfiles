{ config
, jellyfin-ultrachromic-src
, lib
, pkgs
, pkgs-unstable
, ...
}:
let
  inherit (lib) hasAttr fileContents optionals;
  inherit (config.vars) mainUser;

  optionalGroup =
    name: optionals (hasAttr name config.users.groups) [ config.users.groups.${name}.name ];

  # https://github.com/matt1432/nixos-jellyfin#forceEnableBackdrops
  jellyfin-web = pkgs.jellyfin-web.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/scripts/settings/userSettings.js \
        --replace-fail "return toBoolean(this.get('enableBackdrops', false), false);" \
                     "return toBoolean(this.get('enableBackdrops', false), true);"
    '';
  });
in
{
  # To use use NVENC for hardware encoding. To use this, CUDA must be enabled
  users.users."jellyfin".extraGroups =
    optionalGroup mainUser
    ++ optionalGroup "input"
    ++ optionalGroup "media"
    ++ optionalGroup "render"
    ++ optionalGroup "video";

  services.declarative-jellyfin = {
    enable = true;
    inherit jellyfin-web;
    serverId = "8356f7decc7b4c8db04f62834e735b69";

    users.anas = {
      password = "let me in";
      mutable = true;
      permissions = {
        isAdministrator = true;
        enableContentDeletion = true;
        enableRemoteControlOfOtherUsers = true;
        enableCollectionManagement = true;
      };
    };

    libraries = {
      Movies = {
        contentType = "movies";
        pathInfos = [ "/mnt/data/media/movies" ];
        automaticRefreshIntervalDays = 90;
        automaticallyAddToCollection = true;
        enableEmbeddedExtraTitles = true;
        enableEmbeddedEpisodeInfos = true;
        subtitleDownloadLanguages = [
          "eng"
          "ara"
        ];
        subtitleFetcherOrder = [
          "Open Subtitles"
        ];
      };
      Shows = {
        contentType = "tvshows";
        pathInfos = [ "/mnt/data/media/shows" ];
        automaticRefreshIntervalDays = 90;
        automaticallyAddToCollection = true;
        enableEmbeddedExtraTitles = true;
        enableEmbeddedEpisodeInfos = true;
        subtitleDownloadLanguages = [
          "eng"
          "ara"
        ];
        subtitleFetcherOrder = [
          "Open Subtitles"
        ];
      };
      "Music Videos" = {
        contentType = "musicvideos";
        pathInfos = [ "/mnt/data/media/music videos" ];
        automaticRefreshIntervalDays = 120;
      };
      Music = {
        contentType = "music";
        pathInfos = [ "/mnt/data/media/music" ];
        automaticRefreshIntervalDays = 90;
        enableEmbeddedExtraTitles = true;
        enableEmbeddedEpisodeInfos = true;
        #enableRealtimeMonitor = false;
      };
      "Anime Movies" = {
        contentType = "movies";
        pathInfos = [ "/mnt/data/media/anime/Movies" ];
        automaticRefreshIntervalDays = 90;
        automaticallyAddToCollection = true;
        enableEmbeddedExtraTitles = true;
        enableEmbeddedEpisodeInfos = true;
        subtitleDownloadLanguages = [
          "eng"
          "ara"
        ];
        subtitleFetcherOrder = [
          "Open Subtitles"
        ];
      };
      Anime = {
        contentType = "tvshows";
        pathInfos = [ "/mnt/data/media/anime/Shows" ];
        automaticRefreshIntervalDays = 90;
        automaticallyAddToCollection = true;
        enableEmbeddedExtraTitles = true;
        enableEmbeddedEpisodeInfos = true;
        subtitleDownloadLanguages = [
          "eng"
          "ara"
        ];
        subtitleFetcherOrder = [
          "Open Subtitles"
        ];
      };
    };

    system = {
      serverName = "Mayuri";
      metadataPath = "/mnt/data/media/jellyfin/metadata";
      preferredMetadataLanguage = "en";
      quickConnectAvailable = false;
      enableExternalContentInSuggestions = false;
      enableSlowResponseWarning = false;
      trickplayOptions = {
        enableHwAcceleration = true;
        enableHwEncoding = true;
        enableKeyFrameOnlyExtraction = true;
      };
      pluginRepositories = [
        {
          tag = "RepositoryInfo";
          content = {
            Name = "Jellyfin Stable";
            Url = "https://repo.jellyfin.org/files/plugin/manifest.json";
            Enabled = true;
          };
        }
        {
          tag = "RepositoryInfo";
          content = {
            Name = "Intro Skipper";
            Url = "https://raw.githubusercontent.com/jumoog/intro-skipper/master/manifest.json";
            Enabled = true;
          };
        }
        {
          tag = "RepositoryInfo";
          content = {
            Name = "Merge Versions Plugin";
            Url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
            Enabled = true;
          };
        }
      ];
      metadataOptions = [
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [ ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "Movie";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [
              "The Open Movie Database"
            ];
            disabledMetadataFetchers = [
              "The Open Movie Database"
            ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "MusicVideo";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [ ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "Series";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [
              "TheAudioDB"
            ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "MusicAlbum";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            ImageFetcherOrder = [ ];
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [
              "TheAudioDB"
            ];
            disabledMetadataSavers = [ ];
            itemType = "MusicArtist";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [ ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "BoxSet";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [ ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "Season";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
        {
          content = {
            disabledImageFetchers = [ ];
            disabledMetadataFetchers = [ ];
            disabledMetadataSavers = [ ];
            imageFetcherOrder = [ ];
            itemType = "Episode";
            localMetadataReaderOrder = [ ];
            metadataFetcherOrder = [ ];
          };
          tag = "MetadataOptions";
        }
      ];
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
        "vc1"
        "vp8"
        "vp9"
        "av1"
      ];
      allowHevcEncoding = config.gpu.nvidia.enableCUDA;
      enableTonemapping = true;
      downMixAudioBoost = 1;
    };
  };

  environment.systemPackages = with pkgs-unstable; [ feishin ];
}
