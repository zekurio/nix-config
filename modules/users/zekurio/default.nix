{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.modules.users.zekurio;
in
{
  options.modules.users.zekurio = {
    enable = mkEnableOption "zekurio user configuration";

    homeManager = {
      enable = mkEnableOption "home-manager configuration for zekurio";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # System-level user configuration
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
    }

    # Home-manager configuration
    (mkIf cfg.homeManager.enable {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";

        users.zekurio = {
          home = {
            username = "zekurio";
            homeDirectory = "/home/zekurio";
            stateVersion = "25.05";
            enableNixpkgsReleaseCheck = false;

            packages = with pkgs; [
              age
              bat
              btop
              eza
              envsubst
              pfetch-rs
              git
              jq
              nil
              nixd
              sops
              zellij
            ];
          };

          programs = {
            direnv = {
              enable = true;
              nix-direnv.enable = true;
            };

            eza = {
              enable = true;
              extraOptions = [
                "--group-directories-first"
                "--icons=auto"
              ];
            };

            zsh = {
              enable = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;
              oh-my-zsh = {
                enable = true;
                plugins = [
                  "git"
                  "sudo"
                  "direnv"
                ];
                theme = "robbyrussell";
              };
              initContent = ''
                # Disable greeting
                unsetopt BEEP
              '';
            };

            git = {
              enable = true;
              signing = {
                key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq";
                signByDefault = true;
              };
              settings = {
                user = {
                  name = "Michael Schwieger";
                  email = "git@zekurio.xyz";
                };
                init.defaultBranch = "main";
                pull.rebase = true;
                rebase.autoStash = true;
                gpg.format = "ssh";
              };
            };

            ssh = {
              enable = true;
              enableDefaultConfig = false;
              matchBlocks."*".compression = true;
            };
          };
        };
      };
    })
  ]);
}
