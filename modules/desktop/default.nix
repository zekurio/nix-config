{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.modules.desktop;

  # Generate raw KDL for outputs (since niri module doesn't support mode strings directly)
  outputsKdl = lib.concatStringsSep "\n\n" (
    lib.mapAttrsToList (
      name: value:
      let
        modeStr = lib.optionalString (value.mode != null) "  mode \"${value.mode}\"\n";
        vrrStr = lib.optionalString value.variableRefreshRate "  variable-refresh-rate\n";
        scaleStr = lib.optionalString (value.scale != null) "  scale ${toString value.scale}\n";
      in
      "output \"${name}\" {\n${modeStr}${vrrStr}${scaleStr}}"
    ) cfg.niri.outputs
  );
in
{
  options.modules.desktop = {
    enable = mkEnableOption "desktop environment support";

    niri = {
      outputs = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              mode = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Output mode (e.g., '1920x1080@120.003')";
              };
              scale = mkOption {
                type = types.nullOr types.float;
                default = null;
                description = "Output scale factor";
              };
              variableRefreshRate = mkOption {
                type = types.bool;
                default = false;
                description = "Enable variable refresh rate";
              };
            };
          }
        );
        default = { };
        description = "Per-output niri configuration";
      };

      xkbLayout = mkOption {
        type = types.str;
        default = "us";
        description = "XKB keyboard layout";
      };

      touchpad = {
        tap = mkOption {
          type = types.bool;
          default = false;
          description = "Enable tap-to-click on touchpad";
        };
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra KDL configuration to append to niri config";
      };
    };

    ghostty = {
      fontSize = mkOption {
        type = types.int;
        default = 12;
        description = "Font size for ghostty terminal";
      };

      backgroundOpacity = mkOption {
        type = types.float;
        default = 1.0;
        description = "Background opacity (0.0 to 1.0)";
      };

      backgroundBlurRadius = mkOption {
        type = types.int;
        default = 32;
        description = "Background blur radius";
      };

      extraSettings = mkOption {
        type = types.attrsOf (
          types.oneOf [
            types.str
            types.int
            types.float
            types.bool
            (types.listOf types.str)
          ]
        );
        default = { };
        description = "Extra ghostty settings to merge with defaults";
      };
    };
  };

  config = mkIf cfg.enable {
    # Polkit for authentication dialogs
    security.polkit.enable = true;
    # GNOME Keyring for secret management
    services.gnome.gnome-keyring.enable = true;
    # D-Bus (dependency for polkit/keyring)
    services.dbus.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    security.pam.services.greetd.text = ''
      auth substack login
      account include login
      password substack login
      session include login
    '';

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      SSH_AUTH_SOCK = "/home/zekurio/.bitwarden-ssh-agent.sock";
      # Cursor theme
      XCURSOR_THEME = "graphite-dark";
      XCURSOR_SIZE = "24";
      # Icon theme (must be system-wide for GNOME apps and DMS)
      GTK_ICON_THEME_NAME = "Papirus-Dark";
      # Wayland and Qt/Electron theming (as per DMS recommendations)
      XDG_CURRENT_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
    };

    # System-wide packages for desktop environment
    environment.systemPackages = with pkgs; [
      # Theming packages (must be system-wide for GNOME apps and DMS)
      papirus-icon-theme
      graphite-cursors
      adw-gtk3
      # GTK runtime for icon/cursor theme loading
      glib
      gtk3
      gtk4
      # Qt theming support
      libsForQt5.qt5ct
      qt6Packages.qt6ct
    ];

    # Niri compositor (from nixpkgs)
    programs.niri.enable = true;

    # DankMaterialShell (from nixpkgs-unstable)
    programs.dms-shell = {
      enable = true;
      quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      # Core features
      enableSystemMonitoring = true;
      enableClipboard = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
    };

    programs.dsearch = {
      enable = true;
      systemd.enable = true;
    };

    # DankGreeter (from nixpkgs-unstable)
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/zekurio";
    };

    # Desktop home-manager configuration
    home-manager.users.zekurio = {
      # Niri config file
      xdg.configFile."niri/config.kdl".text = ''
        // Generated by NixOS configuration
        config-notification {
            disable-failed
        }

        // Output configuration
        ${outputsKdl}

        gestures {
            hot-corners {
                off
            }
        }

        input {
            keyboard {
                xkb {
                    layout "${cfg.niri.xkbLayout}"
                }
                numlock
            }
            touchpad {
                ${lib.optionalString cfg.niri.touchpad.tap "tap"}
            }
            mouse {
            }
            trackpoint {
            }
        }

        layout {
            background-color "transparent"
            center-focused-column "never"
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }
            default-column-width { proportion 0.5; }
            border {
                off
                width 4
                active-color   "#707070"
                inactive-color "#d0d0d0"
                urgent-color   "#cc4444"
            }
            shadow {
                softness 30
                spread 5
                offset x=0 y=5
                color "#0007"
            }
            struts {
            }
        }

        layer-rule {
            match namespace="^quickshell$"
            place-within-backdrop true
        }

        overview {
            workspace-shadow {
                off
            }
        }

        spawn-at-startup "bash" "-c" "wl-paste --watch cliphist store &"

        environment {
            XDG_CURRENT_DESKTOP "niri"
            QT_QPA_PLATFORM "wayland"
            ELECTRON_OZONE_PLATFORM_HINT "auto"
            QT_QPA_PLATFORMTHEME "gtk3"
            QT_QPA_PLATFORMTHEME_QT6 "gtk3"
        }

        hotkey-overlay {
            skip-at-startup
        }

        prefer-no-csd
        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        animations {
            workspace-switch {
                spring damping-ratio=0.80 stiffness=523 epsilon=0.0001
            }
            window-open {
                duration-ms 150
                curve "ease-out-expo"
            }
            window-close {
                duration-ms 150
                curve "ease-out-quad"
            }
            horizontal-view-movement {
                spring damping-ratio=0.85 stiffness=423 epsilon=0.0001
            }
            window-movement {
                spring damping-ratio=0.75 stiffness=323 epsilon=0.0001
            }
            window-resize {
                spring damping-ratio=0.85 stiffness=423 epsilon=0.0001
            }
            config-notification-open-close {
                spring damping-ratio=0.65 stiffness=923 epsilon=0.001
            }
            screenshot-ui-open {
                duration-ms 200
                curve "ease-out-quad"
            }
            overview-open-close {
                spring damping-ratio=0.85 stiffness=800 epsilon=0.0001
            }
        }

        // Window rules
        window-rule {
            match app-id=r#"^org\.wezfurlong\.wezterm$"#
            default-column-width {}
        }
        window-rule {
            match app-id=r#"^org\.gnome\."#
            draw-border-with-background false
            geometry-corner-radius 12
            clip-to-geometry true
        }
        window-rule {
            match app-id=r#"^gnome-control-center$"#
            match app-id=r#"^pavucontrol$"#
            match app-id=r#"^nm-connection-editor$"#
            default-column-width { proportion 0.5; }
            open-floating false
        }
        window-rule {
            match app-id=r#"^gnome-calculator$"#
            match app-id=r#"^galculator$"#
            match app-id=r#"^blueman-manager$"#
            match app-id=r#"^org\.gnome\.Nautilus$"#
            match app-id=r#"^steam$"#
            match app-id=r#"^xdg-desktop-portal$"#
            open-floating true
        }
        window-rule {
            match app-id=r#"^org\.wezfurlong\.wezterm$"#
            match app-id="Alacritty"
            match app-id="zen"
            match app-id="com.mitchellh.ghostty"
            match app-id="kitty"
            draw-border-with-background false
        }
        window-rule {
            match is-active=false
            opacity 0.9
        }
        window-rule {
            match app-id=r#"firefox$"# title="^Picture-in-Picture$"
            match app-id="zoom"
            open-floating true
        }
        window-rule {
            match app-id=r#"org.quickshell$"#
            open-floating true
        }

        debug {
            honor-xdg-activation-with-invalid-serial
        }

        recent-windows {
            binds {
                Alt+Tab         { next-window scope="output"; }
                Alt+Shift+Tab   { previous-window scope="output"; }
                Alt+grave       { next-window filter="app-id"; }
                Alt+Shift+grave { previous-window filter="app-id"; }
            }
        }

        // Include DMS files
        include "dms/colors.kdl"
        include "dms/layout.kdl"
        include "dms/alttab.kdl"
        include "dms/binds.kdl"

        ${lib.optionalString (cfg.niri.extraConfig != "") ''
          // Extra configuration
          ${cfg.niri.extraConfig}''}
      '';

      programs = {
        # Terminal emulator
        ghostty = {
          enable = true;
          enableZshIntegration = true;
          settings = mkMerge [
            {
              # Font (per-host configurable)
              font-size = cfg.ghostty.fontSize;

              # Window (per-host configurable)
              window-decoration = false;
              window-padding-x = 12;
              window-padding-y = 12;
              background-opacity = cfg.ghostty.backgroundOpacity;
              background-blur-radius = cfg.ghostty.backgroundBlurRadius;

              # Cursor
              cursor-style = "block";
              cursor-style-blink = true;

              # Scrollback
              scrollback-limit = 3023;

              # Terminal features
              mouse-hide-while-typing = true;
              copy-on-select = false;
              confirm-close-surface = false;

              # Disable annoying notifications
              app-notifications = "no-clipboard-copy,no-config-reload";

              # Key bindings
              keybind = [
                "ctrl+shift+n=new_window"
                "ctrl+t=new_tab"
                "ctrl+plus=increase_font_size:1"
                "ctrl+minus=decrease_font_size:1"
                "ctrl+zero=reset_font_size"
                "shift+enter=text:\\n"
              ];

              # Material 3 UI elements
              unfocused-split-opacity = 0.7;
              unfocused-split-fill = "#44464f";

              # GTK/Tab configuration
              gtk-titlebar = false;
              gtk-single-instance = true;

              # Shell integration
              shell-integration = "detect";
              shell-integration-features = "cursor,sudo,title,no-cursor";

              # DMS dynamic theme colors
              config-file = [ "config-dankcolors" ];
            }
            cfg.ghostty.extraSettings
          ];
        };
      };

      fonts.fontconfig.enable = true;

      # Ensure icon and cursor themes are properly set
      home.sessionVariables = {
        GTK_ICON_THEME_NAME = "Papirus-Dark";
        XCURSOR_THEME = "graphite-dark";
        XCURSOR_SIZE = "24";
      };

      # XDG portal settings for theme consistency
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };

      home.packages = with pkgs; [
        # Fonts
        (nerd-fonts.symbols-only)
        inter
        fira-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
        # Theming packages moved to system packages
        # Applications
        brave
        zed-editor
        vesktop
        bitwarden-desktop
        bitwarden-cli
        deezer-enhanced
        jellyfin-desktop
        # Wayland utilities
        xwayland-satellite
        wl-clipboard
        cliphist
      ];
    };
  };
}
