{ config
, lib
, pkgs
, ...
}:
{
  gamingHost = true;
  imports = [
    # Include the results of the hardware scan.
    ./mayuri-hardware-configuration.nix
  ];

  # nix-secrets activates in stage 1, so the age identity under /home must be
  # mounted before the initrd activation script runs.
  fileSystems."/home".neededForBoot = true;

  # Use the shared nix-secrets module on this host.
  nix-secrets = {
    enable = true;
    identityPaths = [ "/home/anas/.nix-secrets/keys.txt" ];
    recipientAliases.anas = "age124py20nfzyj0mxrvd8y06qqppm4xvqm4xl2emeg56pc9afefgglqn6wpzj"; # public key
  };
  # Networking
  networking.hostName = "Mayuri";
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

  networking.interfaces.enp7s0.ipv4.addresses = [{
    address = "192.168.1.2";
    prefixLength = 24;
  }];

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # OpenVPN HTTP proxy container.
  ovpn-proxy = {
    enable = false;
    externalInterface = "enp7s0";
    configSecret = "openvpn/mayuri/config";
    usernameSecret = "openvpn/mayuri/username";
    passwordSecret = "openvpn/mayuri/password";
    credentialsTemplate = "openvpn/mayuri/credentials";

    # MagicDNS resolves the bare name `mayuri` to this Tailscale address.
    extraLoopbackIPs = [ "100.126.74.4" ];
  };

  # I2P router (i2pd) container. Create the encrypted secrets below, then set
  # both enable flags to true to start the router and publish the site.
  i2p-router = {
    enable = false;
    externalInterface = "enp7s0";
    extraLoopbackIPs = [ "100.126.74.4" ];
    console.passwordSecret = "i2p/mayuri/console/password";
    sites.blog = {
      enable = false;
      port = 8080;
      keySecret = "i2p/mayuri/sites/blog/keys";
    };
  };

  # Tor container. Create the onion key secret below, then enable the router
  # and the site to publish it.
  tor-router = {
    enable = false;
    externalInterface = "enp7s0";
    extraLoopbackIPs = [ "100.126.74.4" ];
    sites.blog = {
      enable = false;
      port = 8080;
      targetPort = 8080;
      keySecret = "tor/mayuri/sites/blog/keys";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  gpu = {
    nvidia = {
      enable = true;
      isTuring = false; # https://en.wikipedia.org/wiki/Turing_(microarchitecture)#Products_using_Turing
    };
    intel.enable = false;
    amd.enable = false;
  };
  gpu.nvidia.enableCUDA = true;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true; # Set to false if using SSH keys only
    };
  };

  # Tha audio server
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    # Disable timer-based scheduling to fix stutter on bluetooth usb hardware
    extraConfig = ''
      load-module module-udev-detect tsched=0
    '';
  };

  # A gui/tray to manage the bluetooth
  services.blueman.enable = true;
}
