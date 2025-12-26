{ config, lib, pkgs, ... }:
let
  domain = "docs.zekurio.xyz";
  port = 8010;
in
{
  options.services.paperless-ngx-wrapped = {
    enable = lib.mkEnableOption "Paperless-ngx document management system with Caddy integration";
  };

  config = lib.mkIf config.services.paperless-ngx-wrapped.enable {
    services.paperless = {
      enable = true;
      dataDir = "/var/lib/paperless";
      consumptionDir = "/var/lib/paperless/consume";
      consumptionDirIsPublic = true;
      port = port;
      address = "127.0.0.1";
      settings = {
        PAPERLESS_URL = "https://${domain}";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_TIME_ZONE = "Europe/Vienna";
        PAPERLESS_ENABLE_COMPRESSION = true;
        PAPERLESS_TASK_WORKERS = 2;
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        # OIDC Authentication via Dex
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      };
      # Environment file containing PAPERLESS_SOCIALACCOUNT_PROVIDERS JSON
      # See secrets/adam.yaml for the required format
      environmentFile = config.sops.secrets.paperless_env.path;
    };

    sops.secrets.paperless_env = {
      owner = "paperless";
      group = "paperless";
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/paperless/consume 0770 paperless paperless -"
    ];

    services.caddy-wrapper.virtualHosts."paperless-ngx" = {
      domain = domain;
      reverseProxy = "localhost:${toString port}";
    };

    users.users.paperless.extraGroups = [ "share" ];
  };
}
