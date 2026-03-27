{ pkgs, mypkgs, ... }:
{
  home.packages = [
    pkgs.cloudflared
  ];
  programs.ssh = {
    matchBlocks = {
      "ssh.kvineet.in" = {
        user = "azureuser";
        match = ''host ssh.kvineet.in exec "${pkgs.cloudflared}/bin/cloudflared access ssh-gen --hostname %h"'';
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
        identityFile = "~/.cloudflared/%h-cf_key";
        certificateFile = "~/.cloudflared/%h-cf_key-cert.pub";
      };
    };
  };
}
