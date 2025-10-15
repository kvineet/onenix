{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # ...various
      dejavu_fonts
      powerline-fonts
      noto-fonts
      noto-fonts-emoji-blob-bin
      iosevka-bin
    ];
  fonts.fontconfig.enable = true;

}
