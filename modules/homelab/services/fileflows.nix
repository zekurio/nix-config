{
  config,
  lib,
  ...
}:
let
  shareUser = "share";
  shareGroup = "share";
  shareUid = 995;
  shareGid = 995;
  port = 5000;
  domain = "ff.schnitzelflix.xyz";
in
{
  options.services.fileflows-wrapped = {
    enable = lib.mkEnableOption "FileFlows media processing with Caddy integration";
  };

  config = lib.mkIf config.services.fileflows-wrapped.enable {
    virtualisation.oci-containers.containers.fileflows = {
      image = "revenz/fileflows";
      ports = [ "${toString port}:5000" ];
      environment = {
        TempPathHost = "/tmp/fileflows";
        TZ = "Europe/Vienna";
        PUID = toString shareUid;
        PGID = toString shareGid;
      };
      volumes = [
        "/tmp/fileflows:/temp"
        "fileflows_data:/app/Data"
        "fileflows_logs:/app/Logs"
        "/mnt/downloads:/mnt/downloads"
      ];
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
      ];
    };

    # Create required directories with proper permissions
    systemd.tmpfiles.rules = [
      "d /tmp/fileflows 2775 ${shareUser} ${shareGroup} -"
    ];

    # Caddy virtual host configuration
    services.caddy-wrapper.virtualHosts."fileflows" = {
      inherit domain;
      reverseProxy = "localhost:${toString port}";
    };
  };
}
