{
  config,
  lib,
  pkgs,
  ...
}: let
  shareUser = "share";
  shareGroup = "share";
  shareUmask = "0002";
  domain = "arr.schnitzelflix.xyz";
  port = 6969;
in {
  options.services.whisparr-wrapped = {
    enable = lib.mkEnableOption "Whisparr adult content manager with Caddy integration";
  };

  config = lib.mkIf config.services.whisparr-wrapped.enable {
    services.whisparr = {
      enable = true;
      user = shareUser;
      group = shareGroup;
    };

    # Set umask for shared library access
    systemd.services.whisparr.serviceConfig = {
      User = shareUser;
      Group = shareGroup;
      UMask = lib.mkForce shareUmask;
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."whisparr" = {
      inherit domain;
      extraConfig = ''
        redir /whisparr /whisparr/
        @whisparr path /whisparr*
        reverse_proxy @whisparr localhost:${toString port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /whisparr
        }
      '';
    };
  };
}
