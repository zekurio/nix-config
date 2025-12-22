{ config, lib, ... }:
let
  domain = "stats.schnitzelflix.xyz";
  port = 3000;
  dataDir = "/var/lib/streamystats";
in
{
  options.services.streamystats-wrapped = {
    enable = lib.mkEnableOption "StreamyStats Jellyfin analytics with Caddy integration";
  };

  config = lib.mkIf config.services.streamystats-wrapped.enable {
    virtualisation.oci-containers.containers.streamystats = {
      image = "fredrikburmester/streamystats-v2-aio:latest";
      ports = [ "127.0.0.1:${toString port}:3000" ];
      volumes = [
        "${dataDir}/postgresql:/var/lib/postgresql/data"
      ];
      environmentFiles = [
        config.sops.secrets.streamystats_env.path
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/postgresql 0755 root root -"
    ];

    # SOPS secret for streamystats environment variables
    # Should contain: SESSION_SECRET and POSTGRES_PASSWORD
    sops.secrets.streamystats_env = {
      mode = "0400";
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."streamystats" = {
      inherit domain;
      reverseProxy = "localhost:${toString port}";
    };
  };
}
