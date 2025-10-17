{ config, lib, pkgs, ... }:

{
  options.services.prowlarr-wrapped = {
    enable = lib.mkEnableOption "Prowlarr indexer manager with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "arr.schnitzelflix.xyz";
      description = "Domain name for Prowlarr";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9696;
      description = "Port for Prowlarr to listen on";
    };
    useVpn = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run Prowlarr through the VPN namespace";
    };
    vpnNamespace = lib.mkOption {
      type = lib.types.str;
      default = "vpn";
      description = "Name of the VPN network namespace to use";
    };
  };

  config = lib.mkIf config.services.prowlarr-wrapped.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Add prowlarr user to zekurio group for coordination with other arr services
    users.groups.zekurio.members = [ "prowlarr" ];

    # Configure Prowlarr service
    systemd.services.prowlarr = lib.mkMerge [
      # Base configuration for URL base
      {
        environment = {
          Prowlarr__Server__UrlBase = "/prowlarr";
        };
      }
      # VPN-specific configuration
      (lib.mkIf config.services.prowlarr-wrapped.useVpn {
        after = [ "wireguard-ns.service" ];
        requires = [ "wireguard-ns.service" ];
        environment = {
          # Bind to all interfaces in namespace
          PROWLARR__BindAddress = "0.0.0.0";
        };
        serviceConfig = {
          # Run in network namespace
          NetworkNamespacePath = "/var/run/netns/${config.services.prowlarr-wrapped.vpnNamespace}";
        };
      })
    ];

    # Create a bridge to access Prowlarr from the host
    systemd.services.prowlarr-proxy = lib.mkIf config.services.prowlarr-wrapped.useVpn {
      description = "Proxy to access Prowlarr in VPN namespace";
      after = [ "prowlarr.service" ];
      wants = [ "prowlarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
      };
      script = ''
        ${pkgs.socat}/bin/socat \
          TCP-LISTEN:${toString config.services.prowlarr-wrapped.port},bind=0.0.0.0,fork,reuseaddr \
          EXEC:'${pkgs.iproute2}/bin/ip netns exec ${config.services.prowlarr-wrapped.vpnNamespace} ${pkgs.socat}/bin/socat STDIO TCP:127.0.0.1:${toString config.services.prowlarr-wrapped.port}',nofork
      '';
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."prowlarr" = {
      domain = config.services.prowlarr-wrapped.domain;
      extraConfig = ''
        redir /prowlarr /prowlarr/
        @prowlarr path /prowlarr*
        reverse_proxy @prowlarr localhost:${toString config.services.prowlarr-wrapped.port} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /prowlarr
        }
      '';
    };
  };
}
