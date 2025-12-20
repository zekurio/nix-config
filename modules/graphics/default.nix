{ pkgs, ... }:
{
  imports = [
    ./amd.nix
    ./intel.nix
  ];

  environment.systemPackages = with pkgs; [
    pciutils
  ];
}
