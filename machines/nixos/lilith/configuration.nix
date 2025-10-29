{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../default.nix
    ./disko.nix
    ../../../modules/desktop
    ../../../modules/gaming
    ../../../modules/graphics
    ../../../modules/home-manager
    ../../../modules/users
    ../../../overlays
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    dnsovertls = "true";
  };

  networking.hostName = "lilith";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

  time.timeZone = lib.mkDefault "Europe/Vienna";

  boot = {
    loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.mkForce false;
    };
    initrd = {
      verbose = false;
    };
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
      "acpi_enforce_resources=lax"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
    kernelModules = ["kvm-amd" "it87"];
    extraModprobeConfig = ''
      options it87 force_id=0x8628
    '';
    kernelPackages = pkgs.linuxPackages_zen;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
  };

  modules = {
    desktop.hyprland.enable = true;
    gaming.enable = true;
    graphics.amd.enable = true;
    homeManager = {
      bitwardenSsh.enable = true;
      dev.enable = true;
    };
  };

  users.users.zekurio.extraGroups = lib.mkAfter ["networkmanager"];

  environment.systemPackages = lib.mkAfter [
    pkgs.sbctl
    pkgs.cryptsetup
  ];

  programs.coolercontrol.enable = true;

  services = {
    fwupd.enable = true;
    gvfs.enable = true;
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    openssh = {
      enable = lib.mkDefault true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    power-profiles-daemon.enable = true;
  };

  systemd.services.disable-gpp0-acpi-wakeup = {
    description = "Disable ACPI wake device GPP0";
    wantedBy = ["multi-user.target"];
    after = ["sysinit.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-gpp0-acpi-wakeup" ''
        echo GPP0 > /proc/acpi/wakeup
      '';
    };
  };

  system.stateVersion = "25.05";
}
