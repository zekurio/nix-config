{ config, lib, pkgs, ... }:

{
  options.services.navidrome-wrapped = {
    enable = lib.mkEnableOption "Navidrome music server with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "nv.zekurio.xyz";
      description = "Domain name for Navidrome";
    };
    musicFolder = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/fast-nvme/media/music";
      description = "Path to music folder";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 4533;
      description = "Port for Navidrome to listen on";
    };
  };

  config = lib.mkIf config.services.navidrome-wrapped.enable {
    services.navidrome = {
      enable = true;
      settings = {
        MusicFolder = config.services.navidrome-wrapped.musicFolder;
        Address = "127.0.0.1";
        Port = config.services.navidrome-wrapped.port;
        BaseUrl = "/";
      };
      group = "zekurio";
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."navidrome" = {
      domain = config.services.navidrome-wrapped.domain;
      reverseProxy = "localhost:${toString config.services.navidrome-wrapped.port}";
    };
  };
}
