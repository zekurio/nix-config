{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.users;

  baseProfile = import ./profiles/base.nix { inherit pkgs; };
  desktopProfile = import ./profiles/desktop.nix { inherit pkgs; };
in
{
  options.modules.users = {
    enable = lib.mkEnableOption "user configuration";

    profiles = {
      base = lib.mkEnableOption "base CLI tools and configuration" // {
        default = true;
      };
      desktop = lib.mkEnableOption "desktop environment configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings.trusted-users = [ "zekurio" ];

    programs.zsh.enable = true;

    users = {
      users.zekurio = {
        shell = pkgs.zsh;
        uid = 1000;
        isNormalUser = true;
        hashedPassword = "$y$j9T$F7RSP23wOrzzmEJcTxY98.$i58fRl1nIbPjOZ4jBxLu/FWJb/i/DEytiWVtMxcd5G8";
        extraGroups = [
          "wheel"
          "users"
          "video"
          "podman"
          "input"
        ];
        group = "zekurio";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXuY93/KsNdn9B9LW4JwPGpHa5d5W0XHYttP5wdHDb8 zekurio@termius"
        ];
      };

      groups.zekurio = {
        gid = 1000;
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";

      users.zekurio = lib.mkMerge [
        # Base home-manager config
        {
          home = {
            username = "zekurio";
            homeDirectory = "/home/zekurio";
            stateVersion = "25.05";
            enableNixpkgsReleaseCheck = false;
          };
        }

        # Conditionally merge base profile
        (lib.mkIf cfg.profiles.base baseProfile)

        # Conditionally merge desktop profile
        (lib.mkIf cfg.profiles.desktop desktopProfile)
      ];
    };
  };
}
