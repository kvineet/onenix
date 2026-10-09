{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/azure-common.nix"
    ./disk-config.nix
    ../common/configuration.nix
    ./modules/babybuddy.nix
    ./modules/cloudflared.nix
    ./modules/fail2ban.nix
    ./modules/firehol.nix
    ./modules/immich.nix
    ./modules/syncthing.nix
    ./modules/telegram-notifications.nix
    ./modules/traefik.nix
    ./modules/wireguard.nix
  ];

  users.users.kvineet.uid = 1000;

  networking.hostName = "kv-vpc";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  system.stateVersion = "26.05";
}
