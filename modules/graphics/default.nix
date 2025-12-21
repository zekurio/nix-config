{ pkgs, ... }:
{
  imports = [
    ./amd.nix
    ./hybrid.nix
    ./intel.nix
  ];

  environment.systemPackages = with pkgs; [
    pciutils
  ];
}
