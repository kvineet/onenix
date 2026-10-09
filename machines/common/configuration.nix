{
  config,
  lib,
  pkgs,
  globals,
  modulesPath,
  ...
}@args:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.age
    pkgs.nfs-utils
  ];
  users.users.kvineet = {
    isNormalUser = true;
    description = "kvineet";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9cZDQjzlmMTw2PStQMWlk+XbLfP4KMKeKM3C9izsyf kvineet@kvineet-pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINkEmmoJ9hJXfbHL/mFjxbWKIwPGoB/dhL5TyQGe8Cr MSFT_kvineet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdGV58h+hnSpPOr3EcaQqD0W2Ss4oRwZ8oeua9QVAsG"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  programs.zsh.enable = true;
  programs.nano.enable = false;
  programs.neovim = {
    defaultEditor = true;
    enable = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
