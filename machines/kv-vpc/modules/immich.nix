{ ... }:

{
  users.users.immich.uid = 980;
  users.groups.immich.gid = 980;

  boot.supportedFilesystems = [ "nfs" ];

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    mediaLocation = "/datadisk/immich";
    openFirewall = false;
    settings.server.externalDomain = "https://immich.kvineet.in";
  };

  fileSystems = {
    "/mnt/photos" = {
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

    "/datadisk/immich/library" = {
      device = "/mnt/photos/library";
      fsType = "none";
      options = [
        "bind"
        "x-systemd.requires-mounts-for=/mnt/photos"
      ];
    };

    "/datadisk/immich/ext-library" = {
      device = "/mnt/photos/ext-library";
      fsType = "none";
      options = [
        "bind"
        "x-systemd.requires-mounts-for=/mnt/photos"
      ];
    };

    "/datadisk/immich/thumbs" = {
      device = "/mnt/photos/thumbs";
      fsType = "none";
      options = [
        "bind"
        "x-systemd.requires-mounts-for=/mnt/photos"
      ];
    };

    "/datadisk/immich/encoded-video" = {
      device = "/mnt/photos/encoded-video";
      fsType = "none";
      options = [
        "bind"
        "x-systemd.requires-mounts-for=/mnt/photos"
      ];
    };
  };

  systemd.services.immich-server = {
    unitConfig.RequiresMountsFor = [
      "/datadisk/immich"
      "/datadisk/immich/library"
      "/datadisk/immich/ext-library"
      "/datadisk/immich/thumbs"
      "/datadisk/immich/encoded-video"
    ];
  };
}
