{
  config,
  lib,
  ...
}:
let
  shareUser = "share";
  shareGroup = "share";
  domain = "arr.schnitzelflix.xyz";
  port = 7474;
in
{
  options.services.autobrr-wrapped = {
    enable = lib.mkEnableOption "autobrr torrent automation tool with Caddy integration";
  };

  config = lib.mkIf config.services.autobrr-wrapped.enable {
    services.autobrr = {
      enable = true;
      secretFile = config.sops.secrets.autobrr_secret.path;
      settings = {
        host = "0.0.0.0";
        port = port;
        baseUrl = "/autobrr/";
        baseUrlModeLegacy = false;
        logLevel = "INFO";
        checkForUpdates = true;
      };
    };

    # SOPS secret for autobrr session secret
    sops.secrets.autobrr_secret = {
      owner = shareUser;
      group = shareGroup;
      mode = "0400";
    };

    services.caddy-wrapper.virtualHosts."autobrr" = {
      domain = domain;
      extraConfig = ''
        # Block access from outside local/tailscale networks
        @blocked not remote_ip 192.168.0.0/16 100.64.0.0/10 127.0.0.1/8
        respond @blocked "Access denied" 403

        redir /autobrr /autobrr/
        @autobrr path /autobrr*
        reverse_proxy @autobrr localhost:${toString port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /autobrr
        }
      '';
    };
  };
}
