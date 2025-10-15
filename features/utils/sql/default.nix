{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # ...various
    sqlcmd
  ];
}
