{ pkgs, ... }:
{
  imports = [
    ./intel.nix
    ./amd.nix
  ];

  environment.systemPackages = with pkgs; [
    pciutils
  ];
}
