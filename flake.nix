{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
      globals = {
        username = "kvineet";
        winUser = "vinekulkarni";
        name = "Vineet Kulkarni";
        dirs = {
          downloads = "/home/${globals.username}/Downloads";
          webdav = "/srv/webDav";
          dirs.config = "/home/${globals.username}/";
          dotdir = "/home/${globals.username}/projects/onenix";
        };
      };
    in
    {
      nixosConfigurations.seedbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./machines/seedbox/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            home-manager.users.${globals.username} = ./machines/seedbox/home.nix;
          }
        ];
      };
      nixosConfigurations.pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # TODO disko.nixosModules.disko
          ./machines/pc/configuration.nix
          # TODO sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${globals.username} = ./machines/pc/home.nix;
            home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            home-manager.extraSpecialArgs = { inherit globals; };
          }
        ];
      };
    };
}
