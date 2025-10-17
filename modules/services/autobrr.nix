{ config, lib, pkgs, ... }:

{
  options.services.autobrr-wrapped = {
    enable = lib.mkEnableOption "autobrr torrent automation tool with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for autobrr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 7474;
      description = "Port for autobrr to listen on";
    };
  };

  config = lib.mkIf config.services.autobrr-wrapped.enable {
    services.autobrr = {
      enable = true;
      # Temporary placeholder - you should create a proper secret file
      secretFile = pkgs.writeText "autobrr-secret" "sessionSecret=changeme";
    };

    services.caddy-wrapper.virtualHosts."autobrr" = {
      domain = config.services.autobrr-wrapped.domain;
      extraConfig = ''
        redir /autobrr /autobrr/
        @autobrr path /autobrr*
        reverse_proxy @autobrr localhost:${toString config.services.autobrr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /autobrr
        }
      '';
    };
  };
}