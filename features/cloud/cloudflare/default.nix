{ pkgs, mypkgs, ... }:
{
  home.packages = [
    pkgs.cloudflared
  ];
  programs.ssh.extraConfig = ''
    Match Host ssh.kvineet.in exec "${pkgs.cloudflared}/bin/cloudflared access ssh-gen --hostname %h"
          User azureuser
          ProxyCommand ${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h
          IdentityFile ~/.cloudflared/%h-cf_key
          CertificateFile ~/.cloudflared/%h-cf_key-cert.pub
  '';
}
