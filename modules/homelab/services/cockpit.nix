{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.modules.homelab.cockpit;
in
{
  options.modules.homelab.cockpit = with lib; {
    enable = mkEnableOption "Enable Cockpit web-based server management interface";

    allowedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.0.0/24" "100.64.0.0/10" ];
      description = ''
        List of allowed origins for Cockpit connections.
        By default, allows local network (192.168.0.0/24) and Tailscale network (100.64.0.0/10).
      '';
    };

    port = mkOption {
      type = types.port;
      default = 9090;
      description = "Port for Cockpit to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      port = cfg.port;
      settings = {
        "WebService" = {
          "Origins" = lib.mkForce (lib.concatStringsSep " " (cfg.allowedOrigins ++ [ "127.0.0.1" "::1" ]));
          "ProtocolHeader" = "X-Forwarded-Proto";
        };
        "Session" = {
          "IdleTimeout" = "15";
        };
      };
    };

    # Configure firewall to allow cockpit connections
    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
    };

    # Cockpit package (modules like machines, storaged, etc. are not
    # available as separate packages in nixpkgs - they're either built
    # into cockpit or need to be installed via other means)
    environment.systemPackages = with pkgs; [
      cockpit
    ];
  };
}