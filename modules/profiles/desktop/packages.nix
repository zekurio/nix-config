# Desktop packages list
pkgs: desktopSet:
(with pkgs; [
  accountsservice
  adw-gtk3
  bibata-cursors
  brightnessctl
  pywalfox-native
  cliphist
  gearlever
  gcr
  grim
  grimblast
  loupe
  matugen
  nautilus
  seahorse
  showtime
  slurp
  wayland-utils
  wl-clip-persist
  wl-clipboard
  xdg-user-dirs
  xdg-user-dirs-gtk
  xwayland-satellite
])
++ (with desktopSet; [
  bitwarden-desktop
  deezer-enhanced
  ghostty
  jetbrains.goland
  jetbrains.idea-ultimate
  tsukimi
  vesktop
  zed-editor
])
++ [
  pkgs.nur.repos.forkprince.helium-nightly
]
