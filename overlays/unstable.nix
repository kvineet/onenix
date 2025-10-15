{ config, pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import nixpkgs-unstable {
        inherit (final) system config;
      };
    })
  ];
}