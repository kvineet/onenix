{
  inputs,
  lib,
  config,
  pkgs,
  globals,
  ...
}:
{
  imports = [
    ../../features/shell
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "${globals.username}";
    homeDirectory = "/home/${globals.username}";
  };

  programs.home-manager.enable = true;
  home = {
    stateVersion = "23.05";
    packages = with pkgs; [
      rar
      fzf
      jq
      yq-go
    ];
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        compression = false;
        addKeysToAgent = "no";
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
