{ inputs, config, lib, ... }:
let
  # Check if zekurio user exists and is enabled
  zekurioEnabled = config.modules.users.zekurio.enable or false;
in
{
  config = {
    # Basic DMS greeter configuration with conditional user settings
    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = "niri";
    } // lib.optionalAttrs zekurioEnabled {
      configHome = "/home/zekurio";
      configFiles = [ "/home/zekurio/.config/DankMaterialShell/settings.json" ];
    };

    # Enable gnome-keyring integration for greetd
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Configure home-manager for zekurio if enabled
    home-manager.users.zekurio = lib.mkIf zekurioEnabled {
      imports = [ inputs.dms.homeModules.dankMaterialShell.default ];

      programs.dankMaterialShell = {
        enable = true;
        systemd.enable = true;
      };
    };
  };
}