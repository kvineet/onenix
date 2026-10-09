{ ... }:

{
  users.users.immich.uid = 980;
  users.groups.immich.gid = 980;

  boot.supportedFilesystems = [ "nfs" ];

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    mediaLocation = "/mnt/photos/immich";
    openFirewall = false;
    settings.server.externalDomain = "https://immich.kvineet.in";
  };

  fileSystems."/mnt/photos" = {
    device = "10.100.0.1:/photos";
    fsType = "nfs4";
    options = [
      "rw"
      "vers=4.1"
      "_netdev"
      "noauto"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.mount-timeout=30s"
      "x-systemd.requires=wireguard-peer-tardis.service"
    ];
  };

  systemd.services.immich-server = {
    after = [ "mnt-photos.mount" ];
    requires = [ "mnt-photos.mount" ];
    unitConfig.RequiresMountsFor = [ "/mnt/photos/immich" ];
  };
}
