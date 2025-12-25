{
  config,
  lib,
  ...
}:
let
  domain = "stats.schnitzelflix.xyz";
  port = 3000;
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
        "streamystats_postgres:/var/lib/postgresql/data"
      ];
      environmentFiles = [
        config.sops.secrets.streamystats_env.path
      ];
    };

    sops.secrets.streamystats_env = {
      mode = "0400";
    };

    services.caddy-wrapper.virtualHosts."streamystats" = {
      inherit domain;
      reverseProxy = "localhost:${toString port}";
    };
  };
}
