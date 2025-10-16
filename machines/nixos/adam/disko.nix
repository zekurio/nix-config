# Disko configuration for adam
# This provides declarative disk partitioning for easy deployment
{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Change this to match your actual disk device (e.g., /dev/nvme0n1, /dev/sda)
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
      
      # SATA drive for downloads and transcoding cache
      cache = {
        type = "disk";
        # Update this to your SATA device path (e.g., /dev/sdb)
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            cache = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/cache";
                mountOptions = [ "defaults" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
