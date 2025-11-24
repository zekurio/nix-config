{ config
, pkgs
, modulesPath
, ...
}:
let
  mainUser = "zekurio";
  shareUser = "share";
  shareGroup = "share";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../../../modules/graphics
    ../../../modules/virtualization
    ../default.nix
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
      "zenpower"
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
    blacklistedKernelModules = [ "k10temp" ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "tank" ];
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
  };

  modules.graphics.intelArc.enable = true;
  modules.virtualization.enable = true;
  modules.homelab.mediaShare = {
    enable = true;
    collaborators = [ mainUser ];
  };
  modules.homelab.tailscale = {
    enable = true;
    publicInterface = "enp42s0";
  };

  # Networking configuration
  networking = {
    hostName = "adam";
    useDHCP = true;
    networkmanager.enable = false;
    firewall.enable = true;
    hostId = "eab7e93e";
  };

  # DNS over TLS with Cloudflare
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  fileSystems."/mnt/downloads" = {
    device = "/dev/disk/by-uuid/b036ac8f-cb3c-468f-9a37-80351abe887c";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" ];
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

  # System packages
  environment.systemPackages = with pkgs; [
    ryzen-monitor-ng
    zfs
    unstable.ab-av1
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

    backups.b2 = {
      enable = true;
      repository = "b2:zekurio-homelab:adam";
      paths = [
        "/etc/nixos"
        "/var/lib/autobrr"
        "/var/lib/immich"
        "/var/lib/jellyfin"
        "/var/lib/jellyseerr"
        "/var/lib/paperless"
        "/var/lib/prowlarr"
        "/var/lib/qBittorrent"
        "/var/lib/radarr"
        "/var/lib/sabnzbd"
        "/var/lib/sonarr"
        "/var/lib/vaultwarden"
      ];
      excludePaths = [ ];
      extraBackupArgs = [ "--tag adam" ];
      pruneKeep = {
        daily = 7;
        weekly = 4;
        monthly = 12;
      };
      timer = "*-*-* 01:00:00";
      randomizedDelaySec = "1h";
    };

    # Enable wrapped services with Caddy integration
    paperless-ngx-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;
    jellyseerr-wrapped.enable = true;
    jellyfin-wrapped.enable = true;
    immich-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
    sabnzbd-wrapped.enable = true;
    autobrr-wrapped.enable = true;

    # qBittorrent with VPN confinement
    qbittorrent-wrapped.enable = true;
  };

  # VPN namespace configuration for qBittorrent
  vpnNamespaces.mullvad = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.mullvad_wg.path;
    accessibleFrom = [
      "192.168.0.0/16" # Adjust to your local network
    ];
    portMappings = [
      {
        from = 8080;
        to = 8080;
      } # qBittorrent WebUI
    ];
    openVPNPorts = [
      {
        port = 6881;
        protocol = "both";
      } # qBittorrent incoming connections
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

  users.mutableUsers = false;

  # Shared media user, directories, and permission remediation
  # are defined in modules.homelab.mediaShare.

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sun 04:00";
    flake = "github:zekurio/nix-config#adam";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
