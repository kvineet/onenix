{
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.systemd-boot.enable = true;
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.neovim
    pkgs.git
  ];

  virtualisation.virtualbox.guest.enable = true;

  fileSystems."/srv/webDav" = {
    device = "webDav";
    fsType = "vboxsf";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9cZDQjzlmMTw2PStQMWlk+XbLfP4KMKeKM3C9izsyf kvineet@kvineet-pc"
  ] ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed

  system.stateVersion = "24.05";
}
