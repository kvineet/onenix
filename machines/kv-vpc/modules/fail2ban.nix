{ ... }:

{
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    maxretry = 10;
    ignoreIP = [
      "10.100.0.0/24"
      "10.200.0.0/16"
      "192.168.68.0/24"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "24h";
      overalljails = true;
    };
    jails.traefik-auth = {
      filter.Definition = {
        failregex = ''^(?=.*"ClientHost":"<HOST>")(?=.*"DownstreamStatus":(?:401|403)(?:,|})).*$'';
        ignoreregex = "";
      };
      settings = {
        backend = "auto";
        logpath = "/var/lib/traefik/access.log";
        port = "http,https";
        protocol = "tcp";
        findtime = "10m";
      };
    };
  };
}
