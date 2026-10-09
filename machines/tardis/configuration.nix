{
  config,
  lib,
  pkgs,
  ...
}:
let
  cloudflareCredentialsFile = "/var/lib/cloudflare-ddns/credentials.env";
  localInterface = "enp3s0";
  localNetwork = "192.168.68.0/24";
  wireguardInterface = "wg0";
  wireguardPort = 51820;
  wireguardPrivateKeyFile = "/var/lib/wireguard/private.key";
  wireguardPublicKeyFile = "/var/lib/wireguard/public.key";
  kvVpcPublicKeyFile = "/var/lib/wireguard/peers/kv-vpc.public";
  kvVpcEndpointFile = "/var/lib/wireguard/peers/kv-vpc.endpoint";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  users.users.kvineet.uid = 1000;
  users.users.immich = {
    uid = 980;
    group = "immich";
    isSystemUser = true;
  };
  users.groups.immich.gid = 980;

  boot = {
    kernel.sysctl."net.ipv4.ip_forward" = 1;
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "tardis";
    hostId = "7a4d1f20";
    firewall = {
      allowedUDPPorts = [ wireguardPort ];
      interfaces.${localInterface}.allowedTCPPorts = [ 2049 ];
      interfaces.${wireguardInterface}.allowedTCPPorts = [ 2049 ];
    };
    nat = {
      enable = true;
      externalInterface = localInterface;
      internalInterfaces = [ wireguardInterface ];
    };
    wireguard.interfaces.${wireguardInterface} = {
      ips = [ "10.100.0.1/24" ];
      listenPort = wireguardPort;
      privateKeyFile = wireguardPrivateKeyFile;

    };
  };

  systemd.services.wireguard-key = {
    description = "Generate the WireGuard keypair";
    wantedBy = [ "multi-user.target" ];
    before = [ "wireguard-${wireguardInterface}.service" ];
    requiredBy = [ "wireguard-${wireguardInterface}.service" ];
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

  systemd.services.wireguard-peer-kv-vpc = {
    description = "Configure the kv-vpc WireGuard peer";
    wantedBy = [ "multi-user.target" ];
    after = [ "wireguard-${wireguardInterface}.service" ];
    requires = [ "wireguard-${wireguardInterface}.service" ];
    partOf = [ "wireguard-${wireguardInterface}.service" ];
    unitConfig.ConditionPathExists = [
      kvVpcPublicKeyFile
      kvVpcEndpointFile
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${lib.getExe pkgs.wireguard-tools} set ${wireguardInterface} \
        peer "$(cat ${lib.escapeShellArg kvVpcPublicKeyFile})" \
        endpoint "$(cat ${lib.escapeShellArg kvVpcEndpointFile})" \
        allowed-ips 10.100.0.2/32,10.200.0.0/16 \
        persistent-keepalive 25
        ${lib.getExe' pkgs.iproute2 "ip"} route replace \
          10.200.0.0/16 dev ${wireguardInterface}
    '';
  };

  systemd.services.nfs-server.unitConfig.RequiresMountsFor = [
    "/srv/photos"
    "/srv/public"
    "/srv/nas"
  ];

  systemd.tmpfiles.rules = [
    "d /srv/photos 2775 kvineet users -"
    "d /srv/photos/immich 0700 immich immich -"
  ];

  systemd.services.cloudflare-ddns.unitConfig.ConditionPathExists = cloudflareCredentialsFile;

  environment.systemPackages = [ pkgs.wireguard-tools ];

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    cloudflare-ddns = {
      enable = true;
      credentialsFile = cloudflareCredentialsFile;
      domains = [ "tardis.kvineet.in" ];
      proxied = "false";
      ttl = 300;
      updateCron = "@every 5m";
      updateOnStart = true;
    };
    nfs.server = {
      enable = true;
      exports = ''
        /srv ${localNetwork}(rw,sync,no_subtree_check,root_squash,fsid=0,crossmnt,insecure)
        /srv 10.100.0.0/24(rw,sync,no_subtree_check,root_squash,fsid=0,crossmnt)
      '';
    };
    nfs.settings.nfsd.vers3 = false;
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        MaxAuthTries = 3;
        X11Forwarding = false;
      };
    };
    zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim.enable = true;
    };
  };

  system.stateVersion = "26.05";
}