{ lib, pkgs, ... }:
{
  imports = [ ./dms/default.nix ];

  # Use niri from nixpkgs (25.11)
  programs.niri.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Base niri config with environment variables (at the beginning)
  home-manager.users.zekurio.xdg.configFile."niri/config.kdl".text = lib.mkBefore ''
    // Environment variables for Qt theming
    environment {
      QT_QPA_PLATFORMTHEME "gtk3"
      QT_QPA_PLATFORMTHEME_QT6 "gtk3"
    }
  '';
}
