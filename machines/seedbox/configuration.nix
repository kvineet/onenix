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
    ../common/configuration-beta.nix
    ../../features/podman
    ../../features/podman/services/cloudflare
    # ../../features/podman/services/jellyfin
    ../../features/services/jellyfin.nix
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
      "uid=1000"
      "gid=1000"
    ];
  };
  powerManagement.enable = false;
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
  system.stateVersion = "24.05";
}
