{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCcQoZiY9wkJ+U93isE8B3CKLmzL7TPzVh3ugE1WPJq";
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        rebase.autoStash = true;
        gpg.format = "ssh";
        commit.gpgSign = true;
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*".compression = true;
    };
  };
}
