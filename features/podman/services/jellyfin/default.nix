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
        "in.kvineet.seedbox.torrent.service" = "jellyfin";
      };
      hostname = "jellyfin";
    };
  };
}
