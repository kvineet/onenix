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
      globals = {
        username = "kvineet";
        winUser = "vinekulkarni";
        name = "Vineet Kulkarni";
        dirs = {
          downloads = "/home/${globals.username}/Downloads";
          webdav = "/srv/webDav";
          dirs.config = "/home/${globals.username}";
          dotdir = "/home/${globals.username}/projects/onenix";
        };
      };
      mkNixos = modules: nixpkgs.lib.nixosSystem { inherit system modules; };
      mkHomeManager =
        {
          home,
          extraSpecialArgs ? { },
          sharedModules ? [ ],
          useGlobalPkgs ? false,
        }:
        {
          home-manager = {
            inherit extraSpecialArgs sharedModules useGlobalPkgs;
            useUserPackages = true;
            users.${globals.username} = home;
          };
        };
    in
    {
      nixosConfigurations = {
        kv-vpc = mkNixos [
          disko.nixosModules.disko
          ./machines/kv-vpc/configuration.nix
        ];
        tardis = mkNixos [
          disko.nixosModules.disko
          ./machines/tardis/configuration.nix
        ];
        seedbox = mkNixos [
          disko.nixosModules.disko
          ./machines/seedbox/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          (mkHomeManager {
            home = ./machines/seedbox/home.nix;
            useGlobalPkgs = true;
            sharedModules = [ plasma-manager.homeModules.plasma-manager ];
          })
        ];
        msft = mkNixos [
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "26.05";
            wsl = {
              enable = true;
              defaultUser = "${globals.username}";
              docker-desktop.enable = true;
              wslConf = {
                user.default = "${globals.username}";
              };
            };
          }
          ./machines/msft/configuration.nix
          # TODO sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          (mkHomeManager {
            home = ./machines/msft/home.nix;
            extraSpecialArgs = { inherit globals; };
          })
        ];
        pc = mkNixos [
          # TODO disko.nixosModules.disko
          ./machines/pc/configuration.nix
          # TODO sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          (mkHomeManager {
            home = ./machines/pc/home.nix;
            sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            extraSpecialArgs = { inherit globals; };
          })
        ];
      };
    };
}
