{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "docker.io/linuxserver/jellyfin:latest";
      autoStart = true;
      ports = [ "13385:8096" ];
      volumes = [
        "/root/Jellyfin:/config"
        "/srv/webDav:/data/content"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "jellyfin";
      };
      hostname = "jellyfin";
    };
  };
  systemd.tmpfiles.rules = [
    "d /root/Jellyfin 1777 root root"
  ];
}
