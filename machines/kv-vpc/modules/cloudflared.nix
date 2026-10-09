{
  lib,
  pkgs,
  ...
}:
let
  cloudflaredTokenFile = "/var/lib/cloudflared/tunnel-token";
in
{
  systemd.services.cloudflared-kv-vpc = {
    description = "Cloudflare Tunnel for kv-vpc";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = cloudflaredTokenFile;
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      LoadCredential = "tunnel-token:${cloudflaredTokenFile}";
      ExecStart = "${lib.getExe pkgs.cloudflared} tunnel --no-autoupdate run --token-file %d/tunnel-token";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  environment.systemPackages = [ pkgs.cloudflared ];
}
