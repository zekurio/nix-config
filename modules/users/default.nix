{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    hasAttrByPath
    mkAfter
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.users.zekurio;

  defaultSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq zekurio@lilith"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAa219QnvgiicM6yAiCTwe9tPB2FJCEY75LNsf4NOsLT zekurio@adam"
  ];

  defaultGitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq";

  basePackages =
    pkgs': with pkgs'; [
      age
      bat
      btop
      eza
      envsubst
      fastfetch
      git
      jq
      nil
      nixd
      sops
      zellij
    ];
in
{
  options.users.zekurio = {
    enable = mkEnableOption "Development user setup with Home Manager" // {
      default = true;
    };

    stateVersion = mkOption {
      type = types.str;
      default = "25.05";
      description = "Home Manager stateVersion for the managed user.";
    };

    sshAuthorizedKeys = mkOption {
      type = types.listOf types.str;
      default = defaultSshAuthorizedKeys;
      description = "SSH public keys allowed to login as zekurio.";
    };

    gitSigningKey = mkOption {
      type = types.nullOr types.str;
      default = defaultGitSigningKey;
      description = "SSH public key used for Git commit signing (gpg.format=ssh).";
    };
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [ "zekurio" ];

    environment.shells = with pkgs; [ zsh ];
    environment.variables.EDITOR = "nano";

    programs.zsh.enable = true;

    users = {
      users = {
        zekurio = {
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
          openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
        };
      };
      groups = {
        zekurio = {
          gid = 1000;
        };
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };

    home-manager.users.zekurio =
      { pkgs, ... }:
      {
        home = {
          username = "zekurio";
          homeDirectory = "/home/zekurio";
          stateVersion = cfg.stateVersion;
          enableNixpkgsReleaseCheck = false;
          packages = basePackages pkgs;
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
            settings = {
              user = {
                name = "Michael Schwieger";
                email = "git@zekurio.xyz";
              } // optionalAttrs (cfg.gitSigningKey != null) {
                signingKey = cfg.gitSigningKey;
              };
              init.defaultBranch = "main";
              pull.rebase = true;
              rebase.autoStash = true;
              gpg.format = "ssh";
              gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
              commit.gpgSign = true;
            };
          };

          ssh = {
            enable = true;
            enableDefaultConfig = false;
            matchBlocks."*".compression = true;
          };
        };
      };

    environment.systemPackages = mkAfter [
      pkgs.gh
      pkgs.unstable.opencode
    ];
  };
}
