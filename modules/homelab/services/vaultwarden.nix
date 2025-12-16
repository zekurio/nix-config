{ config, lib, ... }:
let
  domain = "vw.zekurio.xyz";
  port = 8222;
in
{
  options.services.vaultwarden-wrapped = {
    enable = lib.mkEnableOption "Vaultwarden password manager with Caddy integration";
  };

  config = lib.mkIf config.services.vaultwarden-wrapped.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://${domain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = port;
        WEBSOCKET_ENABLED = true;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;
      };
      environmentFile = config.sops.secrets.vaultwarden_env.path;
    };

    # SOPS secret for vaultwarden environment variables
    sops.secrets.vaultwarden_env = {
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."vaultwarden" = {
      inherit domain;
      reverseProxy = "localhost:${toString port}";
    };
  };
}
