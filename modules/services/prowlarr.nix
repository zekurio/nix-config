{ config, lib, pkgs, ... }:

{
  options.services.prowlarr-wrapped = {
    enable = lib.mkEnableOption "Prowlarr indexer manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Prowlarr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9696;
      description = "Port for Prowlarr to listen on";
    };
  };

  config = lib.mkIf config.services.prowlarr-wrapped.enable {
    services.prowlarr = {
      enable = true;
    };

    # Add prowlarr user to zekurio group for coordination with other arr services
    users.groups.zekurio.members = [ "prowlarr" ];

    # Configure Prowlarr's URL base
    systemd.services.prowlarr.environment = {
      Prowlarr__Server__UrlBase = "/prowlarr";
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."prowlarr" = {
      domain = config.services.prowlarr-wrapped.domain;
      extraConfig = ''
        redir /prowlarr /prowlarr/
        @prowlarr path /prowlarr*
        reverse_proxy @prowlarr localhost:${toString config.services.prowlarr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /prowlarr
        }
      '';
    };
  };
}
