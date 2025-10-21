{ config, pkgs, modulesPath, lib, ... }:

let
  # Media service group for shared access to library files
  mediaGroup = "media";
  mediaUser = "zekurio";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../../../modules/home-manager
    ../../../overlays
    ../../../modules/homelab/podman.nix
    ../../../modules/homelab/services/jellyfin.nix
    ../../../modules/homelab/services/navidrome.nix
    ../../../modules/homelab/services/vaultwarden.nix
    ../../../modules/homelab/services/caddy.nix
    ../../../modules/homelab/services/sonarr.nix
    ../../../modules/homelab/services/radarr.nix
    ../../../modules/homelab/services/lidarr.nix
    ../../../modules/homelab/services/prowlarr.nix
    ../../../modules/homelab/services/sabnzbd.nix
    ../../../modules/homelab/services/jellyseerr.nix
    ../../../modules/homelab/services/autobrr.nix
    ../../../modules/homelab/services/qbittorrent.nix
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
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 8096 19200 ];
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

  # NVMe media drive - existing partition, not managed by disko
  fileSystems."/mnt/fast-nvme" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" "nodiratime" ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      mullvad-wg = { };
      autobrr-secret = { };
    };
  };

  # Nix configuration
  nixpkgs.config.allowUnfree = true;
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkForce "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
    };
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
    lidarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
    sabnzbd-wrapped.enable = true;
    autobrr-wrapped.enable = true;

    # qBittorrent with VPN confinement
    qbittorrent-wrapped.enable = true;

    # Caddy reverse proxy for Jellyfin container
    caddy-wrapper.virtualHosts."jellyfin-container" = {
      domain = "schnitzelflix.xyz";
      reverseProxy = "localhost:8096";
    };
  };

  # Podman containers
  virtualisation.podman-homelab = {
    enable = true;
    jellyfin.enable = true;
    fileflows.enable = true;
    configarr.enable = true;
  };

  # VPN namespace configuration for qBittorrent
  vpnNamespaces.mullvad = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.mullvad-wg.path;
    accessibleFrom = [
      "192.168.0.0/16"  # Adjust to your local network
    ];
    portMappings = [
      { from = 8080; to = 8080; }  # qBittorrent WebUI
    ];
    openVPNPorts = [
      { port = 6881; protocol = "both"; }  # qBittorrent incoming connections
    ];
  };

  # Confine qBittorrent to VPN namespace
  systemd.services.qbittorrent = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "mullvad";
    };
    serviceConfig = {
      SupplementaryGroups = [ mediaGroup ];
    };
  };

  # Create media group for shared access
  users.groups.${mediaGroup} = {};

  # Add main user to media group
  users.users.${mediaUser}.extraGroups = [ mediaGroup ];

  # Add qBittorrent user to media group with proper UMask for shared downloads
  users.users.qbittorrent.extraGroups = [ mediaGroup ];
  systemd.services.qbittorrent.serviceConfig.UMask = lib.mkForce "0002";

  # Create required directories with proper ownership
  systemd.tmpfiles.rules = [
    # qBittorrent state directory
    "d /var/lib/qBittorrent 0775 qbittorrent ${mediaGroup} -"
    # Arr services state directories
    "d /var/lib/sonarr 0775 sonarr ${mediaGroup} -"
    "d /var/lib/sonarr/.config 0775 sonarr ${mediaGroup} -"
    "d /var/lib/radarr 0775 radarr ${mediaGroup} -"
    "d /var/lib/radarr/.config 0775 radarr ${mediaGroup} -"
    "d /var/lib/lidarr 0775 lidarr ${mediaGroup} -"
    "d /var/lib/lidarr/.config 0775 lidarr ${mediaGroup} -"
    # Downloads directories on root drive (for transcoding before moving to NVMe)
    "d /var/downloads 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/completed 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/completed/sonarr 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/completed/radarr 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/completed/torrent 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/converted 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/converted/sonarr 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/converted/radarr 0775 ${mediaUser} ${mediaGroup} -"
    "d /var/downloads/incomplete 0775 ${mediaUser} ${mediaGroup} -"
    # Media directories on NVMe - owned by user but writable by media group
    "z /mnt/fast-nvme/media 0775 ${mediaUser} ${mediaGroup} -"
    "z /mnt/fast-nvme/media/anime 0775 ${mediaUser} ${mediaGroup} -"
    "z /mnt/fast-nvme/media/movies 0775 ${mediaUser} ${mediaGroup} -"
    "z /mnt/fast-nvme/media/music 0775 ${mediaUser} ${mediaGroup} -"
    "z /mnt/fast-nvme/media/tv 0775 ${mediaUser} ${mediaGroup} -"
    # Fix permissions recursively on existing files
    "Z /var/downloads 0775 ${mediaUser} ${mediaGroup} -"
    "Z /mnt/fast-nvme/media 0775 ${mediaUser} ${mediaGroup} -"
  ];

  # Systemd service to fix media and downloads permissions on boot
  systemd.services.fix-media-permissions = {
    description = "Fix permissions on media and downloads directories";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      # Fix downloads directories
      ${pkgs.findutils}/bin/find /var/downloads -type d -exec ${pkgs.coreutils}/bin/chmod 775 {} \;
      ${pkgs.findutils}/bin/find /var/downloads -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
      ${pkgs.coreutils}/bin/chown -R ${mediaUser}:${mediaGroup} /var/downloads

      # Fix media directories if they exist
      if [ -d /mnt/fast-nvme/media ]; then
        ${pkgs.findutils}/bin/find /mnt/fast-nvme/media -type d -exec ${pkgs.coreutils}/bin/chmod 775 {} \;
        ${pkgs.findutils}/bin/find /mnt/fast-nvme/media -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
        ${pkgs.coreutils}/bin/chown -R ${mediaUser}:${mediaGroup} /mnt/fast-nvme/media
      fi
    '';
  };

  # User configuration
  modules.homeManager.git.enable = true;

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "*-*-* 03:00:00";
    randomizedDelaySec = "1h";
    flake = "github:zekurio/nix-config#adam";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
