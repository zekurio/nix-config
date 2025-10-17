{ config, lib, pkgs, ... }:

{
  options.services.radarr-wrapped = {
    enable = lib.mkEnableOption "Radarr movie manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Radarr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 7878;
      description = "Port for Radarr to listen on";
    };
  };

  config = lib.mkIf config.services.radarr-wrapped.enable {
    services.radarr = {
      enable = true;
      group = "zekurio";
      openFirewall = true;
    };

    # Add radarr user to zekurio group for media access
    users.groups.zekurio.members = [ "radarr" ];

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."radarr" = {
      domain = config.services.radarr-wrapped.domain;
      extraConfig = ''
        handle_path /radarr/* {
          reverse_proxy localhost:${toString config.services.radarr-wrapped.port}
        }
      '';
    };
  };
}
