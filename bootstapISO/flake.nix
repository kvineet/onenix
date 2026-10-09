{
  description = "Headless NixOS installer ISO for nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
  {
    nixosConfigurations.installer =
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./installer.nix
        ];
      };
  };
}
