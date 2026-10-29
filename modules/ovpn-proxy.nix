{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.ovpn-proxy;

  interfaceAddresses =
    config.networking.interfaces.${cfg.externalInterface}.ipv4.addresses or [ ];

  firstInterfaceAddress =
    if interfaceAddresses == [ ] then
      throw ''
        ovpn-proxy: networking.interfaces.${toString cfg.externalInterface}.ipv4.addresses
        is empty. Set ovpn-proxy.lanAddress and ovpn-proxy.lanPrefixLength explicitly.
      ''
    else
      builtins.head interfaceAddresses;

  lanAddress =
    if cfg.lanAddress != null then cfg.lanAddress else firstInterfaceAddress.address;

  lanPrefixLength =
    if cfg.lanPrefixLength != null then cfg.lanPrefixLength else firstInterfaceAddress.prefixLength;

  ipv4ToInt = address:
    lib.foldl'
      (acc: octet: acc * 256 + lib.toInt octet)
      0
      (lib.splitString "." address);

  intToIpv4 = value:
    let
      a = value / 16777216;
      b = value / 65536 - a * 256;
      c = value / 256 - a * 65536 - b * 256;
      d = value - a * 16777216 - b * 65536 - c * 256;
    in
    "${toString a}.${toString b}.${toString c}.${toString d}";

  maskOctetTable = [ 0 128 192 224 240 248 252 254 255 ];

  maskOctets =
    let
      fullOctets = lanPrefixLength / 8;
      remainder = lanPrefixLength - fullOctets * 8;
    in
    lib.genList
      (index:
        if index < fullOctets then 255
        else if index == fullOctets then builtins.elemAt maskOctetTable remainder
        else 0
      )
      4;

  lanNetworkAddress = intToIpv4 (
    lib.bitAnd
      (ipv4ToInt lanAddress)
      (ipv4ToInt (lib.concatMapStringsSep "." toString maskOctets))
  );

  secretEnabled = name: config.nix-secrets.secrets.${name}.enable or false;

  credentialsAvailable =
    config.nix-secrets.enable
    && secretEnabled cfg.usernameSecret
    && secretEnabled cfg.passwordSecret;

  secretsAvailable =
    credentialsAvailable && secretEnabled cfg.configSecret;

  containerReady =
    cfg.enable
    && cfg.externalInterface != null
    && secretsAvailable;

  openvpnService = "openvpn-${cfg.openvpnServer}";
in
{
  options.ovpn-proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run the OpenVPN + Privoxy proxy container on this host.";
    };

    externalInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "enp7s0";
      description = ''
        Host network interface connected to the LAN. Its first IPv4 address is
        used as the default LAN address and as the interface for NAT and the
        port forward.
      '';
    };

    lanAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.1.2";
      description = ''
        Address LAN clients use to reach this proxy. Defaults to the first IPv4
        address of externalInterface.
      '';
    };

    lanPrefixLength = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 24;
      description = ''
        Prefix length of the LAN. Defaults to the prefix length of the first
        IPv4 address of externalInterface.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7777;
      description = "TCP port exposed on the host for the HTTP proxy.";
    };

    proxyPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "TCP port Privoxy listens on inside the container.";
    };

    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.234.0.1";
      description = "Host-side address of the private container network.";
    };

    localAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.234.0.2";
      description = "Container-side address of the private container network.";
    };

    network = lib.mkOption {
      type = lib.types.str;
      default = "10.234.0.0/24";
      description = "Private container network in CIDR notation, used for NAT.";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1.1.1.1" "1.0.0.1" ];
      description = "DNS servers used inside the container.";
    };

    loopbackIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "127.0.0.1" "127.0.0.2" lanAddress ];
      description = ''
        Addresses that may use the forwarded port locally. Defaults to
        127.0.0.1, the hostname address 127.0.0.2, and the host's LAN address.
      '';
    };

    extraLoopbackIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "100.64.0.1" ];
      description = ''
        Additional addresses appended to loopbackIPs, such as a Tailscale
        address used by MagicDNS to resolve this host's name.
      '';
    };

    openvpnServer = lib.mkOption {
      type = lib.types.str;
      default = "proton";
      description = "Name of the OpenVPN systemd service inside the container.";
    };

    configSecret = lib.mkOption {
      type = lib.types.str;
      default = "openvpn/config";
      description = "nix-secrets secret containing the .ovpn configuration.";
    };

    usernameSecret = lib.mkOption {
      type = lib.types.str;
      default = "openvpn/username";
      description = "nix-secrets secret containing the OpenVPN username.";
    };

    passwordSecret = lib.mkOption {
      type = lib.types.str;
      default = "openvpn/password";
      description = "nix-secrets secret containing the OpenVPN password.";
    };

    credentialsTemplate = lib.mkOption {
      type = lib.types.str;
      default = "openvpn/credentials";
      description = "nix-secrets template containing the OpenVPN credentials file.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || cfg.externalInterface != null;
          message = "ovpn-proxy.enable requires ovpn-proxy.externalInterface.";
        }
        {
          assertion = !cfg.enable || secretsAvailable;
          message = ''
            ovpn-proxy is enabled, but its secrets are not available on this host.
            Enable nix-secrets and make sure ${cfg.configSecret},
            ${cfg.usernameSecret} and ${cfg.passwordSecret} are enabled.
          '';
        }
      ];
    }

    # Declare the secrets on hosts that use the container. Secrets are
    # host-specific, so they are not declared in the shared module.
    (lib.mkIf cfg.enable {
      nix-secrets.secrets = {
        "${cfg.configSecret}" = { };
        "${cfg.usernameSecret}" = { };
        "${cfg.passwordSecret}" = { };
      };
    })

    (lib.mkIf (cfg.enable && credentialsAvailable) {
      nix-secrets.templates."${cfg.credentialsTemplate}".content = ''
        ${config.security.nix-secrets.secrets.${cfg.usernameSecret}}
        ${config.security.nix-secrets.secrets.${cfg.passwordSecret}}
      '';
    })

    (lib.mkIf containerReady {
      # NAT for the container's private veth pair and the host-side port forward.
      networking.nat = {
        enable = true;
        internalIPs = [ cfg.network ];
        externalInterface = cfg.externalInterface;
        forwardPorts = [
          {
            sourcePort = cfg.port;
            destination = "${cfg.localAddress}:${toString cfg.proxyPort}";
            proto = "tcp";

            # Also allow the host itself and the extra addresses (for example
            # the Tailscale/MagicDNS address) to use the proxy. Without this
            # the port forward only applies to traffic arriving on the LAN
            # interface.
            loopbackIPs = cfg.loopbackIPs ++ cfg.extraLoopbackIPs;
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      containers.ovpn-proxy = {
        autoStart = true;
        privateNetwork = true;

        # Gives the container CAP_NET_ADMIN and /dev/net/tun, like the Docker
        # service's `cap_add: NET_ADMIN` and `devices: /dev/net/tun`.
        enableTun = true;

        inherit (cfg) hostAddress localAddress;

        # Only expose the OpenVPN material to this container. nix-secrets
        # exposes the decrypted files as symlinks, so bind-mount the individual
        # files (nspawn follows the symlink on the host side) rather than
        # /run itself.
        bindMounts = {
          "/var/lib/ovpn-proxy-config.ovpn" = {
            hostPath = config.security.nix-secrets.secrets.${cfg.configSecret}.path;
            isReadOnly = true;
          };
          "/var/lib/ovpn-proxy-credentials" = {
            hostPath = config.security.nix-secrets.templates.${cfg.credentialsTemplate}.path;
            isReadOnly = true;
          };
        };

        config =
          { lib, pkgs, ... }:
          {
            system.stateVersion = "26.05";

            networking = {
              useHostResolvConf = lib.mkForce false;
              nameservers = cfg.dns;

              # Reply to LAN clients through the host. Without this, replies to
              # clients behind the host's port-forward would follow the VPN's
              # default route (the Docker image does the same with LOCAL_NETWORK).
              interfaces.eth0.ipv4.routes = [
                {
                  address = lanNetworkAddress;
                  prefixLength = lanPrefixLength;
                  via = cfg.hostAddress;
                }
              ];

              firewall = {
                enable = true;
                allowedTCPPorts = [ cfg.proxyPort ];
              };
            };

            # ProtonVPN configs ship with a bare `auth-user-pass` line. Strip it
            # and let services.openvpn append the credentials file supplied by
            # nix-secrets.
            systemd.services."${openvpnService}".preStart = ''
              ${pkgs.coreutils}/bin/install -d -m 0700 /run/openvpn
              ${pkgs.gnused}/bin/sed -E '/^[[:space:]]*auth-user-pass/d' \
                /var/lib/ovpn-proxy-config.ovpn \
                > /run/openvpn/config.ovpn
              ${pkgs.coreutils}/bin/chmod 0600 /run/openvpn/config.ovpn
            '';

            services.openvpn.servers.${cfg.openvpnServer} = {
              config = "config /run/openvpn/config.ovpn";
              authUserPass = "/var/lib/ovpn-proxy-credentials";
              autoStart = true;
            };

            services.privoxy = {
              enable = true;
              settings = {
                listen-address = "0.0.0.0:${toString cfg.proxyPort}";
                debug = 1;
              };
            };

            # Wait for the tunnel before accepting proxy traffic.
            systemd.services.privoxy = {
              after = [ "${openvpnService}.service" ];
              wants = [ "${openvpnService}.service" ];
            };
          };
      };
    })
  ];
}
