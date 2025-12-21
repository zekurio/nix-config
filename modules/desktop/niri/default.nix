{ pkgs, ... }:
{
  imports = [ ./dms/default.nix ];

  programs.niri.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
