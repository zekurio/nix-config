{
  pkgs,
  ...
}:
{
  nix.settings.trusted-users = [ "zekurio" ];

  users = {
    users = {
      zekurio = {
        shell = pkgs.bash;
        uid = 1000;
        isNormalUser = true;
        # PLACEHOLDER-HASH: This will be replaced during deployment
        hashedPassword = "PLACEHOLDER-HASH";
        extraGroups = [
          "wheel"
          "users"
          "video"
          "podman"
          "input"
        ];
        group = "zekurio";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq"
        ];
      };
    };
    groups = {
      zekurio = {
        gid = 1000;
      };
    };
  };
}
