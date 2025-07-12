{
  config,
  lib,
  pkgs,
  ...
}@args:
{

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.neovim
    pkgs.git
  ];
  programs.zsh.enable = true;
  users.users.kvineet = {
    isNormalUser = true;
    hashedPasswordFile = "../../.local/kvineet.pwd";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9cZDQjzlmMTw2PStQMWlk+XbLfP4KMKeKM3C9izsyf kvineet@kvineet-pc"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9cZDQjzlmMTw2PStQMWlk+XbLfP4KMKeKM3C9izsyf kvineet@kvineet-pc"
  ] ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed

}
