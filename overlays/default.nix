{ ... }:

{
  nixpkgs.config.allowUnfree = true;
  
  nixpkgs.overlays = [
    # Add overlays here
    (import ./jellyfin-ffmpeg.nix)
  ];
}
