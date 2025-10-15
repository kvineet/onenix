{ globals, pkgs, ... }:
{
  home.packages = with pkgs;
    [
    ];
  services = {
    syncthing = {
      enable = true;
    };
  };
}
