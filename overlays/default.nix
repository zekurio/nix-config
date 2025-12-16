inputs: {
  nixpkgs.overlays = [
    (import ./jellyfin-ffmpeg.nix)
    (import ./jellyseerr-develop.nix inputs)
    (import ./unstable.nix inputs)
  ];
}
