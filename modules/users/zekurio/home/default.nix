{ pkgs, ... }:
{
  home.username = "zekurio";
  home.homeDirectory = "/home/zekurio";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
