{ lib, pkgs, ... }:
let
  inherit
    (lib)
    mkAfter
    mkDefault
    ;
in {
  config = {
    security.polkit.enable = true;

    services = {
      accounts-daemon.enable = true;
      dbus.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = mkDefault [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = mkDefault [
        "gtk"
      ];
    };

    environment = {
      systemPackages = mkAfter [
        pkgs.accountsservice
        pkgs.adw-gtk3
        pkgs.bibata-cursors
        pkgs.unstable.bitwarden-desktop
        pkgs.blueman
        pkgs.brightnessctl
        pkgs.cliphist
        pkgs.unstable.tsukimi
        pkgs.unstable.feishin
        pkgs.file-roller
        pkgs.unstable.ghostty
        pkgs.grim
        pkgs.grimblast
        pkgs.loupe
        pkgs.mate.mate-polkit
        pkgs.matugen
        pkgs.nautilus
        pkgs.seahorse
        pkgs.showtime
        pkgs.slurp
        pkgs.papirus-icon-theme
        pkgs.unstable.vesktop
        pkgs.wayland-utils
        pkgs.wl-clipboard
        pkgs.wl-clip-persist
        pkgs.xdg-user-dirs
        pkgs.xdg-user-dirs-gtk
        pkgs.xwayland-satellite
        pkgs.unstable.zed-editor
      ];

      sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      variables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "20";
      };
    };

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      material-symbols
      nerd-fonts.geist-mono
      geist-font
    ];
  };
}
