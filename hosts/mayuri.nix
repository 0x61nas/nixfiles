{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./mayuri-hardware-configuration.nix

  ];
  # Networking
  networking.hostName = "Mayuri";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager  = {
    enable = true;
    dns = "systemd-resolved";
  };

  # The systemd DNS resolver
  # see: resolvectl status
  services.resolved = {
    enable = true;
  };

  networking.interfaces.enp7s0.ipv4.addresses = [{
     address = "192.168.1.2";
     prefixLength = 24;
  }];

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  gpu = {
    nvidia = {
      enable = true;
      isTuring = false; # https://en.wikipedia.org/wiki/Turing_(microarchitecture)#Products_using_Turing
    };
    intel.enable = false;
    amd.enable = false;
  };
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true; # Set to false if using SSH keys only
    };
  };

    # A gui/tray to manage the bluetooth
  services.blueman.enable = true;
}
