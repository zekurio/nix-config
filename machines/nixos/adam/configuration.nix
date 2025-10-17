{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
    ../../../overlays
    ../../../modules/services/jellyfin.nix
    ../../../modules/services/navidrome.nix
    ../../../modules/services/vaultwarden.nix
    ../../../modules/services/caddy.nix
    ../../../modules/services/sonarr.nix
    ../../../modules/services/radarr.nix
    ../../../modules/services/prowlarr.nix
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

  # DNS over TLS with Cloudflare
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  # Enable firewall (ports configured in service modules)
  networking.firewall.enable = true;

  fileSystems."/mnt/fast-nvme" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.wireguard_private_key = {
      mode = "0400";
    };
  };

  services = {
    openssh.enable = true;
    autoaspm.enable = true;

    # Enable wrapped services with Caddy integration
    jellyfin-wrapped.enable = true;
    navidrome-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
  };

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
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "*-*-* 03:00:00";
    randomizedDelaySec = "1h";
    flake = "github:zekurio/nix-config";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
