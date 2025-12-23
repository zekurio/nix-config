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
      systemd-boot.enable = lib.mkForce false;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    initrd.systemd = {
      enable = true;
      emergencyAccess = true;
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

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tools
  ];

  modules.desktop = {
    enable = true;
    niri = {
      outputs."eDP-1" = {
        mode = "1920x1080@120.003";
        scale = 1.25;
        variableRefreshRate = true;
      };
      xkbLayout = "de";
      touchpad.tap = true;
    };
  };
  modules.graphics.hybrid.enable = true;
  modules.virtualization.enable = true;

  services.power-profiles-daemon.enable = true;

  users.users.zekurio.extraGroups = [ "networkmanager" ];

  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sun 04:00";
    flake = "github:zekurio/nix#sachiel";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.11";
}
