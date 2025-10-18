{ pkgs, lib, ... }:
let
  maybePlugin = name: lib.mkIf (lib.hasAttr name pkgs.fishPlugins) {
    inherit name;
    src = lib.getAttr name pkgs.fishPlugins;
  };

  pluginList = lib.filter (plugin: plugin ? src) [
    (maybePlugin "eza")
    (maybePlugin "fzf")
    (maybePlugin "tide")
  ];
in
{
  home.packages = with pkgs; [
    bat
    btop
    eza
    fzf
    zellij
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g tide_prompt_style pure
      set -g tide_theme nord
      set -g tide_prompt_add_newline false
      set -g tide_left_prompt_items pwd git
      set -g tide_right_prompt_items status cmd_duration context jobs
    '';
    plugins = pluginList;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    extraOptions = [ "--group-directories-first" "--icons=auto" ];
  };
}
