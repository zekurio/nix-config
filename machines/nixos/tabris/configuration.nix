{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../default.nix
  ];

  # WSL configuration
  wsl = {
    enable = true;
    defaultUser = "zekurio";
    startMenuLaunchers = true;

    # Enable native Docker/Podman support instead of Docker Desktop integration
    docker-desktop.enable = false;

    # WSL-specific interop settings
    interop = {
      includePath = true;
      register = true;
    };

    # Mount Windows drives
    wslConf = {
      automount = {
        enabled = true;
        root = "/mnt";
        options = "metadata,umask=22,fmask=11";
      };
      network = {
        generateHosts = true;
        generateResolvConf = true;
      };
    };
  };

  # Networking
  networking = {
    hostName = "tabris";
    firewall.enable = false; # WSL handles this at the Windows level
  };

  # Enable nix-ld for running unpatched dynamic binaries
  programs.nix-ld = {
    enable = true;
  };

  # Development-ready packages
  environment.systemPackages = with pkgs; [
    # WSL utilities
    wslu
  ];

  # wsl2-ssh-agent: forwards SSH agent requests to Windows SSH agent
  # Requires Windows OpenSSH agent service to be running
  home-manager.users.zekurio = {
    home.packages = [ pkgs.wsl2-ssh-agent ];

    programs.zsh.initContent = lib.mkAfter ''
      # Initialize wsl2-ssh-agent for Windows SSH agent forwarding
      if [[ -z "$SSH_AUTH_SOCK" ]]; then
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
        if ! ${pkgs.socat}/bin/socat -u OPEN:/dev/null UNIX-CONNECT:"$SSH_AUTH_SOCK" &>/dev/null; then
          rm -f "$SSH_AUTH_SOCK"
          (setsid ${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent -socket "$SSH_AUTH_SOCK" &>/dev/null &)
        fi
      fi
    '';
  };

  # Time zone (inherits from Windows)
  time.timeZone = "Europe/Vienna";

  # DO NOT TOUCH THIS
  system.stateVersion = "25.05";
}
