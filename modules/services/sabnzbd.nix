{ config, lib, pkgs, ... }:

{
  options.services.sabnzbd-wrapped = {
    enable = lib.mkEnableOption "SABnzbd Usenet downloader with Caddy integration";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "sab.schnitzelflix.xyz";
      description = "Domain name for SABnzbd";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for SABnzbd to listen on";
    };
  };

  config = lib.mkIf config.services.sabnzbd-wrapped.enable {
    services.sabnzbd = {
      enable = true;
      group = "zekurio";
      openFirewall = true;
      configFile = "/var/lib/sabnzbd/sabnzbd.ini";
    };

    # Add sabnzbd user to zekurio group for media access
    users.groups.zekurio.members = [ "sabnzbd" ];

    # Ensure SABnzbd has access to download directories
    systemd.services.sabnzbd.serviceConfig = {
      ReadWritePaths = [ "/var/cache/downloads" ];
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."sabnzbd" = {
      domain = config.services.sabnzbd-wrapped.domain;
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.sabnzbd-wrapped.port}
      '';
    };
  };
}
