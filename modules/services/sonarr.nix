{ config, lib, pkgs, ... }:

{
  options.services.sonarr-wrapped = {
    enable = lib.mkEnableOption "Sonarr TV show manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Sonarr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8989;
      description = "Port for Sonarr to listen on";
    };
  };

  config = lib.mkIf config.services.sonarr-wrapped.enable {
    services.sonarr = {
      enable = true;
      group = "zekurio";
      openFirewall = true;
    };

    # Add sonarr user to zekurio group for media access
    users.groups.zekurio.members = [ "sonarr" ];

    # Configure Sonarr's URL base
    systemd.services.sonarr.environment = {
      Sonarr__Server__UrlBase = "/sonarr";
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."sonarr" = {
      domain = config.services.sonarr-wrapped.domain;
      extraConfig = ''
        redir /sonarr /sonarr/
        @sonarr path /sonarr*
        reverse_proxy @sonarr localhost:${toString config.services.sonarr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /sonarr
        }
      '';
    };
  };
}
