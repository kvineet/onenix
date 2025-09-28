{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.cloudflared = {
    enable = true;
    path = [ pkgs.cloudflared ];
    wants = [
      "network-online.target"
      "nss-lookup.target"
    ];
    before = [
      "nss-lookup.target"
    ];
    serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
      DynamicUser = "yes";
      EnvironmentFile = "/root/.config/tunnel.env";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run";
    };
    wantedBy = [
      "multi-user.target"
    ];
  };
}
