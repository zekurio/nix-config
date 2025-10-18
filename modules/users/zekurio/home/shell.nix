{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    eza
    zellij
    git
    bun
    vim
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    plugins = [
      pkgs.fishPlugins.pure
    ];
  };

  programs.eza = {
    enable = true;
    extraOptions = [ "--group-directories-first" "--icons=auto" ];
  };
}
