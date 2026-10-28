{ config
, lib
, pkgs
, ...
}:
let
  openvpnSecretsEnabled =
    config.nix-secrets.enable
    && config.nix-secrets.secrets."openvpn/config".enable
    && config.nix-secrets.secrets."openvpn/username".enable
    && config.nix-secrets.secrets."openvpn/password".enable;
in
{
  config = lib.mkIf openvpnSecretsEnabled {
    # NAT for the container's private veth pair and the host-side port forward.
    networking.nat = {
      enable = true;
      internalIPs = [ "10.234.0.0/24" ];
      externalInterface = "enp7s0";
      forwardPorts = [
        {
          sourcePort = 7777;
          destination = "10.234.0.2:8080";
          proto = "tcp";

          # Also allow the host itself to use the proxy on 7777. Without this
          # the port forward only applies to traffic arriving on enp7s0.
          loopbackIPs = [ "127.0.0.1" "192.168.1.2" ];
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 7777 ];

    containers.ovpn-proxy = {
      autoStart = true;
      privateNetwork = true;

      # Gives the container CAP_NET_ADMIN and /dev/net/tun, like the Docker
      # service's `cap_add: NET_ADMIN` and `devices: /dev/net/tun`.
      enableTun = true;

      hostAddress = "10.234.0.1";
      localAddress = "10.234.0.2";

      # Only expose the OpenVPN material to this container. nix-secrets exposes
      # the decrypted files as symlinks, so bind-mount the individual files
      # (nspawn follows the symlink on the host side) rather than /run itself.
      bindMounts = {
        "/var/lib/ovpn-proxy-config.ovpn" = {
          hostPath = config.security.nix-secrets.secrets."openvpn/config".path;
          isReadOnly = true;
        };
        "/var/lib/ovpn-proxy-credentials" = {
          hostPath = config.security.nix-secrets.templates."openvpn/credentials".path;
          isReadOnly = true;
        };
      };

      config =
        { lib, pkgs, ... }:
        {
          system.stateVersion = "26.05";

          networking = {
            useHostResolvConf = lib.mkForce false;
            nameservers = [ "1.1.1.1" "1.0.0.1" ];

            # Reply to LAN clients through the host. Without this, replies to
            # clients behind the host's port-forward would follow the VPN's
            # default route (the Docker image does the same with LOCAL_NETWORK).
            interfaces.eth0.ipv4.routes = [
              {
                address = "192.168.1.0";
                prefixLength = 24;
                via = "10.234.0.1";
              }
            ];

            firewall = {
              enable = true;
              allowedTCPPorts = [ 8080 ];
            };
          };

          # ProtonVPN configs ship with a bare `auth-user-pass` line. Strip it and
          # let services.openvpn append the credentials file supplied by nix-secrets.
          systemd.services.openvpn-proton.preStart = ''
            ${pkgs.coreutils}/bin/install -d -m 0700 /run/openvpn
            ${pkgs.gnused}/bin/sed -E '/^[[:space:]]*auth-user-pass/d' \
              /var/lib/ovpn-proxy-config.ovpn \
              > /run/openvpn/config.ovpn
            ${pkgs.coreutils}/bin/chmod 0600 /run/openvpn/config.ovpn
          '';

          services.openvpn.servers.proton = {
            config = "config /run/openvpn/config.ovpn";
            authUserPass = "/var/lib/ovpn-proxy-credentials";
            autoStart = true;
          };

          services.privoxy = {
            enable = true;
            settings = {
              listen-address = "0.0.0.0:8080";
              debug = 1;
            };
          };

          # Wait for the tunnel before accepting proxy traffic.
          systemd.services.privoxy = {
            after = [ "openvpn-proton.service" ];
            wants = [ "openvpn-proton.service" ];
          };
        };
    };
  };
}
