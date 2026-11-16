{
  lib,
  pkgs,
  globals,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.age
    pkgs.nfs-utils
  ];
  users.users.${globals.username} = {
    isNormalUser = true;
    description = "${globals.username}";
    shell = pkgs.zsh;
    extraGroups = [
      "uinput"
      "video"
      "render"
      "input"
      "wheel"
      "networkmanager"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDB7inOqeP6sIoEAAjoIt2+T8ymCBHtqdcGjppim6zI8 vineet.kulkarni8@gmail.com"
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
