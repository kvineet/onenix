{
  pkgs,
  pkgs-unstable,
  globals,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    ../common/home.nix
    ../../features/utils/ledger
    ../../features/devtools
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [ ];
    # Configure your nixpkgs instance
    config = { };
  };
  home.packages = with pkgs; [
    kdePackages.kate
    kdePackages.kdenlive
    vscode-fhs
    yt-dlp
    # stremio
    stremio-linux-shell
    mpv
    telegram-desktop
    nicotine-plus
    openttd-jgrpp
    pkgs-unstable.oscar
    bottles
    obsidian
    google-chrome
    zoom-us
  ];

  programs.zsh.zsh-abbr.abbreviations = {
    rebuild = "sudo nixos-rebuild --flake ${globals.dirs.dotdir}#pc switch";
    hm = "home-manager switch --flake ${globals.dirs.dotdir}#pc";
  };
}
