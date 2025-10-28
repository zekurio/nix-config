{
  lib,
  config,
  inputs,
  ...
}: let
  inherit
    (lib)
    hasAttrByPath
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.desktop.hyprland;
in {
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
    ./system.nix
    ./home.nix
    ./browser.nix
  ];

  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Hyprland desktop with DankMaterialShell integration";

    user = mkOption {
      type = types.str;
      default = "zekurio";
      description = "Primary desktop user that owns the session.";
    };

    greeterCompositor = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Compositor used by the DankMaterialShell greeter.";
      example = "niri";
    };

    greeterConfigHome = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional path copied to the greeter data directory before start.";
      example = "/home/zekurio";
    };
  };

  config = mkIf cfg.enable (
    let
      defaultConfigHome = "/home/${cfg.user}";
      resolvedConfigHome =
        if cfg.greeterConfigHome != null
        then cfg.greeterConfigHome
        else defaultConfigHome;
    in {
      assertions = [
        {
          assertion = hasAttrByPath [cfg.user] config.users.users;
          message = "modules.desktop.hyprland.user must reference an existing user.";
        }
      ];

      programs.dankMaterialShell.greeter = {
        enable = true;
        compositor.name = cfg.greeterCompositor;
        configHome = resolvedConfigHome;
      };

      modules.desktop.browser.brave.enable = mkDefault true;
    }
  );
}
