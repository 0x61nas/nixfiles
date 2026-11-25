{ lib
, pkgs
, pkgs-unstable
, inputs
, localHostName
, ...
}:
let
  nodes = inputs.self.nixosConfigurations;
  hostNames = builtins.attrNames nodes;

  # Prefer the router on this machine, then fall back to other hosts in name
  # order. PAC tries proxies left to right.
  orderedHosts =
    lib.optionals (builtins.elem localHostName hostNames) [ localHostName ]
    ++ builtins.filter (host: host != localHostName) hostNames;

  i2pEnabled = host: nodes.${host}.config.i2p-router.enable or false;
  torEnabled = host: nodes.${host}.config.tor-router.enable or false;

  i2pHosts = builtins.filter i2pEnabled orderedHosts;
  torHosts = builtins.filter torEnabled orderedHosts;

  proxy = kind: host:
    let
      node = nodes.${host}.config;
      address = if host == localHostName then "127.0.0.1" else host;
      port = if kind == "i2p" then node.i2p-router.httpProxy.port else node.tor-router.socks.port;
      scheme = if kind == "i2p" then "PROXY" else "SOCKS5";
    in
    "${scheme} ${address}:${toString port}";

  chain = kind: hosts: lib.concatStringsSep "; " (map (proxy kind) hosts) + "; DIRECT";

  pacEnabled = i2pHosts != [ ] || torHosts != [ ];

  pacFile = pkgs.writeText "firefox-proxy.pac" ''
    function FindProxyForURL(url, host) {
    ${lib.optionalString (torHosts != [ ]) ''    if (dnsDomainIs(host, ".onion")) return "${chain "tor" torHosts}";''}
    ${lib.optionalString (i2pHosts != [ ]) ''    if (dnsDomainIs(host, ".i2p")) return "${chain "i2p" i2pHosts}";''}
      return "DIRECT";
    }
  '';
in
{
  programs.firefox = {
    enable = true;
    package = pkgs-unstable.firefox;
    # Keep using the legacy profile location, the current profile lives in
    # `~/.mozilla/firefox` and not in the XDG config home.
    configPath = ".mozilla/firefox";
    languagePacks = [
      "ar"
      "en-US"
      "ja"
      "ka"
    ];

    profiles.default = {
      # Generated from every host's router config. With no router enabled
      # anywhere Firefox stays on direct connections.
      settings =
        if pacEnabled then {
          "network.proxy.type" = 2; # automatic proxy configuration
          "network.proxy.autoconfig_url" = "file://${toString pacFile}";
        } else {
          "network.proxy.type" = 0; # no proxy
        };

      # everything in the set.
      #extensions.packages = pkgs.firefox-addons.all;

      # …or a hand-picked list.
      extensions.packages = with pkgs.firefox-addons; [
        ublock-origin
        foxytab
        keepassxc-browser
        sponsorblock
        single-file
        auto-tab-discard
        control-panel-for-twitter
        material-icons-for-github
        crxviewer
        pixiv-toolkit
        privacy-extension-for-whatsapp
        readeck
        styl-us
        tab-session-manager
        besttimetracker # Track time, analyze your habits and block addictive sites
        traduzir-paginas-web # Translate your page in real time using Google, Bing or Yandex.
        youtube-recommended-videos # Hide YouTube related videos, comments, video suggestions wall, homepage recommendations, trending tab, and other distractions.
        wayback-machine_new # Wayback Machine
        gruvbox-dark-theme
      ];
    };
  };
}
