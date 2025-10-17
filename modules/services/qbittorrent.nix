{ config, lib, pkgs, ... }:

{
  options.services.qbittorrent-wrapped = {
    enable = lib.mkEnableOption "qBittorrent with VPN confinement";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "qbit.schnitzelflix.xyz";
      description = "Domain name for qBittorrent";
    };
    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for qBittorrent WebUI to listen on";
    };
    torrentingPort = lib.mkOption {
      type = lib.types.port;
      default = 6881;
      description = "Port for incoming torrent connections";
    };
  };

  config = lib.mkIf config.services.qbittorrent-wrapped.enable {
    services.qbittorrent = {
      enable = true;
      user = "zekurio";
      group = "zekurio";
      webuiPort = config.services.qbittorrent-wrapped.webuiPort;
      torrentingPort = config.services.qbittorrent-wrapped.torrentingPort;
      openFirewall = false; # Managed through VPN namespace
      
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          WebUI = {
            Address = "0.0.0.0";  # Bind to all interfaces in the namespace
            Port = config.services.qbittorrent-wrapped.webuiPort;
          };
          Connection = {
            PortRangeMin = config.services.qbittorrent-wrapped.torrentingPort;
          };
          Downloads = {
            SavePath = "/var/downloads/completed/torrent";
          };
        };
      };
      
      extraArgs = [ "--confirm-legal-notice" ];
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."qbittorrent" = {
      domain = config.services.qbittorrent-wrapped.domain;
      reverseProxy = "192.168.15.1:${toString config.services.qbittorrent-wrapped.webuiPort}";
    };
  };
}
