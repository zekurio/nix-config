{ pkgs, ... }:
{
  imports = [
    ./intel.nix
  ];

  environment.systemPackages = with pkgs; [
    pciutils
  ];
}
