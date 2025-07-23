{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
