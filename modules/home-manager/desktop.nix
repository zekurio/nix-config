{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    hasAttrByPath
    mkAfter
    mkEnableOption
    mkIf
    mkOption
    types;
  cfg = config.modules.desktop.hyprland;
in
{
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
  ];

  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Hyprland desktop with DankMaterialShell integration";

    user = mkOption {
      type = types.str;
      default = "zekurio";
      description = "Primary desktop user that owns the session.";
    };

    greeterCompositor = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Compositor used by the DankMaterialShell greeter.";
      example = "niri";
    };

    greeterConfigHome = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional path copied to the greeter data directory before start.";
      example = "/home/zekurio";
    };
  };

  config = mkIf cfg.enable (
    let
      defaultConfigHome = "/home/${cfg.user}";
      resolvedConfigHome =
        if cfg.greeterConfigHome != null then cfg.greeterConfigHome else defaultConfigHome;
    in
    {
      assertions = [
        {
          assertion = hasAttrByPath [ cfg.user ] config.users.users;
          message = "modules.desktop.hyprland.user must reference an existing user.";
        }
      ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };

      programs.firefox = {
        enable = true;
        package = pkgs.firefox.overrideAttrs (_old: {
          extraNativeMessagingHosts = with pkgs; [pywalfox-native];
        });
      };

      services.seatd.enable = true;
      security = {
        pam.services.greetd.enableGnomeKeyring = true;
        polkit.enable = true;
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [ "hyprland" "gtk" ];
        };
      };

      services.dbus.enable = true;

      environment = {
        systemPackages = mkAfter (with pkgs; [
          accountsservice
          adw-gtk3
          aonsoku
          bibata-cursors
          bitwarden
          blueman
          brightnessctl
          firefox
          fira-code
          ghostty
          grim
          grimblast
          inter
          loupe
          material-symbols
          mate.mate-polkit
          matugen
          nautilus
          papirus-icon-theme
          papirus-folders
          pywalfox-native
          seahorse
          showtime
          slurp
          pkgs.unstable.vesktop
          wayland-utils
          wl-clipboard
          xwayland-satellite
          pkgs.unstable.zed-editor
        ]);
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
      };

      users.users.${cfg.user}.extraGroups = mkAfter [
        "audio"
        "render"
        "seat"
      ];

      programs.dankMaterialShell.greeter = {
        enable = true;
        compositor.name = cfg.greeterCompositor;
        configHome = resolvedConfigHome;
      };

      home-manager.sharedModules = mkAfter [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        ({ pkgs, ... }: {
          services.gnome-keyring.enable = true;
          home.packages = mkAfter [
            pkgs.gcr
          ];
        })
      ];

      home-manager.users.${cfg.user} = {
        home.pointerCursor = {
          gtk.enable = true;
          # x11.enable = true;
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 16;
        };
        programs.dankMaterialShell.enable = true;
      };
    }
  );
}
