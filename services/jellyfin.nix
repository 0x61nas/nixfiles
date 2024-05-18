{ pkgs, ... }: {
  users.groups.media = { };
  services.jellyfin = {
    enable = true;
    group = "media";
    # dataDir = "/mnt/data/media/jellyfin/var"
  };

  environment.systemPackages = with pkgs; [
    # jellyfin-web
    #jellyfin-ffmpeg
  ];
}
