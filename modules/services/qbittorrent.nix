{ config, lib, pkgs, ... }:

{
  options.services.qbittorrent-wrapped = {
    enable = lib.mkEnableOption "qBittorrent with VPN confinement";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "qbt.schnitzelflix.xyz";
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
    };

    # Caddy virtual host configuration with base URL
    services.caddy-wrapper.virtualHosts."qbittorrent" = {
      domain = config.services.qbittorrent-wrapped.domain;
      extraConfig = ''
        redir /qbt /qbt/
        @qbt path /qbt*
        reverse_proxy @qbt 192.168.15.1:${toString config.services.qbittorrent-wrapped.webuiPort} {
          header_up Host {http.request.host}
          header_up X-Forwarded-Prefix /qbt
        }
      '';
    };
  };
}
