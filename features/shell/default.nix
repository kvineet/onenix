{ pkgs, ... }:
{
  imports = [
    ./xdg
    ./zsh
    ./git
    ./lsd
  ];

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      withRuby = false;
      withPython3 = false;
    };
  };
  home = {
    packages = with pkgs; [
      shellcheck
      up
      htop
    ];
  };
}
