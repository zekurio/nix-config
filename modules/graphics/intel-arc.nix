{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphics.intelArc;
in
{
  options.modules.graphics.intelArc = {
    enable = mkEnableOption "Intel ARC GPU support";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    # Add monitoring tool here
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];

    boot.kernelParams = [ "i915.enable_guc=3" ];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-compute-runtime
          vpl-gpu-rt
        ];
      };
    };
  };
}
