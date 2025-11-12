{ lib, ... }: {
  imports = [
    ./common.nix
    ./browser.nix
    ./hyprland
  ];

  config.services.gnome.gnome-keyring.enable = lib.mkDefault true;
}
