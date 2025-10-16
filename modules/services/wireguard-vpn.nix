{ config, lib, pkgs, ... }:

{
  options.services.wireguard-vpn = {
    enable = lib.mkEnableOption "WireGuard VPN connection in network namespace";
    
    namespaceName = lib.mkOption {
      type = lib.types.str;
      default = "vpn";
      description = "Name of the network namespace";
    };

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the private key file (SOPS secret)";
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of IP addresses for the WireGuard interface";
      example = [ "10.0.0.2/24" ];
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "DNS servers to use through the VPN";
      example = [ "1.1.1.1" "8.8.8.8" ];
    };

    peer = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Public key of the VPN peer";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        description = "Endpoint address and port of the VPN peer";
        example = "vpn.example.com:51820";
      };

      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "0.0.0.0/0" "::/0" ];
        description = "IP ranges to route through the VPN";
      };

      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        default = 25;
        description = "Interval in seconds to send keepalive packets";
      };
    };
  };

  config = lib.mkIf config.services.wireguard-vpn.enable {
    # Create systemd service to set up the network namespace and WireGuard
    systemd.services.wireguard-ns = {
      description = "WireGuard VPN in network namespace";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ iproute2 wireguard-tools ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = let
        ns = config.services.wireguard-vpn.namespaceName;
        iface = config.services.wireguard-vpn.interfaceName;
        addresses = lib.concatStringsSep " " config.services.wireguard-vpn.address;
        dnsServers = lib.concatStringsSep "," config.services.wireguard-vpn.dns;
      in ''
        # Create network namespace
        ip netns add ${ns} || true

        # Create WireGuard interface in namespace
        ip link add ${iface} type wireguard
        ip link set ${iface} netns ${ns}

        # Configure WireGuard in namespace
        ip netns exec ${ns} ip addr add ${addresses} dev ${iface}
        ip netns exec ${ns} wg set ${iface} \
          private-key ${config.services.wireguard-vpn.privateKeyFile} \
          peer ${config.services.wireguard-vpn.peer.publicKey} \
          endpoint ${config.services.wireguard-vpn.peer.endpoint} \
          persistent-keepalive ${toString config.services.wireguard-vpn.peer.persistentKeepalive} \
          allowed-ips ${lib.concatStringsSep "," config.services.wireguard-vpn.peer.allowedIPs}

        # Bring up interface
        ip netns exec ${ns} ip link set ${iface} up
        ip netns exec ${ns} ip link set lo up

        # Set default route through VPN
        ip netns exec ${ns} ip route add default dev ${iface}

        ${lib.optionalString (dnsServers != "") ''
          # Set DNS
          mkdir -p /etc/netns/${ns}
          echo "nameserver ${lib.concatStringsSep "\nnameserver " config.services.wireguard-vpn.dns}" > /etc/netns/${ns}/resolv.conf
        ''}
      '';

      preStop = let
        ns = config.services.wireguard-vpn.namespaceName;
      in ''
        ip netns del ${ns} || true
      '';
    };

    # Enable WireGuard kernel module
    networking.firewall.allowedUDPPorts = [ 51820 ];

    # Ensure iproute2 and wireguard-tools are available
    environment.systemPackages = with pkgs; [ iproute2 wireguard-tools ];
  };
}
