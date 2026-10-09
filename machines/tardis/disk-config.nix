{ ... }:
let
  # Replace all four placeholders with the machine's stable /dev/disk/by-id paths.
  # Applying disko in destroy/format mode ERASES all four selected disks.
  disks = {
    system = "/dev/disk/by-id/ata-WDC_WDS240G2G0A-00JH30_184442805877";
    cache = "/dev/disk/by-id/ata-KINGSTON_SV300S37A120G_50026B774607207A";
    hdd1 = "/dev/disk/by-id/ata-ST4000VN006-3CW104_WW6B2A6P";
    hdd2 = "/dev/disk/by-id/ata-ST4000VN006-3CW104_WW6B4ED4";
  };

  mkStorageDisk = device: {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      partitions.zfs = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "tank";
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      system = {
        device = disks.system;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
      hdd1 = mkStorageDisk disks.hdd1;
      hdd2 = mkStorageDisk disks.hdd2;
      cache = mkStorageDisk disks.cache;
    };

    zpool = {
      rpool = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          mountpoint = "none";
          canmount = "off";
        };
        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
        };
      };

      tank = {
        type = "zpool";
        # Members refer to disko disk names and their partitions named "zfs".
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "mirror";
                members = [ "hdd1" "hdd2" ];
              }
            ];
            # L2ARC read cache only, not a data, special, or SLOG vdev.
            cache = [ "cache" ];
          };
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          mountpoint = "none";
          canmount = "off";
        };
        datasets = {
          photos = {
            type = "zfs_fs";
            mountpoint = "/srv/photos";
            options.mountpoint = "legacy";
          };
          public = {
            type = "zfs_fs";
            mountpoint = "/srv/public";
            options.mountpoint = "legacy";
          };
          nas = {
            type = "zfs_fs";
            mountpoint = "/srv/nas";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}