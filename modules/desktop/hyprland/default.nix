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
    ./home.nix
    ./system.nix
  ];

  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Hyprland desktop with DankMaterialShell integration";

    user = mkOption {
      type = types.str;
      default = "zekurio";
      description = "Primary desktop user that owns the session.";
    };

    monitors = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "DP-2,2560x1440@165,2560x0,1,vrr,1"
        "HDMI-A-1,1920x1080@60,0x0,1"
      ];
      description = "Monitor configuration entries for Hyprland.";
    };

    input = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      example = {
        kb_layout = "eu";
        numlock_by_default = true;
      };
      description = "Hyprland input settings.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = hasAttrByPath [cfg.user] config.users.users;
        message = "modules.desktop.hyprland.user must reference an existing user.";
      }
    ];

    modules.desktop.browser.brave.enable = mkDefault true;
  };
}
