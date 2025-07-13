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
    ../common/configuration.nix
    ../../features/podman
    ../../features/podman/services/jellyfin
    ../../features/podman/services/torrent
    ../../features/podman/services/home-assistant
  ];
  boot.loader.systemd-boot.enable = true;
  services.openssh.enable = true;

  virtualisation.virtualbox.guest.enable = true;

  fileSystems."/srv/webDav" = {
    device = "webDav";
    fsType = "vboxsf";
    options = [
      "nofail"
    ];
  };

  system.stateVersion = "24.05";
}
