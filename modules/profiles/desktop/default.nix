# Desktop profile - graphical desktop environment configuration
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (lib)
    mkAfter
    mkBefore
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkDefault
    types
    ;

  cfg = config.profiles.desktop;
  niriCfg = cfg.niri;
  niriEnabled = niriCfg.enable;

  desktopPackages = import ./packages.nix;
  niriSettings = import ./niri.nix;
in
{
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
  ];

  options.profiles.desktop = {
    enable = mkEnableOption "Graphical desktop profile";

    user = mkOption {
      type = types.str;
      default = config.profiles.dev.user;
      description = "User that receives the desktop configuration.";
    };

    desktopPackageSet = mkOption {
      type = types.lazyAttrsOf types.anything;
      default = if pkgs ? unstable then pkgs.unstable else pkgs;
      description = ''
        Package set to use for desktop applications that need newer builds.
        Override this on hosts that already follow an unstable channel to avoid
        importing it twice.
      '';
    };

    niri = {
      enable = mkEnableOption "Niri desktop configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = config.profiles.dev.enable;
          message = "profiles.desktop requires profiles.dev to be enabled";
        }
      ];

      home-manager.sharedModules = mkAfter [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
      ];

      home-manager.users.${cfg.user} =
        { pkgs, config, ... }:
        mkMerge [
          {
            home.packages = mkAfter (desktopPackages pkgs cfg.desktopPackageSet);
          }
          (mkIf niriEnabled {
            services.gnome-keyring.enable = true;

            programs.niri.settings = niriSettings { inherit config; };

            programs.dankMaterialShell = {
              enable = true;
              niri = {
                enableKeybinds = false;
                enableSpawn = false;
              };
            };

            # Browser configuration (Firefox)
            programs.firefox = {
              enable = true;
              policies = {
                DisableTelemetry = true;
                DisableFirefoxStudies = true;
                PasswordManagerEnabled = false;
                Preferences = {
                  "cookiebanners.service.mode.privateBrowsing" = 2;
                  "cookiebanners.service.mode" = 2;
                  "privacy.donottrackheader.enabled" = true;
                  "privacy.fingerprintingProtection" = true;
                };
                ExtensionSettings = {
                  "uBlock0@raymondhill.net" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "pywalfox@frewacom.org" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "jid1-xUfzOsOFlzSOXg@jetpack" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/reddit-enhancement-suite/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "{9063c2e9-e07c-4c2c-9646-cfe7ca8d0498}" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/old-reddit-redirect/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "{bd6be57d-91d7-41d2-b61d-3ba20f7942e5}" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/kagi-translate/latest.xpi";
                    installation_mode = "force_installed";
                  };
                  "moz-addon@7tv.app" = {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/7tv-nightly-extension/latest.xpi";
                    installation_mode = "force_installed";
                  };
                };
              };
            };

            # Terminal configuration (Ghostty)
            programs.ghostty = {
              enable = true;
              settings = {
                font-family = "GeistMono Nerd Font Mono";
                font-size = 12;
                window-decoration = false;
                window-padding-x = 12;
                window-padding-y = 12;
                background-opacity = 0.90;
                background-blur-radius = 32;
                cursor-style = "block";
                cursor-style-blink = true;
                scrollback-limit = 3023;
                mouse-hide-while-typing = true;
                copy-on-select = false;
                confirm-close-surface = false;
                unfocused-split-opacity = 0.7;
                unfocused-split-fill = "#44464f";
                gtk-titlebar = false;
                shell-integration = "detect";
                shell-integration-features = "cursor,sudo,title,no-cursor";
                config-file = "./config-dankcolors";
                keybind = [
                  "ctrl+shift+n=new_window"
                  "ctrl+t=new_tab"
                  "ctrl+plus=increase_font_size:1"
                  "ctrl+minus=decrease_font_size:1"
                  "ctrl+zero=reset_font_size"
                  "shift+enter=text:\\n"
                ];
              };
            };

            # Theme configuration (GTK, cursor, XDG dirs)
            gtk = {
              enable = true;
              font.name = "Geist";
              iconTheme = {
                name = "Papirus-Dark";
                package = pkgs.papirus-icon-theme;
              };
            };

            xdg.userDirs = {
              enable = true;
              desktop = "$HOME/Desktop";
              documents = "$HOME/Documents";
              download = "$HOME/Downloads";
              music = "$HOME/Music";
              pictures = "$HOME/Pictures";
              publicShare = "$HOME/Public";
              templates = "$HOME/Templates";
              videos = "$HOME/Videos";
            };

            home.pointerCursor = {
              gtk.enable = true;
              x11.enable = true;
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 20;
            };
          })
        ];
    }
    (mkIf niriEnabled {
      services.gnome.gnome-keyring.enable = mkDefault true;
      security.polkit.enable = true;

      # Disable niri-flake's default polkit agent as DMS has its own
      systemd.user.services.niri-flake-polkit.enable = false;

      services = {
        accounts-daemon.enable = true;
        dbus.enable = true;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };
      };

      programs.niri = {
        enable = true;
      };

      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

      services.seatd.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      xdg.portal = {
        enable = true;
        extraPortals = mkAfter [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
        config.common.default = mkBefore [
          "gnome"
          "gtk"
        ];
      };

      systemd.services.greetd.environment = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "20";
        XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
      };

      programs.dankMaterialShell.greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/${cfg.user}";
      };

      users.users.${cfg.user}.extraGroups = mkAfter [
        "audio"
        "render"
        "seat"
      ];

      environment = {
        sessionVariables.NIXOS_OZONE_WL = "1";
        variables = {
          XCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = "20";
        };
      };

      fonts.packages = with pkgs; [
        geist-font
        material-symbols
        nerd-fonts.geist-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
    })
  ]);
}
