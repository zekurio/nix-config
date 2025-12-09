{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphics.intelArc;

  arc-power = pkgs.writeShellScriptBin "arc-power" ''
    # adjust path based on your hwmon output
    hwmon="/sys/class/drm/card0/device/hwmon/hwmon2"
    
    if [[ -f "$hwmon/power1_average" ]]; then
      awk '{printf "%.2f W\n", $1/1000000}' "$hwmon/power1_average"
    elif [[ -f "$hwmon/energy1_input" ]]; then
      cat "$hwmon/energy1_input"
    else
      echo "No power sensor found. Available:"
      ls "$hwmon/"
    fi
  '';
in
{
  options.modules.graphics.intelArc = {
    enable = mkEnableOption "Intel ARC GPU support";
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [ "i915.enable_guc=3" ];
    boot.kernelModules = [ "i915" ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    environment.systemPackages = [ arc-power ];

    hardware = {
      enableAllFirmware = true;
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vpl-gpu-rt
          intel-compute-runtime
        ];
      };
    };
  };
}