{
  config,
  lib,
  pkgs,
  ...
}:
let
  commonEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "Asia/Kolkata";
    LANGUAGE = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
  };
in
{
  virtualisation.oci-containers.containers = {
    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:develop";
      ports = [ "13369:9696" ];
      autoStart = true;
      environment = commonEnv;
      volumes = [
        "/root/Downloads/torrents/watch:/downloads"
        "/root/torrent/prowlarr:/config"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "prowlarr";
      };
      hostname = "prowlarr";
    };
    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      ports = [ "13381:7878" ];
      autoStart = true;
      environment = commonEnv;
      volumes = [
        "/root/Downloads/torrents:/downloads"
        "/root/torrent/radarr:/config"
        "/srv/webDav/:/webDav"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "radarr";
      };
      hostname = "radarr";
    };
    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      ports = [ "13382:8989" ];
      autoStart = true;
      environment = commonEnv // {
        SONARR_BRANCH = "main";
      };
      volumes = [
        "/root/Downloads/torrents:/downloads"
        "/root/torrent/sonarr:/config"
        "/srv/webDav/:/webDav"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "sonarr";
      };
      hostname = "sonarr";
    };
    transmission = {
      image = "lscr.io/linuxserver/transmission:latest";
      ports = [ "13371:9091" ];
      autoStart = true;
      environment = commonEnv // {
        # TRANSMISSION_WEB_HOME = "/config/themes/flood-for-transmission/";
      };
      volumes = [
        "/root/Downloads/torrents:/downloads"
        "/root/torrent/transmission:/config"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "transmission";
      };
      hostname = "transmission";
    };
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = [ "13370:8191" ];
      autoStart = true;
      environment = commonEnv // {
        LOG_LEVEL = "INFO";
      };
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "flaresolverr";
      };
      hostname = "flaresolverr";
    };
  };
  systemd.tmpfiles.rules = [
    "d /root/torrents/transmission 1777 root root"
    "d /root/torrents/prowlarr 1777 root root"
    "d /root/torrents/sonarr 1777 root root"
    "d /root/torrents/radarr 1777 root root"
  ];
}
