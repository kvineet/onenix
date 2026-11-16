{
  pkgs,
  pkgs-unstable,
  globals,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    ../minimal/home.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [ ];
    # Configure your nixpkgs instance
    config = { };
  };
  home.packages = with pkgs; [
  ];

  programs.zsh.zsh-abbr.abbreviations = {
    rebuild = "sudo nixos-rebuild --flake ${globals.dirs.dotdir}#tardis switch";
    hm = "home-manager switch --flake ${globals.dirs.dotdir}#tardis";
  };
}
