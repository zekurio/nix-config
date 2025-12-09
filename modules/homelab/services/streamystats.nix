{
  config,
  lib,
  ...
}:
let
  cfg = config.services.streamystats-wrapped;
in
{
  options.services.streamystats-wrapped = {
    enable = lib.mkEnableOption "StreamyStats Jellyfin viewing statistics";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "stats.schnitzelflix.xyz";
      description = "Domain name for StreamyStats";
    };
    webPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for StreamyStats web interface";
    };
    jobsPort = lib.mkOption {
      type = lib.types.port;
      default = 3005;
      description = "Port for StreamyStats job server";
    };
    imageVersion = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = "Docker image version tag for StreamyStats";
    };
    database = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "PostgreSQL host";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 5432;
        description = "PostgreSQL port";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "streamystats";
        description = "PostgreSQL database name";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "streamystats";
        description = "PostgreSQL user";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # SOPS secrets
    sops.secrets.streamystats_db_password = {
      mode = "0400";
    };
    sops.secrets.streamystats_secret = {
      mode = "0400";
    };

    # SOPS template to generate environment file with interpolated secrets
    sops.templates."streamystats.env" = {
      content = ''
        DATABASE_URL=postgresql://${cfg.database.user}:${config.sops.placeholder.streamystats_db_password}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}
        AUTH_SECRET=${config.sops.placeholder.streamystats_secret}
        POSTGRES_USER=${cfg.database.user}
        POSTGRES_PASSWORD=${config.sops.placeholder.streamystats_db_password}
        POSTGRES_DB=${cfg.database.name}
        PGPASSWORD=${config.sops.placeholder.streamystats_db_password}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Use Docker backend for OCI containers
    virtualisation.oci-containers.backend = "docker";

    # StreamyStats containers
    virtualisation.oci-containers.containers = {
      # Migration container - runs once to set up database
      streamystats-migrate = {
        image = "docker.io/fredrikburmester/streamystats-v2-migrate:${cfg.imageVersion}";
        extraOptions = [ "--network=host" ];
        environmentFiles = [ config.sops.templates."streamystats.env".path ];
      };

      # Web frontend (Next.js)
      streamystats-web = {
        image = "docker.io/fredrikburmester/streamystats-v2-nextjs:${cfg.imageVersion}";
        extraOptions = [ "--network=host" ];
        environmentFiles = [ config.sops.templates."streamystats.env".path ];
        environment = {
          NODE_ENV = "production";
          HOSTNAME = "0.0.0.0";
          PORT = toString cfg.webPort;
          JOB_SERVER_URL = "http://127.0.0.1:${toString cfg.jobsPort}";
        };
        dependsOn = [ "streamystats-migrate" ];
      };

      # Job server
      streamystats-jobs = {
        image = "docker.io/fredrikburmester/streamystats-v2-job-server:${cfg.imageVersion}";
        extraOptions = [ "--network=host" ];
        environmentFiles = [ config.sops.templates."streamystats.env".path ];
        environment = {
          NODE_ENV = "production";
          PORT = toString cfg.jobsPort;
          HOST = "0.0.0.0";
        };
        dependsOn = [ "streamystats-migrate" ];
      };
    };

    # Ensure migrate container runs before web and jobs start
    # and only runs once (restart = "no")
    systemd.services.docker-streamystats-migrate = {
      serviceConfig = {
        Restart = lib.mkForce "no";
        RemainAfterExit = true;
      };
    };

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."streamystats" = {
      domain = cfg.domain;
      reverseProxy = "localhost:${toString cfg.webPort}";
    };
  };
}
