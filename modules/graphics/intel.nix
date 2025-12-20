{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphics.intel;
in
{
  options.modules.graphics.intel = {
    enable = mkEnableOption "Intel GPU support";
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
