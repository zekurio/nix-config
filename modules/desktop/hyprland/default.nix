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
