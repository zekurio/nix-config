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
      {
        name = "pure";
        src = pkgs.fishPlugins.pure.src;
      }
    ];
  };

  programs.eza = {
    enable = true;
    extraOptions = [ "--group-directories-first" "--icons=auto" ];
  };
}
