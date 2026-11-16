{
  lib,
  globals,
  home-manager,
  nixpkgs,
  nixos-wsl,
  pkgs-unstable,
  system,
}:
let
  self = {
    revDomainNotation =
      builtins.concatStringsSep "."
        (lib.reverseList (lib.splitString "." globals.domain));

    mkNixos =
      modules:
      nixpkgs.lib.nixosSystem {
        inherit system modules;
        specialArgs = {
          inherit globals pkgs-unstable;
          helpers = self;
        };
      };

    mkWslNixos =
      modules:
      self.mkNixos (
        [
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "26.05";
            wsl = {
              enable = true;
              defaultUser = globals.username;
              docker-desktop.enable = true;
              wslConf = {
                user.default = globals.username;
              };
            };
          }
        ] ++ modules
      );

    mkHomeManager =
      {
        home,
        extraSpecialArgs ? {
          inherit globals pkgs-unstable;
          helpers = self;
        },
        sharedModules ? [ ],
        useGlobalPkgs ? false,
      }:
      [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            inherit extraSpecialArgs sharedModules useGlobalPkgs;
            useUserPackages = true;
            users.${globals.username} = home;
          };
        }
      ];
  };
in
self
