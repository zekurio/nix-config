{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.desktop;
in
{
  options.modules.desktop = {
    enable = mkEnableOption "desktop environment support";
  };

  config = mkIf cfg.enable {
    # Polkit for authentication dialogs
    security.polkit.enable = true;
    # GNOME Keyring for secret management
    services.gnome.gnome-keyring.enable = true;
    # D-Bus (dependency for polkit/keyring)
    services.dbus.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Niri compositor (from nixpkgs)
    programs.niri.enable = true;

    # DankMaterialShell (from nixpkgs-unstable)
    programs.dms-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      # Core features
      enableSystemMonitoring = true;
      enableClipboard = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
    };

    # DankGreeter (from nixpkgs-unstable)
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/zekurio";
    };

    # Desktop home-manager configuration
    home-manager.users.zekurio = {
      programs = {
        # Terminal emulator
        ghostty = {
          enable = true;
          enableZshIntegration = true;
          settings = {
            # DMS dynamic theme colors
            config-file = [ "config-dankcolors" ];
            # Disable GTK decorations
            gtk-titlebar = false;

            # Padding
            window-padding-x = 10;
            window-padding-y = 10;
          };
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        cursorTheme = {
          name = "graphite-dark";
        };
      };

      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        (nerd-fonts.symbols-only)
        inter
        fira-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
        unstable.brave
        unstable.zed-editor
        unstable.vesktop
        unstable.bitwarden-desktop
        unstable.bitwarden-cli
        unstable.deezer-enhanced
        xwayland-satellite
        wl-clipboard
        cliphist
      ];
    };
  };
}
