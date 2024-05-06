{ pkgs-unstable, ... }: {
  boot = {
    kernelPackages = pkgs-unstable.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 15;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      # not working see: https://github.com/NixOS/nixpkgs/issues/243026
      timeout = 3;
    };
  };
}
