{ config, lib, ... }:
let
  cfg = config.services.jfa-go-wrapped;
in
{
  options.services.jfa-go-wrapped = {
    enable = lib.mkEnableOption "jfa-go (Jellyfin Accounts Go) with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "accounts.schnitzelflix.xyz";
      description = "Domain name for jfa-go";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8056;
      description = "Port for jfa-go";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.jfa-go = {
      image = "hrfee/jfa-go";
      ports = [ "${toString cfg.port}:8056" ];
      volumes = [
        "/var/lib/jfa-go:/data"
        "/var/lib/jellyfin:/jf"
        "/etc/localtime:/etc/localtime:ro"
      ];
      autoStart = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jfa-go 0755 root root -"
    ];

    services.caddy-wrapper.virtualHosts."jfa-go" = {
      domain = cfg.domain;
      reverseProxy = "localhost:${toString cfg.port}";
    };
  };
}
