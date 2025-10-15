{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
    ../../../overlays
    ../../../modules/nixos/common.nix
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

  services = {
    openssh.enable = true;
    autoaspm.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];

  # System configuration
  time.timeZone = "Europe/Vienna";
  system.autoUpgrade.enable = true;

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
