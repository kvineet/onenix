{
  inputs,
  lib,
  config,
  pkgs,
  mypkgs,
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
    vscode-fhs
  ];
  programs.zsh.zsh-abbr.abbreviations = {
    hm = "home-manager switch --flake ${globals.dirs.dotdir}#pc";
  };
}
