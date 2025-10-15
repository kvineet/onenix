{
  config,
  lib,
  pkgs,
  globals,
  ...
}@args:
{
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.age
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
      # TODO: change this to your ssh key
    ];
  };

  programs.zsh.enable = true;
  programs.nano.enable = false;
  programs.neovim = {
    defaultEditor = true;
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
