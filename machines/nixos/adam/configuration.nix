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
    ../../../modules/services/sabnzbd.nix
    ../../../modules/services/jellyseerr.nix
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
  networking.firewall.allowedTCPPorts = [ 8096 19200 ];


  fileSystems."/mnt/fast-nvme" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    autoaspm.enable = true;

    # Enable wrapped services with Caddy integration
    jellyfin-wrapped.enable = false;  # Using container instead
    navidrome-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;
    jellyseerr-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
    sabnzbd-wrapped.enable = true;

    # Caddy reverse proxy for Jellyfin container
    caddy-wrapper.virtualHosts."jellyfin-container" = {
      domain = "schnitzelflix.xyz";
      reverseProxy = "localhost:8096";
    };
  };

  # Create required directories with proper ownership
  systemd.tmpfiles.rules = [
    # Downloads directories on root drive (for transcoding before moving to NVMe)
    "d /var/downloads 0775 zekurio zekurio -"
    "d /var/downloads/completed 0775 zekurio zekurio -"
    "d /var/downloads/completed/sonarr 0775 zekurio zekurio -"
    "d /var/downloads/completed/radarr 0775 zekurio zekurio -"
    "d /var/downloads/completed/torrent 0775 zekurio zekurio -"
    "d /var/downloads/incomplete 0775 zekurio zekurio -"
    # Media directories on NVMe
    "z /mnt/fast-nvme/media 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/anime 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/movies 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/music 0775 zekurio zekurio -"
    "z /mnt/fast-nvme/media/tv 0775 zekurio zekurio -"
    # Podman directories
    "d /var/lib/containers/jellyfin 0775 zekurio zekurio -"
    "d /var/cache/containers/jellyfin 0775 zekurio zekurio -"
    "d /var/lib/containers/fileflows/data 0775 zekurio zekurio -"
    "d /var/lib/containers/fileflows/logs 0775 zekurio zekurio -"
    "d /tmp/fileflows 0775 zekurio zekurio -"
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
    oci-containers.containers = {
      jellyfin = {
        image = "jellyfin/jellyfin:10.11.0-rc9";
        autoStart = true;
        user = "1000:1000";
        ports = [ "8096:8096" ];

        volumes = [
          "/mnt/fast-nvme/media:/media"
          "/var/lib/containers/jellyfin:/config"
          "/var/cache/containers/jellyfin:/cache"
        ];

        extraOptions = [
          "--device=/dev/dri:/dev/dri"
        ];
      };

      fileflows = {
        image = "revenz/fileflows:latest";
        autoStart = true;
        ports = [ "19200:5000" ];

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock:ro"
          "/var/downloads:/downloads"
          "/var/lib/containers/fileflows/data:/app/Data"
          "/var/lib/containers/fileflows/logs:/app/Logs"
          "/tmp/fileflows:/temp"
        ];

        environment = {
          "TempPathHost" = "/tmp/fileflows";
          "PUID" = "1000";
          "PGID" = "1000";
        };

        extraOptions = [
          "--device=/dev/dri:/dev/dri"
        ];
      };
    };
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
