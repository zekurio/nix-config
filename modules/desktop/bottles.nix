{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.desktop.bottles;
in {
  options.modules.desktop.bottles = {
    enable =
      lib.mkEnableOption "Bottles wineprefix manager"
      // {
        default = true;
      };

    removeWarningPopup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Remove the startup warning popup about unsupported configurations.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkAfter [
      (pkgs.bottles.override {
        removeWarningPopup = cfg.removeWarningPopup;
      })
    ];
  };
}
