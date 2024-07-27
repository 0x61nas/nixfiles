{ pkgs, ... }: {
  users.groups.media = { };
  services.jellyfin = {
    enable = true;
    group = "media";
    package = pkgs.jellyfin;
    # dataDir = "/mnt/data/media/jellyfin/var"
  };

  environment.systemPackages = with pkgs; [ feishin ];
}
