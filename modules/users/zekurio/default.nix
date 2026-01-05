{
  pkgs,
  lib,
  config,
  ...
}:
let
  use1Password = config.networking.hostName != "adam";
  onePassPath = "~/.1password/agent.sock";
in
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
        "gamemode"
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

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.zekurio = {
      home = {
        username = "zekurio";
        homeDirectory = "/home/zekurio";
        stateVersion = "25.05";

        packages = with pkgs; [
          age
          bat
          btop
          claude-code
          eza
          envsubst
          pfetch-rs
          git
          jq
          nil
          nixd
          opencode
          sops
          zellij
        ];
      };

      # Suppress version mismatch warning
      home.enableNixpkgsReleaseCheck = false;

      # Font configuration
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [ "Inter" ];
          monospace = [ "Fira Code" ];
        };
      };

      # MangoHud configuration
      xdg.configFile."MangoHud/MangoHud.conf".text = ''
        control=mangohud
        full
        cpu_temp
        gpu_temp
        ram
        vram
        io_read
        io_write
        arch
        gpu_name
        cpu_power
        gpu_power
        wine
        frametime
      '';

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        cursorTheme = {
          name = "BreezeX-RosePine-Linux";
          package = pkgs.rose-pine-cursor;
          size = 32;
        };
        font = {
          name = "Inter";
          size = 11;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
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

        gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
          };
        };

        git = {
          enable = true;
          signing = lib.mkIf (!use1Password) {
            key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq";
            signByDefault = true;
          };
          settings = lib.mkMerge [
            {
              user = {
                name = "Michael Schwieger";
                email = "git@zekurio.xyz";
              };
              init.defaultBranch = "main";
              pull.rebase = true;
              rebase.autoStash = true;
              gpg.format = "ssh";
            }
            (lib.mkIf use1Password {
              "gpg \"ssh\"".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
              commit.gpgsign = true;
              user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq";
            })
          ];
        };

        ssh = {
          enable = true;
          enableDefaultConfig = false;
          extraConfig = lib.mkIf use1Password ''
            Host *
                IdentityAgent ${onePassPath}
          '';
          matchBlocks."*".compression = true;
        };
      };
    };
  };
}
