{ config
, lib
, pkgs
, ...
}:
{
  gamingHost = false;
  imports = [
    # Include the results of the hardware scan.
    ./kurisu-hardware-configuration.nix

  ];
  # Networking
  networking.hostName = "Kurisu";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  # The systemd DNS resolver
  # see: resolvectl status
  services.resolved = {
    enable = true;
  };

  networking.interfaces.enp44s0.ipv4.addresses = [{
    address = "192.168.1.3";
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
      enable = false;
      isTuring = false; # https://en.wikipedia.org/wiki/Turing_(microarchitecture)#Products_using_Turing
    };
    intel.enable = true;
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

  # Tha audio server
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/main.lua.d/51-bluez-fix.lua" ''
        bluez_monitor.properties["bluez5.enable-sbc-xq"] = true
        bluez_monitor.properties["bluez5.enable-msbc"] = true
        bluez_monitor.properties["bluez5.enable-hw-volume"] = true
        bluez_monitor.properties["bluez5.roles"] = [ "a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hfp_hf" "hfp_ag" ]
        bluez_monitor.properties["bluez5.codecs"] = [ "sbc_sbc" "sbc_xq" "sbc_msbc" "aac" "aptx" "aptx_hd" "ldac" ]
        bluez_monitor.properties["bluez5.keep-profile"] = true
      '')
    ];
  };

  # A gui/tray to manage the bluetooth
  services.blueman.enable = true;

}
