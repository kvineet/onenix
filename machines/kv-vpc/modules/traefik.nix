{ globals, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      accessLog = {
        filePath = "/var/lib/traefik/access.log";
        format = "json";
        bufferingSize = 0;
        filters.statusCodes = [
          "401"
          "403"
        ];
      };
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        websecure.address = ":443";
      };
      certificatesResolvers.letsencrypt.acme = {
        email = "kvineet.in@gmail.com";
        storage = "/var/lib/traefik/acme.json";
        httpChallenge.entryPoint = "web";
      };
    };
    dynamicConfigOptions.http = {
      routers.immich = {
        rule = "Host(\"immich.${globals.domain}\")";
        entryPoints = [ "websecure" ];
        service = "immich";
        tls.certResolver = "letsencrypt";
      };
      services.immich.loadBalancer.servers = [
        { url = "http://127.0.0.1:2283"; }
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "f /var/lib/traefik/access.log 0640 traefik traefik -"
  ];
}
