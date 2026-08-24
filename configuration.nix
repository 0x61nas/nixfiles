{ pkgs, pkgs-unstable, ... }:
{
  imports = [
    ./modules
    ./gui/thunar.nix
  ];

  fonts.fontDir.enable = true;
  # desktop.hyprland.enable = true;

  # Firmware update helper
  # https://nixos.wiki/wiki/Fwupd
  services.fwupd.enable = true;

  services.flatpak.enable = false;
  # services.flatpak.packages = [
  #   "hu.kramo.Cartridges"
  #   "com.github.tchx84.Flatseal"
  #   "com.valvesoftware.Steam"
  #   "net.davidotek.pupgui2" # protonUp-qt
  #   # "com.brave.Browser"
  #   "net.lutris.Lutris"
  # ];
  # workarounds.flatpak.enable = true;

  programs.zsh.enable = true;
  # I don't use ohMyZsh, but it doses provide a some convenient functions.
  programs.zsh.ohMyZsh.enable = true;
  programs.dconf.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.virt-manager.enable = true;

  users.mutableUsers = false;

  users.users.anas = {
    isNormalUser = true;
    description = "am the problem its me";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "video"
      "audio"
      "tty"
      "anas"
    ];
    shell = pkgs.zsh;
    initialPassword = "kill me plz";
  };

  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  environment.systemPackages =
    with pkgs;
    [
      cachix
      coreutils-full
      docker

      ripgrep
      git
      (eza.override {
        gitSupport = false;
      })
      networkmanagerapplet
      tmux
      gdb
      gnumake
      killall
      zathura
      wget
      fzf
      file
      usbutils

      # firefox
      (pkgs.wrapFirefox (firefox-unwrapped.override { pipewireSupport = true; }) { })
      keepassxc
      unzip
      zip
      farbfeld
      ffmpeg
      cmus

      llvmPackages.clang-unwrapped
      llvmPackages.bintools
      rustup
      gcc
      python3
      just

      ntfs3g

      #mtpfs
      # notification daemon
      dunst
      libnotify

    ]
    ++ (with pkgs-unstable; [
      neovim
      qbittorrent
      nvtopPackages.full
      btop
    ]);

  #security.sudo-rs.enable = true;
  # she was sudo girl, ama doas boy :(
  security.doas.enable = true;
  security.sudo.enable = false;
  security.doas.extraRules = [
    {
      users = [ "anas" ];
      # Optional, retains environment variables while running commands
      # e.g. retains your NIX_PATH when applying your config
      keepEnv = true;
      persist = true; # Optional, only require password verification a single time
    }
  ];

  environment.variables = {
    EDITOR = "nvim";
    TERMINAL = "st";
    PAGER = "less";
    SUDO = "doas";
    BROWSER = "firefox";
    NAME = "Anas Elgarhy";
    USERNAME = "0x61nas";
    EMAIL = "anas.elgarhy.dev@gmail.com";
    # Globals
    TZ = "Africa/Cairo";
    # make less better
    # X = leave content on-screen
    # F = quit automatically if less than one screenfull
    # R = raw terminal characters (fixes git diff)
    #     see http://jugglingbits.wordpress.com/2010/03/24/a-better-less-playing-nice-with-git/
    LESS = "-F -X -R";
    # Rust stuff
    CARGO_INCREMENTAL = "1";
    RUSTFLAGS = "-C target-cpu=native";
    RUST_BACKTRACE = "1";
  };

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = true;

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    # This improves touchscreen support and enables additional touchpad gestures.
    # It also enables smooth scrolling as opposed to the stepped scrolling that Firefox has by default.
    #MOZ_USE_XINPUT2 = "1";
    # WEBKIT_DISABLE_COMPOSITING_MODE essential in NVIDIA + compositor https://github.com/NixOS/nixpkgs/issues/212064#issuecomment-1400202079
    WEBKIT_DISABLE_COMPOSITING_MODE = "1";
  };

  services.keyd = {
    enable = true;
    keyboards = {
      # The name is just the name of the configuration file, it does not really matter
      default = {
        ids = [ "*" ]; # what goes into the [id] section, here we select all keyboards
        # Everything but the ID section:
        settings = {
          # The main layer, if you choose to declare it in Nix
          main = {
            esc = "capslock";
            # Maps capslock to escape when pressed and control when held.
            capslock = "overload(control, esc)";
            control = "oneshot(control)";
            meta = "oneshot(meta)";
            shift = "oneshot(shift)";
            leftalt = "oneshot(alt)";
          };
          otherlayer = { };
        };
        extraConfig = ''
                    # put here any extra-config, e.g. you can copy/paste here directly a configuration, just remove the ids part
                    [control]
                    control = toggle(control)

                    [meta]
                    meta = toggle(meta)

                    [shift]
                    shift = toggle(shift)

                    [alt]
                    leftalt = toggle(alt)
        '';
      };
    };
  };
  # Optional, but makes sure that when you type the make palm rejection work with keyd
  # https://github.com/rvaiya/keyd/issues/723
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';

  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
    #media-session.enable = true; # default for now, no need to change
  };

  services.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";

  nix = {
    package = pkgs-unstable.nixVersions.latest;
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    # };
    settings = {
      auto-optimise-store = true;
      sandbox = "relaxed";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  programs.nh = {
    enable = true;
    package = pkgs-unstable.nh;
    # clean.enable = true;
    # clean.extraArgs = "--keep-since 5month --keep 6";
    flake = "/home/anas/nixfiles";
  };
}
