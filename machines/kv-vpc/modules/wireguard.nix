{
  lib,
  pkgs,
  ...
}:
let
  wireguardInterface = "wg0";
  wireguardPort = 51820;
  wireguardPrivateKeyFile = "/var/lib/wireguard/private.key";
  wireguardPublicKeyFile = "/var/lib/wireguard/public.key";
  tardisPublicKeyFile = "/var/lib/wireguard/peers/tardis.public";
in
{
  networking = {
    firewall = {
      allowedUDPPorts = [ wireguardPort ];
      interfaces.${wireguardInterface}.allowedTCPPorts = [ 22 ];
    };
    wireguard.interfaces.${wireguardInterface} = {
      ips = [ "10.100.0.2/24" ];
      listenPort = wireguardPort;
      privateKeyFile = wireguardPrivateKeyFile;
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd.services = {
    wireguard-key = {
      description = "Generate the WireGuard keypair";
      wantedBy = [ "multi-user.target" ];
      before = [ "systemd-networkd.service" ];
      requiredBy = [ "systemd-networkd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      script = ''
        install -d -m 0700 "$(dirname ${lib.escapeShellArg wireguardPrivateKeyFile})"
        if [[ ! -s ${lib.escapeShellArg wireguardPrivateKeyFile} ]]; then
          ${lib.getExe pkgs.wireguard-tools} genkey > ${lib.escapeShellArg wireguardPrivateKeyFile}
        fi
        ${lib.getExe pkgs.wireguard-tools} pubkey \
          < ${lib.escapeShellArg wireguardPrivateKeyFile} \
          > ${lib.escapeShellArg wireguardPublicKeyFile}
      '';
    };

    wireguard-peer-tardis = {
      description = "Configure the Tardis WireGuard peer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      partOf = [ "systemd-networkd.service" ];
      unitConfig.ConditionPathExists = tardisPublicKeyFile;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${lib.getExe pkgs.wireguard-tools} set ${wireguardInterface} \
          peer "$(cat ${lib.escapeShellArg tardisPublicKeyFile})" \
          allowed-ips 10.100.0.1/32,192.168.68.0/24
        ${lib.getExe' pkgs.iproute2 "ip"} route replace \
          192.168.68.0/24 dev ${wireguardInterface}
      '';
    };
  };

  environment.systemPackages = [ pkgs.wireguard-tools ];
}
