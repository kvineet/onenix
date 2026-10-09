{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking.hostName = "nixos";

  networking.useDHCP = lib.mkDefault true;

  isoImage.volumeID = "NIXOS_LIVE";
  boot.zfs.forceImportRoot = false;

  ########################################
  # SSH
  ########################################

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      PermitRootLogin = "prohibit-password";
    };
  };

  ########################################
  # Preload SSH key
  ########################################

  users.users.nixos.openssh.authorizedKeys.keys = [
    (builtins.readFile ./id_ed25519.pub)
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./id_ed25519.pub)
  ];

  ########################################
  # mDNS
  ########################################

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  ########################################
  # Helpful utilities
  ########################################

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
    vim
    tmux
    htop
    lsof
    rsync
  ];

  ########################################
  # Nice login banner
  ########################################

  environment.etc."issue".text = ''
    =====================================
           Headless NixOS Installer
    =====================================

    SSH:

      ssh root@nixos.local

    or

      ssh root@<ip-address>

    =====================================
  '';
}
