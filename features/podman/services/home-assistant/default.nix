{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.oci-containers.containers = {
    home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      volumes = [
        "/root/home-assistant:/config"
        "/run/dbus:/run/dbus:ro"
      ];
      ports = [ "8123:8123" ];
      extraOptions = [
        "--network=host"
        "--cap-add=CAP_NET_RAW"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "home-assistant";
      };
      hostname = "homeassistant";
    };
  };
  systemd.tmpfiles.rules = [
    "d /root/home-assistant 1777 root root"
  ];
  networking.firewall = {
    allowedTCPPorts = [
      8123
    ];
  };
}
