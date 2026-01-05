{
  config,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  mainUser = "zekurio";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
  ];

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [
      "kvm-amd"
      "zenpower"
      "it87"
    ];
    kernelParams = [
      "acpi_enforce_resources=lax"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
    extraModprobeConfig = ''
      options it87 force_id=0x8628
    '';
    blacklistedKernelModules = [ "k10temp" ];
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
        rocmPackages.clr.icd
      ];
    };
    amdgpu.overdrive.enable = true;
  };

  # SMB shares
  fileSystems = {
    "/mnt/vault" = {
      device = "//192.168.0.2/vault";
      fsType = "cifs";
      options = [
        "credentials=/home/zekurio/.smb/creds"
        "vers=3.0"
        "iocharset=utf8"
        "uid=1000" # zekurio
        "gid=100" # users
        "_netdev"
        "noauto,x-systemd.automount"
      ];
    };

    "/mnt/media" = {
      device = "//192.168.0.2/media";
      fsType = "cifs";
      options = [
        "credentials=/home/zekurio/.smb/creds"
        "vers=3.0"
        "iocharset=utf8"
        "uid=1000"
        "gid=100"
        "_netdev"
        "noauto,x-systemd.automount"
      ];
    };

    "/mnt/datadrop" = {
      device = "//192.168.0.2/datadrop";
      fsType = "cifs";
      options = [
        "credentials=/home/zekurio/.smb/creds"
        "vers=3.0"
        "iocharset=utf8"
        "uid=1000"
        "gid=100"
        "_netdev"
        "noauto,x-systemd.automount"
      ];
    };
  };

  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = "32";
  };

  # Networking configuration
  networking = {
    hostName = "lilith";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Niri compositor
  programs.niri.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # GameMode for automatic performance optimizations
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # DankMaterialShell
  programs = {
    dms-shell = {
      enable = true;
      quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableClipboard = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
    };

    _1password.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "zekurio" ];
    };

    coolercontrol.enable = true;
  };

  # DankGreeter with greetd
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${mainUser}";
  };

  # Set cursor theme for greetd
  systemd.services.greetd.environment = {
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = "32";
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Enable real-time scheduling for audio (prevents crackling)
  security.rtkit.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # system
    ryzen-monitor-ng
    lm_sensors
    xwayland-satellite

    # Desktop applications
    _1password-cli
    _1password-gui
    brave
    deezer-enhanced
    ghostty
    heroic
    protonplus
    tsukimi
    vesktop
    zed-editor

    # Gaming
    mangohud

    # smb
    cifs-utils

    # Automounting
    udiskie

    # Theming
    adw-gtk3
    papirus-icon-theme
    kdePackages.breeze
    qt6Packages.qt6ct
    rose-pine-cursor
  ];

  # Fonts
  fonts.packages = with pkgs; [
    inter
    fira-code
    nerd-fonts.symbols-only
  ];

  services = {
    # LACT for AMD GPU control
    lact.enable = true;

    # Power management
    power-profiles-daemon.enable = true;

    # Pipewire audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      # Fix audio crackling/static during gaming
      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 96000;
          "default.clock.allowed-rates" = [
            48000
            96000
          ];
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 2048;
          "default.clock.quantum-limit" = 8192;
        };
      };
    };

    # udisks2 for automounting removable drives
    udisks2.enable = true;
  };

  # XDG portal for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Systemd user services
  systemd.user.services = {
    udiskie = {
      description = "udiskie automounter for removable drives";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie -a -n -s";
        Restart = "on-failure";
      };
    };
  };

  time.timeZone = "Europe/Vienna";

  # DO NOT TOUCH THIS
  system.stateVersion = "25.11";
}
