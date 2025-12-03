{
  config,
  pkgs,
  modulesPath,
  ...
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
    nameservers = [ "127.0.0.1" ];
    firewall.allowedUDPPorts = [ 53 ];
  };

  # DNS over TLS with Cloudflare
  services.resolved = {
    enable = false;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  fileSystems."/mnt/downloads" = {
    device = "/dev/disk/by-uuid/b036ac8f-cb3c-468f-9a37-80351abe887c";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      mullvad_wg = { };
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

    # Samba network shares for ZFS tank pool
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "adam";
          "netbios name" = "adam";
          security = "user";
          "hosts allow" = "192.168. 10. 100.64.0.0/10 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "Bad User";
          "server min protocol" = "SMB2";
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
          "use sendfile" = "yes";
          "aio read size" = "16384";
          "aio write size" = "16384";
        };
        media = {
          path = "/tank/jellyfin";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "@${shareGroup}";
          "force user" = shareUser;
          "force group" = shareGroup;
          "create mask" = "0664";
          "directory mask" = "2775";
          comment = "Media Library";
        };
        vault = {
          path = "/tank/vault";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = mainUser;
          "force user" = mainUser;
          "force group" = mainUser;
          "create mask" = "0664";
          "directory mask" = "0755";
          comment = "Vault";
        };
        datadrop = {
          path = "/mnt/downloads";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "@${shareGroup}";
          "force user" = shareUser;
          "force group" = shareGroup;
          "create mask" = "0664";
          "directory mask" = "2775";
          comment = "Downloads";
        };
      };
    };

    # Enable SMB autodiscovery
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

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
        "/var/lib/whisparr"
        "/var/lib/dex"
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

    backups.local = {
      enable = true;
      repository = "/tank/backup/restic";
      initialize = true;
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
        "/var/lib/whisparr"
        "/var/lib/dex"
      ];
      excludePaths = [ ];
      extraBackupArgs = [ "--tag adam" ];
      pruneKeep = {
        daily = 7;
        weekly = 4;
        monthly = 12;
      };
      timer = "*-*-* 02:00:00";
      randomizedDelaySec = "1h";
    };

    # Enable wrapped services with Caddy integration
    paperless-ngx-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;
    jellyseerr-wrapped.enable = true;
    jellyfin-wrapped.enable = true;
    immich-wrapped.enable = true;

    # Enable OIDC provider
    dex-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
    sabnzbd-wrapped.enable = true;
    autobrr-wrapped.enable = true;
    whisparr-wrapped.enable = true;

    # qBittorrent with VPN confinement
    qbittorrent-wrapped.enable = true;

    # FileFlows media automation
    fileflows-wrapped.enable = true;

    # Unbound DNS server
    unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" "::1" "0.0.0.0" ];
          access-control = [
            "127.0.0.0/8 allow"
            "::1/128 allow"
            "192.168.0.0/16 allow"
            "100.64.0.0/10 allow"
          ];
          access-control-view = [
            "192.168.0.0/16 lan"
            "100.64.0.0/10 tailscale"
          ];
          do-ip4 = "yes";
          do-ip6 = "no";
          do-udp = "yes";
          do-tcp = "yes";
          hide-identity = "yes";
          hide-version = "yes";
          harden-glue = "yes";
          harden-dnssec-stripped = "yes";
          use-caps-for-id = "yes";
          prefetch = "yes";
          prefetch-key = "yes";
          qname-minimisation = "yes";
          rrset-roundrobin = "yes";
          minimal-responses = "yes";
          cache-min-ttl = 300;
          cache-max-ttl = 86400;
        };

        forward-zone = {
          name = ".";
          forward-ssl-upstream = "yes";
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
          ];
        };

        view = [
          {
            name = "lan";
            local-zone = [
              "schnitzelflix.xyz. transparent"
              "zekurio.xyz. transparent"
            ];
            local-data = [
              "\"schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"docs.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"photos.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"status.schnitzelflix.xyz. 3600 IN A 0.0.0.0\""
              "\"requests.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"sab.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"qbit.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"arr.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"ff.schnitzelflix.xyz. 3600 IN A 192.168.0.2\""
              "\"zekurio.xyz. 3600 IN A 192.168.0.2\""
              "\"vw.zekurio.xyz. 3600 IN A 192.168.0.2\""
            ];
          }
          {
            name = "tailscale";
            local-zone = [
              "schnitzelflix.xyz. transparent"
              "zekurio.xyz. transparent"
            ];
            local-data = [
              "\"schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"docs.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"photos.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"status.schnitzelflix.xyz. 3600 IN A 0.0.0.0\""
              "\"requests.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"sab.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"qbit.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"arr.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"ff.schnitzelflix.xyz. 3600 IN A 100.103.132.84\""
              "\"zekurio.xyz. 3600 IN A 100.103.132.84\""
              "\"vw.zekurio.xyz. 3600 IN A 100.103.132.84\""
            ];
          }
        ];
      };
    };
  };

  # VPN namespace configuration for qBittorrent
  vpnNamespaces.mullvad = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.mullvad_wg.path;
    accessibleFrom = [
      "192.168.0.0/16"
    ];
    portMappings = [
      {
        from = 8080;
        to = 8080;
      }
    ];
    openVPNPorts = [
      {
        port = 6881;
        protocol = "both";
      }
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