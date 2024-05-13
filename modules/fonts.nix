{ pkgs, ... }: {
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
}
