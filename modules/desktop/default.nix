{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.desktop;
in
{
  imports = [ ./niri/default.nix ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment configuration";
  };

  config = mkIf cfg.enable {
    # Polkit for authentication dialogs
    security.polkit.enable = true;

    # GNOME Keyring for secret management
    services.gnome.gnome-keyring.enable = true;

    # Enable GNOME Keyring unlock for greetd PAM service
    security.pam.services.greetd.enableGnomeKeyring = true;

    # D-Bus (dependency for polkit/keyring)
    services.dbus.enable = true;

    # Electron/Chromium Wayland support
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Desktop home-manager configuration
    home-manager.users.zekurio = {
      programs = {
        # Terminal emulator
        ghostty = {
          enable = true;
          enableZshIntegration = true;
        };
      };

      home.packages = with pkgs; [
        unstable.brave
        unstable.zed-editor
        unstable.vesktop
        unstable.bitwarden-desktop
        unstable.bitwarden-cli
        unstable.deezer-enhanced
      ];
    };
  };
}
