{ config, pkgs, modulesPath, lib, ... }:

let
  # Shared service account for media workloads
  shareGroup = "share";
  shareGroupGid = 995;
  shareUser = "share";
  shareUserUid = 995;
  mainUser = "zekurio";
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
    #../../../modules/homelab/services/lidarr.nix
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
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
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
    options = [ "defaults" "noatime" "nodiratime" "acl" ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      mullvad_wg = { };
      autobrr_secret = {
        owner = shareUser;
        group = shareGroup;
        mode = "0400";
      };
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

  # System packages
  environment.systemPackages = with pkgs; [
    streamrip
    beets
    ryzen-monitor-ng
  ];

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
    jellyfin-wrapped.enable = false; # Using container instead
    navidrome-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;
    jellyseerr-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    #lidarr-wrapped.enable = true;
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
    wireguardConfigFile = config.sops.secrets.mullvad_wg.path;
    accessibleFrom = [
      "192.168.0.0/16" # Adjust to your local network
    ];
    portMappings = [
      { from = 8080; to = 8080; } # qBittorrent WebUI
    ];
    openVPNPorts = [
      { port = 6881; protocol = "both"; } # qBittorrent incoming connections
    ];
  };

  # Confine qBittorrent to VPN namespace
  systemd.services.qbittorrent = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "mullvad";
    };
    serviceConfig = {
      User = shareUser;
      Group = shareGroup;
    };
  };

  # Shared service account providing read/write access for media tooling
  users.groups.${shareGroup} = {
    gid = shareGroupGid;
  };

  users.users.${shareUser} = {
    isSystemUser = true;
    uid = shareUserUid;
    group = shareGroup;
    home = "/var/lib/share";
    createHome = true;
    description = "Shared service account for media automation";
  };

  # Allow the main interactive user to collaborate on shared media files
  users.users.${mainUser}.extraGroups = [ shareGroup ];

  systemd.tmpfiles.rules = [
    # qBittorrent state directory
    "Z /var/lib/qBittorrent 2775 ${shareUser} ${shareGroup} -"
    # Downloads directories on root drive (for transcoding before moving to NVMe)
    "Z /var/downloads 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/completed 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/completed/sonarr 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/completed/radarr 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/completed/torrent 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/converted 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/converted/sonarr 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/converted/radarr 2775 ${shareUser} ${shareGroup} -"
    "Z /var/downloads/incomplete 2775 ${shareUser} ${shareGroup} -"
    # Media directories on NVMe - owned by shared service account
    "z /mnt/fast-nvme/media 2775 ${shareUser} ${shareGroup} -"
    "z /mnt/fast-nvme/media/anime 2775 ${shareUser} ${shareGroup} -"
    "z /mnt/fast-nvme/media/movies 2775 ${shareUser} ${shareGroup} -"
    "z /mnt/fast-nvme/media/music 2775 ${shareUser} ${shareGroup} -"
    "z /mnt/fast-nvme/media/tv 2775 ${shareUser} ${shareGroup} -"
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
      ${pkgs.findutils}/bin/find /var/downloads -type d -exec ${pkgs.coreutils}/bin/chmod 2775 {} \;
      ${pkgs.findutils}/bin/find /var/downloads -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
      ${pkgs.coreutils}/bin/chown -R ${shareUser}:${shareGroup} /var/downloads
      ${pkgs.acl}/bin/setfacl -Rm g:${shareGroup}:rwx /var/downloads
      ${pkgs.acl}/bin/setfacl -dRm g:${shareGroup}:rwx /var/downloads

      # Fix media directories if they exist
      if [ -d /mnt/fast-nvme/media ]; then
        ${pkgs.findutils}/bin/find /mnt/fast-nvme/media -type d -exec ${pkgs.coreutils}/bin/chmod 2775 {} \;
        ${pkgs.findutils}/bin/find /mnt/fast-nvme/media -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
        ${pkgs.coreutils}/bin/chown -R ${shareUser}:${shareGroup} /mnt/fast-nvme/media
        ${pkgs.acl}/bin/setfacl -Rm g:${shareGroup}:rwx /mnt/fast-nvme/media
        ${pkgs.acl}/bin/setfacl -dRm g:${shareGroup}:rwx /mnt/fast-nvme/media
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
