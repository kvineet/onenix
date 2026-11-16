{ lib, ... }:
{
  disko.devices = {
    disk = {
      nvme = {
        device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2425E8B9E8DB";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      storage = {
        device = "/dev/disk/by-id/ata-ST2000DM005-2CW102_WFL02ML8";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            bag = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/BagOfHoldings";
              };
            };
          };
        };
      };
    };
  };
}
