_: prev: {
  jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
    # Exact version of ffmpeg_* depends on what jellyfin-ffmpeg package is using.
    # In 24.11 it's ffmpeg_7-full.
    # See jellyfin-ffmpeg package source for details
    ffmpeg_7-full = prev.ffmpeg_7-full.override {
      withMfx = false; # This corresponds to the older media driver
      withVpl = true; # This is the new driver
      withUnfree = true;
    };
  };
}
