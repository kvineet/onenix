{
  pkgs,
  globals,
  ...
}:
{
  home.packages = [
    pkgs.cloudflared
  ];
  programs.ssh = {
    settings = {
      "ssh.${globals.domain}" = {
        user = "azureuser";
        match = ''host ssh.${globals.domain}" exec "${pkgs.cloudflared}/bin/cloudflared access ssh-gen --hostname %h"'';
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
        identityFile = "~/.cloudflared/%h-cf_key";
        certificateFile = "~/.cloudflared/%h-cf_key-cert.pub";
      };
      "kv-vpc.${globals.domain}" = {
        user = "${globals.username}";
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      };
    };
  };
}
