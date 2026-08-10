{ pkgs, ... }: {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      ubuntu-classic
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      hack-font
      nerd-fonts.hack
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
}
