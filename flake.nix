{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
    nixgl.url = "github:nix-community/nixGL";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-wsl,
      flatpaks,
      nixgl,
      home-manager,
      plasma-manager,
      disko,
      nixos-facter-modules,
      sops-nix,
      ...
    }@inputs:
    let
      # overlays = [ nixgl.overlay ];
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      globals = {
        username = "kvineet";
        winUser = "vinekulkarni";
        name = "Vineet Kulkarni";
        domain = "kvineet.in";
        dirs = {
          downloads = "/home/${globals.username}/Downloads";
          webdav = "/srv/webDav";
          dirs.config = "/home/${globals.username}";
          dotdir = "/home/${globals.username}/projects/onenix";
        };
      };
      helpers = import ./lib/helpers.nix {
        lib = nixpkgs.lib;
        inherit globals home-manager pkgs-unstable system;
        inherit nixpkgs nixos-wsl;
      };
    in
    {
      nixosConfigurations = {
        kv-vpc = helpers.mkNixos [
          disko.nixosModules.disko
          ./machines/kv-vpc/configuration.nix
        ];
        tardis = helpers.mkNixos (
          [
            disko.nixosModules.disko
            ./machines/tardis/configuration.nix
          ] ++ (helpers.mkHomeManager {
            home = ./machines/tardis/home.nix;
          })
        );
        seedbox = helpers.mkNixos [
          disko.nixosModules.disko
          ./machines/seedbox/configuration.nix
          sops-nix.nixosModules.sops
        ];
        msft = helpers.mkWslNixos (
          [
            ./machines/msft/configuration.nix
            # TODO sops-nix.nixosModules.sops
          ] ++ (helpers.mkHomeManager {
            home = ./machines/msft/home.nix;
          })
        );
        pc = helpers.mkNixos (
          [
            disko.nixosModules.disko
            ./machines/pc/configuration.nix
            # TODO sops-nix.nixosModules.sops
          ] ++ (helpers.mkHomeManager {
            home = ./machines/pc/home.nix;
            sharedModules = [ plasma-manager.homeModules.plasma-manager ];
          })
        );
      };
    };
}
