{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
    ../../../overlays
    ../../../modules/nixos/common.nix
  ];

  # Boot configuration
  boot = {
    kernelParams = [
      "pcie_aspm=force"
      "consoleblank=60"
      "acpi_enforce_resources=lax"
    ];
    kernelModules = [
      "kvm-amd"
      "k10temp"
    ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vpl-gpu-rt
      ];
    };
  };

  # Networking configuration
  networking = {
    hostName = "adam";
    useDHCP = true;
    networkmanager.enable = false;
  };

  fileSystems."/mnt/fast-nvme" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  services = {
    openssh.enable = true;
    autoaspm.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
      group = "zekurio";
    };
  };

  # Add jellyfin user to zekurio group for media access
  users.groups.zekurio.members = [ "jellyfin" ];

  # Create required directories with proper ownership
  systemd.tmpfiles.rules = [
    "d /var/cache/downloads 0775 zekurio zekurio -"
    "d /var/cache/downloads/completed 0775 zekurio zekurio -"
    "d /var/cache/downloads/completed/sonarr 0775 zekurio zekurio -"
    "d /var/cache/downloads/completed/radarr 0775 zekurio zekurio -"
    "d /var/cache/downloads/completed/torrent 0775 zekurio zekurio -"
    "d /var/cache/downloads/converted 0775 zekurio zekurio -"
    "d /var/cache/downloads/converted/sonarr 0775 zekurio zekurio -"
    "d /var/cache/downloads/converted/radarr 0775 zekurio zekurio -"
    "d /var/cache/downloads/incomplete 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/anime 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/movies 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/music 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/tv 0775 zekurio zekurio -"
  ];

  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.jellyfin
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.jellyfin-web
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.jellyfin-ffmpeg
  ];

  virtualisation = {
    containers.enable = true;
    podman = {
      dockerCompat = true;
      autoPrune.enable = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    oci-containers.backend = "podman";
  };

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade.enable = true;

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
