{
  config,
  lib,
  pkgs,
  globals,
  ...
}:
let
  updateBabybuddyImage = pkgs.writeShellApplication {
    name = "update-babybuddy-image";
    runtimeInputs = [
      config.virtualisation.docker.package
      pkgs.systemd
    ];
    text = ''
      image="lscr.io/linuxserver/babybuddy:latest"
      old_id="$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null || true)"

      docker pull "$image"

      new_id="$(docker image inspect --format '{{.Id}}' "$image")"
      if [[ -z "$new_id" ]]; then
        echo "Pulled image has no image ID" >&2
        exit 1
      fi

      if [[ "$old_id" == "$new_id" ]]; then
        echo "Baby Buddy image is already current: $new_id"
        exit 0
      fi

      echo "Baby Buddy image changed from ''${old_id:-missing} to $new_id"
      systemctl restart docker-babybuddy.service
    '';
  };
in
{
  systemd.services = {
    babybuddy-image-update = {
      description = "Update the Baby Buddy container image";
      after = [
        "docker.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe updateBabybuddyImage;
      };
    };

    docker-babybuddy.serviceConfig.Restart = lib.mkForce "always";
  };

  systemd.timers.babybuddy-image-update = {
    description = "Check daily for a new Baby Buddy container image";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "2h";
      AccuracySec = "5min";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/babybuddy 0750 ${globals.username} users -"
  ];

  virtualisation = {
    docker.enable = true;
    oci-containers = {
      backend = "docker";
      containers.babybuddy = {
        image = "lscr.io/linuxserver/babybuddy:latest";
        autoStart = true;
        pull = "always";
        hostname = "babybuddy";
        ports = [ "127.0.0.1:8000:8000" ];
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Asia/Kolkata";
          CSRF_TRUSTED_ORIGINS = "http://127.0.0.1:8000,https://babybuddy.${globals.username}";
        };
        volumes = [ "/var/lib/babybuddy:/config" ];
      };
    };
  };
}
