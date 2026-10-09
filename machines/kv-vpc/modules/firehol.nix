{
  lib,
  pkgs,
  ...
}:
let
  fireholLevel1Url = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset";
  fireholAllowlist = [
    "10.100.0.0/24"
    "10.200.0.0/16"
    "192.168.68.0/24"
  ];
  updateFireholLevel1 = pkgs.writeShellApplication {
    name = "update-firehol-level1";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gawk
      pkgs.gnugrep
      pkgs.ipset
    ];
    text = ''
      download="$(mktemp)"
      entries="$(mktemp)"
      next_set="firehol_level1_next"

      cleanup() {
        rm -f "$download" "$entries"
        ipset destroy "$next_set" 2>/dev/null || true
      }
      trap cleanup EXIT

      curl \
        --fail \
        --location \
        --proto '=https' \
        --retry 3 \
        --retry-all-errors \
        --silent \
        --show-error \
        --output "$download" \
        ${lib.escapeShellArg fireholLevel1Url}

      tr -d '\r' < "$download" |
        grep -Ev '^(#|[[:space:]]*$)' > "$entries"

      entry_count="$(wc -l < "$entries")"
      if (( entry_count < 1000 )); then
        echo "Refusing FireHOL update with only $entry_count entries" >&2
        exit 1
      fi

      if grep -Evq '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$' "$entries"; then
        echo "Refusing FireHOL update containing malformed entries" >&2
        exit 1
      fi

      ipset destroy "$next_set" 2>/dev/null || true
      ipset create "$next_set" hash:net family inet hashsize 8192 maxelem 131072
      awk -v set="$next_set" '{ print "add " set " " $0 }' "$entries" |
        ipset restore

      ipset create firehol_level1 hash:net family inet hashsize 8192 maxelem 131072 -exist
      ipset swap "$next_set" firehol_level1
      install -m 0644 "$download" /var/lib/firehol-blocklist/firehol_level1.netset
    '';
  };
in
{
  networking.firewall = {
    extraPackages = [ pkgs.ipset ];
    extraCommands = ''
      ipset create firehol_level1 hash:net family inet hashsize 8192 maxelem 131072 -exist
      ipset create firehol_allow hash:net family inet hashsize 1024 maxelem 4096 -exist
      ipset flush firehol_allow
      ${lib.concatMapStringsSep "\n" (
        cidr: "ipset add firehol_allow ${lib.escapeShellArg cidr} -exist"
      ) fireholAllowlist}
      iptables -C nixos-fw \
        -m set --match-set firehol_level1 src \
        -m set ! --match-set firehol_allow src \
        -p tcp -m multiport --dports 80,443 \
        -j DROP 2>/dev/null ||
        iptables -I nixos-fw 1 \
          -m set --match-set firehol_level1 src \
          -m set ! --match-set firehol_allow src \
          -p tcp -m multiport --dports 80,443 \
          -j DROP
    '';
  };

  systemd.services.firehol-level1-update = {
    description = "Update the FireHOL Level 1 blocklist";
    after = [
      "firewall.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "firewall.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe updateFireholLevel1;
      StateDirectory = "firehol-blocklist";
      StateDirectoryMode = "0750";
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.timers.firehol-level1-update = {
    description = "Periodically update the FireHOL Level 1 blocklist";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
      RandomizedDelaySec = "10min";
      Persistent = true;
    };
  };
}
