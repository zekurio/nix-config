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

    # If using VPN, modify the systemd service to run in the namespace
    systemd.services.prowlarr = lib.mkIf config.services.prowlarr-wrapped.useVpn {
      after = [ "wireguard-ns.service" ];
      requires = [ "wireguard-ns.service" ];
      serviceConfig = {
        # Run in network namespace
        NetworkNamespacePath = "/var/run/netns/${config.services.prowlarr-wrapped.vpnNamespace}";
        # Bind to all interfaces in namespace
        Environment = "PROWLARR__BindAddress=0.0.0.0";
      };
    };

    # Create a bridge to access Prowlarr from the host
    systemd.services.prowlarr-proxy = lib.mkIf config.services.prowlarr-wrapped.useVpn {
      description = "Proxy to access Prowlarr in VPN namespace";
      after = [ "prowlarr.service" ];
      wants = [ "prowlarr.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString config.services.prowlarr-wrapped.port},fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec ${config.services.prowlarr-wrapped.vpnNamespace} ${pkgs.socat}/bin/socat STDIO TCP:localhost:${toString config.services.prowlarr-wrapped.port}'";
      };
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."prowlarr" = {
      domain = config.services.prowlarr-wrapped.domain;
      extraConfig = ''
        handle_path /prowlarr/* {
          reverse_proxy localhost:${toString config.services.prowlarr-wrapped.port}
        }
      '';
    };
  };
}
