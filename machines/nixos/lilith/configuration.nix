{
  config,
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

  modules.graphics.amd.enable = true;
  modules.virtualization.enable = true;
  modules.desktop.enable = true;
  modules.users.zekurio = {
    enable = true;
    homeManager.enable = true;
  };

  home-manager.users.zekurio.programs.niri.settings = {
    input.keyboard.xkb.layout = "eu";
    outputs."DP-2" = {
      mode = {
        width = 2560;
        height = 1440;
        refresh = 165.0;
      };
    };
  };

  time.timeZone = "Europe/Vienna";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sun 04:00";
    flake = "git+https://codeberg.org/zekurio/nix?ref=lilith";
  };

  # DO NOT TOUCH THIS
  system.stateVersion = "25.11";
}
