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
          settings = {
            # Include DMS dynamic theme colors
            # Ghostty resolves this relative to its config directory
            config-file = [ "config-dankcolors" ];
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
      ];
    };
  };
}
