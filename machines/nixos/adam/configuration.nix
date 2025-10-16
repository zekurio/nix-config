{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
    ../../../overlays
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
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
    };
  };

  fileSystems."/mnt/fast-nvme" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets/adam.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.caddy_env = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
    };
    secrets.vaultwarden_env = {
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };
  };

  services = {
    openssh.enable = true;
    autoaspm.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
      group = "zekurio";
    };
    navidrome = {
      enable = true;
      settings = {
        MusicFolder = "/mnt/fast-nvme/media/music";
        Address = "127.0.0.1";
        Port = 4533;
        BaseUrl = "/";
      };
      group = "zekurio";
    };
    vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://vw.zekurio.xyz";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        WEBSOCKET_ENABLED = true;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;
      };
      environmentFile = config.sops.secrets.vaultwarden_env.path;
    };
    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
        hash = "sha256-p9AIi6MSWm0umUB83HPQoU8SyPkX5pMx989zAi8d/74=";
      };
      globalConfig = ''
        email {env.CLOUDFLARE_API_EMAIL}
      '';
      virtualHosts."schnitzelflix.xyz" = {
        extraConfig = ''
          reverse_proxy localhost:8096
          tls {
            dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          }
        '';
      };
      virtualHosts."vw.zekurio.xyz" = {
        extraConfig = ''
          reverse_proxy localhost:8222
          tls {
            dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          }
        '';
      };
      virtualHosts."nv.zekurio.xyz" = {
        extraConfig = ''
          reverse_proxy localhost:4533
          tls {
            dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          }
        '';
      };
    };
  };

  # Make Cloudflare API token and email available to Caddy
  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = [ config.sops.secrets.caddy_env.path ];
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
