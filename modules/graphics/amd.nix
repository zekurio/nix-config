{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphics.amd;
in
{
  options.modules.graphics.amd = {
    enable = mkEnableOption "AMD GPU support";

    opencl.enable = mkEnableOption "OpenCL support via ROCm";

    initrd.enable = mkEnableOption "Load amdgpu module in initrd for higher resolution early boot";
  };

  config = mkIf cfg.enable {
    # Basic hardware graphics acceleration
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # Load amdgpu in initrd if requested
    boot.initrd.kernelModules = mkIf cfg.initrd.enable [ "amdgpu" ];

    # OpenCL support via ROCm
    hardware.graphics.extraPackages = mkIf cfg.opencl.enable (
      with pkgs;
      [
        rocmPackages.clr.icd
      ]
    );

    # GPU monitoring and control tools
    environment.systemPackages = with pkgs; [
      radeontop
      clinfo
    ];
  };
}
