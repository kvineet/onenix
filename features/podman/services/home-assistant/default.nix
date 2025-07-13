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
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      pull = "always";
      labels = {
        "in.kvineet.seedbox.service" = "home-assistant";
      };
      hostname = "homeassistant";
    };
  };

}
