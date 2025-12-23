{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
    ../default.nix
  ];

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
    kernelPackages = pkgs.linuxPackages_zen;
  };

  networking = {
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      dns = "systemd-resolved";
    };
    nameservers = [
      "192.168.0.2"
      "9.9.9.9"
    ];
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "9.9.9.9" ];
    extraConfig = ''
      DNSOverTLS=opportunistic
    '';
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
  };

  modules.desktop.enable = true;
  modules.graphics.amd.enable = true;
  modules.virtualization.enable = true;

  services.power-profiles-daemon.enable = true;

  users.users.zekurio.extraGroups = [ "networkmanager" ];

  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sun 04:00";
    flake = "github:zekurio/nix#lilith";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.11";
}
