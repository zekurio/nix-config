{
  lib,
  config,
  pkgs,
  pkgsUnstable,
  ...
}: let
  inherit
    (lib)
    mkAfter
    mkIf
    ;
  cfg = config.modules.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
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
      wireplumber = {
        enable = true;
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common = {
        default = ["hyprland" "gtk"];
      };
    };

    services.dbus.enable = true;
    services.accounts-daemon.enable = true;

    environment = {
      systemPackages = mkAfter [
        pkgs.accountsservice
        pkgs.adw-gtk3
        pkgs.bibata-cursors
        pkgs.bitwarden
        pkgs.blueman
        pkgs.brightnessctl
        pkgs.cliphist
        pkgs.delfin
        pkgsUnstable.feishin
        pkgsUnstable.ghostty
        pkgs.grim
        pkgs.grimblast
        pkgs.loupe
        pkgs.mate.mate-polkit
        pkgs.matugen
        pkgs.nemo
        pkgs.nemo-fileroller
        pkgs.pwvucontrol
        pkgs.seahorse
        pkgs.showtime
        pkgs.slurp
        pkgs.papirus-icon-theme
        pkgsUnstable.vesktop
        pkgs.wayland-utils
        pkgs.wl-clipboard
        pkgs.wl-clip-persist
        pkgs.xdg-user-dirs
        pkgs.xdg-user-dirs-gtk
        pkgs.xwayland-satellite
        pkgsUnstable.zed-editor
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

    systemd.services.greetd.environment = {
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "20";
      XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
    };

    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = "hyprland";
      configHome = "/home/${cfg.user}";
    };

    users.users.${cfg.user}.extraGroups = mkAfter [
      "audio"
      "render"
      "seat"
    ];
  };
}
