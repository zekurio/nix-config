{
  config,
  lib,
  pkgs,
  ...
}:
let
  shareUser = "share";
  shareGroup = "share";
  shareUmask = "0002";
  domain = "schnitzelflix.xyz";
  port = 8096;
in
{
  options.services.jellyfin-wrapped = {
    enable = lib.mkEnableOption "Jellyfin media server with Caddy integration";
  };

  config = lib.mkIf config.services.jellyfin-wrapped.enable {
    services.jellyfin = {
      enable = true;
      user = shareUser;
      group = shareGroup;
      openFirewall = true;
      dataDir = "/var/lib/jellyfin";
      cacheDir = "/var/cache/jellyfin";
    };

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    systemd.tmpfiles.rules = [
      "d /var/cache/jellyfin 2775 ${shareUser} ${shareGroup} -"
    ];

    systemd.services.jellyfin = {
      serviceConfig = {
        UMask = lib.mkForce shareUmask;
        ReadWritePaths = [
          "/var/cache/jellyfin"
          "/var/lib/jellyfin"
        ];
      };
    };

    services.caddy-wrapper.virtualHosts."jellyfin" = {
      domain = domain;
      reverseProxy = "localhost:${toString port}";
      extraConfig = ''
        # TODO: Enable CORS when stats.schnitzelflix.xyz is added to unbound DNS
        # @cors_preflight {
        #   method OPTIONS
        #   header Origin https://stats.schnitzelflix.xyz
        # }
        # handle @cors_preflight {
        #   header Access-Control-Allow-Origin "https://stats.schnitzelflix.xyz"
        #   header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        #   header Access-Control-Allow-Headers "Content-Type, Authorization, X-Emby-Authorization"
        #   header Access-Control-Allow-Credentials "true"
        #   header Access-Control-Max-Age "86400"
        #   respond "" 204
        # }
        #
        # @cors_request {
        #   header Origin https://stats.schnitzelflix.xyz
        # }
        # header @cors_request Access-Control-Allow-Origin "https://stats.schnitzelflix.xyz"
        # header @cors_request Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        # header @cors_request Access-Control-Allow-Headers "Content-Type, Authorization, X-Emby-Authorization"
        # header @cors_request Access-Control-Allow-Credentials "true"
      '';
    };
  };
}
