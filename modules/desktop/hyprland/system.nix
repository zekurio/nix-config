{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkAfter
    mkBefore
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
    security.pam.services.greetd.enableGnomeKeyring = true;

    xdg.portal = {
      extraPortals = mkAfter [
        pkgs.xdg-desktop-portal-hyprland
      ];
      config.common.default = mkBefore [
        "hyprland"
      ];
    };

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
