{ config
, pkgs
, lib
, modulesPath
, ...
}:
let
  # Shared service account for media workloads
  shareGroup = "share";
  shareGroupGid = 2999;
  shareUser = "share";
  shareUserUid = 2999;
  mainUser = "zekurio";
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
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  fileSystems."/mnt/downloads" = {
    device = "/dev/disk/by-uuid/b036ac8f-cb3c-468f-9a37-80351abe887c";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" ];
  };

  fileSystems."/tank" = {
    device = "tank";
    fsType = "zfs";
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
    streamrip
    beets
    ryzen-monitor-ng
    zfs
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
    tailscale.enable = true;

    backups.b2 = {
      enable = true;
      repository = "b2:zekurio-homelab:adam";
      paths = [
        "/etc/nixos"
        "/var/lib/autobrr"
        "/var/lib/configarr"
        "/var/lib/fileflows"
        "/var/lib/jellyfin"
        "/var/lib/jellyseerr"
        "/var/lib/lidarr"
        "/var/lib/navidrome"
        "/var/lib/paperless"
        "/var/lib/prowlarr"
        "/var/lib/qBittorrent"
        "/var/lib/radarr"
        "/var/lib/sabnzbd"
        "/var/lib/sonarr"
        "/var/lib/vaultwarden"
      ];
      excludePaths = [
        "/var/lib/navidrome/cache"
      ];
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
    navidrome-wrapped.enable = true;
    paperless-ngx-wrapped.enable = true;
    vaultwarden-wrapped.enable = true;
    jellyseerr-wrapped.enable = true;
    jellyfin-wrapped.enable = true;

    # Enable arr stack services
    sonarr-wrapped.enable = true;
    radarr-wrapped.enable = true;
    lidarr-wrapped.enable = true;
    prowlarr-wrapped.enable = true;
    sabnzbd-wrapped.enable = true;
    autobrr-wrapped.enable = true;

    # qBittorrent with VPN confinement
    qbittorrent-wrapped.enable = true;

    fileflows-wrapped = {
      enable = true;
    };
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

  # Shared service account providing read/write access for media tooling
  users.groups.${shareGroup} = {
    gid = shareGroupGid;
  };

  users.users.${shareUser} = {
    isSystemUser = true;
    uid = shareUserUid;
    group = shareGroup;
    extraGroups = [
      "video"
      "render"
    ];
    home = "/var/lib/share";
    createHome = true;
    description = "Shared service account for media automation";
  };

  # Allow the main interactive user to collaborate on shared media files
  users.users.${mainUser}.extraGroups = [ shareGroup ];

  systemd.tmpfiles.rules = [
    # qBittorrent state directory
    "Z /var/lib/qBittorrent 2775 ${shareUser} ${shareGroup} -"

    # Downloads directories on NVMe
    "Z /mnt/downloads 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/completed 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/completed/sonarr 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/completed/radarr 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/completed/torrent 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/converted 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/converted/sonarr 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/converted/radarr 2775 ${shareUser} ${shareGroup} -"
    "Z /mnt/downloads/incomplete 2775 ${shareUser} ${shareGroup} -"

    # Media directories on ZFS - owned by shared service account
    "z /tank/media           2775 ${shareUser} ${shareGroup} -"
    "z /tank/media/anime     2775 ${shareUser} ${shareGroup} -"
    "z /tank/media/movies    2775 ${shareUser} ${shareGroup} -"
    "z /tank/media/music     2775 ${shareUser} ${shareGroup} -"
    "z /tank/media/tv        2775 ${shareUser} ${shareGroup} -"
  ];

  # Systemd service to fix media and downloads permissions on boot
  systemd.services.fix-media-permissions =
    let
      mediaStateDirs =
        builtins.filter (dir: lib.hasPrefix "/var/lib" dir)
          (config.services.backups.b2.paths or [ ]);
      chownMediaDirs =
        lib.concatMapStrings (dir: ''
          if [ -d ${dir} ]; then
            ${pkgs.coreutils}/bin/chown -R ${shareUser}:${shareGroup} ${dir}
          fi
        '') mediaStateDirs;
    in
    {
      description = "Fix permissions on media and downloads directories";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Fix downloads directories
        ${pkgs.findutils}/bin/find /mnt/downloads -type d -exec ${pkgs.coreutils}/bin/chmod 2775 {} \;
        ${pkgs.findutils}/bin/find /mnt/downloads -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
        ${pkgs.coreutils}/bin/chown -R ${shareUser}:${shareGroup} /mnt/downloads
        ${pkgs.acl}/bin/setfacl -Rm g:${shareGroup}:rwx /mnt/downloads
        ${pkgs.acl}/bin/setfacl -dRm g:${shareGroup}:rwx /mnt/downloads

        # Fix media directories if they exist
        if [ -d /tank/media ]; then
          ${pkgs.findutils}/bin/find /tank/media -type d -exec ${pkgs.coreutils}/bin/chmod 2775 {} \;
          ${pkgs.findutils}/bin/find /tank/media -type f -exec ${pkgs.coreutils}/bin/chmod 664 {} \;
          ${pkgs.coreutils}/bin/chown -R ${shareUser}:${shareGroup} /tank/media
          ${pkgs.acl}/bin/setfacl -Rm g:${shareGroup}:rwx /tank/media
          ${pkgs.acl}/bin/setfacl -dRm g:${shareGroup}:rwx /tank/media
        fi

        # Fix state directories for media services
        ${chownMediaDirs}
      '';
    };

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sun 04:00";
    randomizedDelaySec = "1h";
    flake = "github:zekurio/nix-config#adam";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
