{ pkgs, ... }:
{
  imports = [ ./dms/default.nix ];

  programs.niri.enable = true;

  environment.systemPackages = [ pkgs.xwayland-satellite ];
}