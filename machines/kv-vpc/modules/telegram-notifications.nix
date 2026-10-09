{
  lib,
  pkgs,
  ...
}:
let
  shoutrrrTelegramUrlFile = "/var/lib/shoutrrr/telegram-url";
  monitoredServices = [
    "babybuddy-image-update"
    "cloud-init"
    "cloudflared-kv-vpc"
    "docker"
    "docker-babybuddy"
    "fail2ban"
    "firehol-level1-update"
    "firewall"
    "immich-machine-learning"
    "immich-server"
    "postgresql"
    "redis-immich"
    "syncthing"
    "syncthing-init"
    "traefik"
    "waagent"
    "wireguard-key"
    "wireguard-peer-tardis"
  ];
  notifyServiceFailure = pkgs.writeShellApplication {
    name = "notify-service-failure";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hostname
      pkgs.shoutrrr
      pkgs.systemd
    ];
    text = ''
      unit="''${1:?systemd unit name is required}"
      credential="''${CREDENTIALS_DIRECTORY:?}/telegram-url"
      host="$(hostname --fqdn 2>/dev/null || hostname)"
      result="$(systemctl show "$unit" --property=Result --value 2>/dev/null || true)"
      active_state="$(systemctl show "$unit" --property=ActiveState --value 2>/dev/null || true)"
      sub_state="$(systemctl show "$unit" --property=SubState --value 2>/dev/null || true)"
      exit_code="$(systemctl show "$unit" --property=ExecMainStatus --value 2>/dev/null || true)"
      timestamp="$(date --iso-8601=seconds)"

      message="$(
        printf 'Host: %s\nUnit: %s\nResult: %s\nState: %s/%s\nExit status: %s\nTime: %s' \
          "$host" \
          "$unit" \
          "''${result:-unknown}" \
          "''${active_state:-unknown}" \
          "''${sub_state:-unknown}" \
          "''${exit_code:-unknown}" \
          "$timestamp"
      )"

      shoutrrr send \
        --url "$(cat "$credential")" \
        --title "systemd service failure" \
        --message "$message"
    '';
  };
in
{
  systemd.services = lib.mkMerge [
    {
      "telegram-notify@" = {
        description = "Send a Telegram alert for failed unit %I";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = shoutrrrTelegramUrlFile;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe notifyServiceFailure} %I";
          LoadCredential = "telegram-url:${shoutrrrTelegramUrlFile}";
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };
      };
    }
    (lib.genAttrs monitoredServices (_: {
      unitConfig.OnFailure = [ "telegram-notify@%n.service" ];
    }))
  ];
}
