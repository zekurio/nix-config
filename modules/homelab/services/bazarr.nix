{ config
, lib
, pkgs
, ...
}:
let
  mediaShare = config.modules.homelab.mediaShare;
  shareUser = mediaShare.user;
  shareGroup = mediaShare.group;
in
{
  options.services.bazarr-wrapped = {
    enable = lib.mkEnableOption "Bazarr subtitle manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Bazarr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 6767;
      description = "Port for Bazarr to listen on";
    };
  };

  config = lib.mkIf config.services.bazarr-wrapped.enable {
    services.bazarr = {
      enable = true;
      user = shareUser;
      group = shareGroup;
      package = pkgs.bazarr;
    };

    # Set umask for shared library access
    systemd.services.bazarr.serviceConfig = {
      User = shareUser;
      Group = shareGroup;
      UMask = lib.mkForce mediaShare.umask;
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."bazarr" = {
      domain = config.services.bazarr-wrapped.domain;
      extraConfig = ''
        redir /bazarr /bazarr/
        @bazarr path /bazarr*
        reverse_proxy @bazarr localhost:${toString config.services.bazarr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /bazarr
        }
      '';
    };
  };
}