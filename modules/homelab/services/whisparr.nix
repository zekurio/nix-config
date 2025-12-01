{
  config,
  lib,
  pkgs,
  ...
}:
let
  mediaShare = config.modules.homelab.mediaShare;
  shareUser = mediaShare.user;
  shareGroup = mediaShare.group;
in
{
  options.services.whisparr-wrapped = {
    enable = lib.mkEnableOption "Whisparr adult content manager with Caddy integration";
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
      package = pkgs.whisparr;
    };

    systemd.services.whisparr.serviceConfig = {
      User = shareUser;
      Group = shareGroup;
      UMask = lib.mkForce mediaShare.umask;
    };

    # Caddy virtual host configuration with base URL
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
