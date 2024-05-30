{ pkgs-unstable, ... }: {
  users.groups.media = { };
  services.jellyfin = {
    enable = true;
    group = "media";
    package = pkgs-unstable.jellyfin;
    # dataDir = "/mnt/data/media/jellyfin/var"
  };
}
