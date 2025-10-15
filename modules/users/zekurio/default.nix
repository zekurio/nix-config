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
        hashedPassword = "$6$rSob073ER.AwVG2u$FD4btmbZ9jFPpdtslAadBDss.4CvIjshCAvFBXe3NtYjU/ydqODGsdYRMnZh5qxpGgy6mNRHeMsrJFwO6XMM./";
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
