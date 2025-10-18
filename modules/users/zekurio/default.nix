{
  pkgs,
  ...
}:
{
  nix.settings.trusted-users = [ "zekurio" ];
  
  programs.fish.enable = true;

  users = {
    users = {
      zekurio = {
        shell = pkgs.fish;
        uid = 1000;
        isNormalUser = true;
        hashedPassword = "$6$b22Ve.o/YRXCik6.$bacQz815Lo6lu311ekb2rYOgq9uYLr0NIaHkoGeG5NJUoCsTIUHWEoJmsPH7BRrgLVmBEKWNBEbtaM5kGpzJY.";
        extraGroups = [
          "wheel"
          "users"
          "video"
          "podman"
          "input"
        ];
        group = "zekurio";
        openssh = {
          authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq"
          ];
        };
      };
    };
    groups = {
      zekurio = {
        gid = 1000;
      };
    };
  };
}

