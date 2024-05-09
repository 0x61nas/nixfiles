{ pkgs, pkgs-unstable, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/default.nix
  ];

  fonts.fontDir.enable = true;
  # desktop.hyprland.enable = true;

  gpu = {
    nvidia.enable = true;
    #intel.enable = false;
  };

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
  workarounds.pulseaudio-mic-boost.enable = true;

  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = true;
  programs.dconf.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.virt-manager.enable = true;

  users.mutableUsers = false;

  users.users.anas = {
    isNormalUser = true;
    description = "am the problem its me";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    shell = pkgs.zsh;
    initialPassword = "kill me plz";
    packages = with pkgs; [
       #sxhkd
       #sxiv
       #xorg.xinit
       #nitrogen
      #zsh-autosuggestions
      #zsh-syntax-highlighting
      #zsh-history-substring-search
      #zsh-you-should-use
      #oh-my-posh
      #dmenu-rs
      #keepassxc
      #pavucontrol
      #jellyfin
      #jellycli
      #jellyfin-web
     ];
  };

  services.xserver = {
	layout = "us,ara";
	  xkbVariant = "dvorak-l,";
	  xkbOptions = "grp:win_space_toggle caps:swapescape keypad:pointerkeys";
  };

  console = {
     font = "Lat2-Terminus16";
    # keyMap = "us";
     useXkbConfig = true; # use xkb.options in tty.
   };

  environment.systemPackages = with pkgs; [
    cachix
    coreutils-full
    home-manager
    docker

    neovim
    ripgrep
    git
    eza
    networkmanagerapplet
    tmux
    zoxide
    gdb
    gnumake
    killall
    zathura
    wget
   
    brave
    firefox
    #(pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true;}) {})
    vlc
    keepassxc
    unzip
    zip
    farbfeld
    ffmpeg

    rustup
    gcc

    ntfs3g

    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    #mtpfs

  ] ++ (with pkgs-unstable; [
    qbittorrent
    nvtopPackages.intel
    nvtopPackages.nvidia
    btop
  ]);

   #----=[ Fonts ]=----#
fonts = {
  enableDefaultPackages = true;
  packages = with pkgs; [ 
    ubuntu_font_family
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    hack-font
    nerdfonts
    jetbrains-mono
  ];

  fontconfig = {
    defaultFonts = {
      serif = [ "Hack Font" "Ubuntu" ];
      sansSerif = [ "Hack Font" "Ubuntu" ];
      monospace = [ "Ubuntu" ];
    };
  };
};

  services.jellyfin.enable = true;

  #security.sudo-rs.enable = true;
  # she was sudo girl, ama doas boy :(
  security.doas.enable = true;
  security.sudo.enable = false;
  security.doas.extraRules = [{
     users = ["anas"];
	  # Optional, retains environment variables while running commands 
	  # e.g. retains your NIX_PATH when applying your config
	  keepEnv = true; 
	  persist = true;  # Optional, only require password verification a single time
	}];

   environment.variables = {
	     EDITOR = "nvim";
	     TERMINAL = "st";
	     PAGER = "less";
	     SUDO = "doas";
	    BROWSER="firefox";
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

  system.stateVersion = "23.11";
  system.autoUpgrade.enable = true;

  nixpkgs.config.allowUnfree = true;
  

   environment.sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      # This improves touchscreen support and enables additional touchpad gestures. 
      # It also enables smooth scrolling as opposed to the stepped scrolling that Firefox has by default.
      MOZ_USE_XINPUT2 = "1"; 
    };

    services.printing.enable = true;
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      #media-session.enable = true; # default for now, no need to change
    };

    qt.enable = true;
    qt.platformTheme = "gtk2";
    qt.style = "gtk2";


  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      auto-optimise-store = true;
      sandbox = "relaxed";
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}