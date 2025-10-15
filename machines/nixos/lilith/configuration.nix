{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
  ];

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
      "acpi_enforce_resources=lax"
    ];
    kernelModules = [
      "kvm-amd"
      "k10temp"
    ];
    loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    }
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth.enable = true;
  };

  # Networking configuration
  networking = {
    hostName = "lilith";
    useDHCP = true;
    networkmanager.enable = false;
  };

  # Nix configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade.enable = true;

  # Hyprland configuration
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # XDG Portal for screensharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  services = {
    lact.enable = true;
    openssh.enable = true;
    pipewire {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    blueman.enable = true;
  }

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
