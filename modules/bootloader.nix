{ pkgs-7d69e, ... }: {
  boot = {
    kernelPackages = pkgs-7d69e.linuxPackages_zen;
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
