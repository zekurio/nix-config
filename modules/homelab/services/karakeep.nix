{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "karakeep.zekurio.xyz";
  port = 3000;
in
{
  options.services.karakeep-wrapped = {
    enable = lib.mkEnableOption "Karakeep bookmark management with Caddy integration";
  };

  config = lib.mkIf config.services.karakeep-wrapped.enable {
    services.karakeep = {
      enable = true;
      extraEnvironment = {
        PORT = toString port;
        HOST = "0.0.0.0";
        NEXTAUTH_URL = "https://${domain}";
        # Disable signups by default for security
        DISABLE_SIGNUPS = "true";
      };
    };

    # Open firewall port
    networking.firewall.allowedTCPPorts = [ port ];

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."karakeep" = {
      domain = domain;
      reverseProxy = "localhost:${toString port}";
    };

    # Add karakeep user to share group for media access
    users.users.karakeep.extraGroups = [ "share" ];
  };
}