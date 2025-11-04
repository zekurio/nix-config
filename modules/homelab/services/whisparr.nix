{
  config,
  lib,
  ...
}: let
  shareUser = "share";
  shareGroup = "share";
in {
  options.services.whisparr-wrapped = {
    enable = lib.mkEnableOption "Whisparr adult media manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Whisparr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 6969;
      description = "Port for Whisparr to listen on";
    };
  };

  config = lib.mkIf config.services.whisparr-wrapped.enable {
    services.whisparr = {
      enable = true;
      user = shareUser;
      group = shareGroup;
    };

    systemd.services.whisparr.serviceConfig = {
      User = shareUser;
      Group = shareGroup;
      UMask = lib.mkForce "0002";
    };

    services.caddy-wrapper.virtualHosts."whisparr" = {
      domain = config.services.whisparr-wrapped.domain;
      extraConfig = ''
        redir /whisparr /whisparr/
        @whisparr path /whisparr*
        reverse_proxy @whisparr localhost:${toString config.services.whisparr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /whisparr
        }
      '';
    };
  };
}
