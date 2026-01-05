{
  config,
  pkgs,
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
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
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
  };

  # AMD GPU environment variables
  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
  };

  # Networking configuration
  networking = {
    hostName = "lilith";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Niri compositor
  programs.niri.enable = true;

  # DankMaterialShell
  programs.dms-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableSystemMonitoring = true;
    enableClipboard = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
  };

  # DankGreeter with greetd
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${mainUser}";
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # System packages
  environment.systemPackages = with pkgs; [
    ryzen-monitor-ng
    lm_sensors

    # Desktop applications
    _1password-cli
    _1password-gui
    brave
    ghostty
    vesktop
    zed-editor

    # Theming
    adw-gtk3
    papirus-icon-theme
  ];

  # Fonts
  fonts.packages = with pkgs; [
    inter
    fira-code
    nerd-fonts.symbols-only
  ];

  services = {
    # Pipewire audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # XDG portal for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  time.timeZone = "Europe/Vienna";

  # DO NOT TOUCH THIS
  system.stateVersion = "25.11";
}
