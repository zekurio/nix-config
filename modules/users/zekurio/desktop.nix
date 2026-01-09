{
  config,
  lib,
  ...
}:
let
  isDesktop = config.networking.hostName == "lilith";
in
{
  config = lib.mkIf isDesktop {
    home-manager.users.zekurio = {
      # Niri configuration (raw KDL to support DMS includes)
      xdg.configFile."niri/config.kdl".text = ''
        // Niri configuration managed by Home Manager
        // https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

        config-notification {
            disable-failed
        }

        output "DP-2" {
            mode "2560x1440@164.835"
            scale 1
            transform "normal"
            variable-refresh-rate
        }

        gestures {
            hot-corners {
                off
            }
        }

        input {
            keyboard {
                xkb {
                    layout "eu"
                }
                numlock
            }
            touchpad {
            }
            mouse {
                accel-profile "flat"
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
        spawn-at-startup "bash" "-c" "wl-clip-persist --clipboard both &"

        environment {
            XDG_CURRENT_DESKTOP "niri"
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
            match app-id=r#"^steam$"#
            match app-id=r#"^xdg-desktop-portal$"#
            match app-id=r#"^io.github.celluloid_player.Celluloid$"#
            match app-id=r#"^1password$"#
            match app-id=r#"^org.gnome.Loupe$"#
            match app-id=r#"^org.gnome.Nautilus$"#
            open-floating true
        }

        window-rule {
            match app-id="com.mitchellh.ghostty"
            draw-border-with-background false
        }

        window-rule {
            match is-active=false
            opacity 0.9
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

        cursor {
            xcursor-theme "BreezeX-RosePine-Linux"
            xcursor-size 32
        }

        // DMS (DankMaterialShell) includes
        include "dms/colors.kdl"
        include "dms/layout.kdl"
        include "dms/alttab.kdl"
        include "dms/binds.kdl"
      '';

      # mangohud configuration
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

      # Ghostty configuration
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          # Font Configuration
          font-size = 12;

          # Window Configuration
          window-decoration = false;
          window-padding-x = 12;
          window-padding-y = 12;
          background-opacity = 1.0;
          background-blur-radius = 32;

          # Cursor Configuration
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

          # Tab configuration
          gtk-titlebar = false;

          # Shell integration
          shell-integration = "detect";
          shell-integration-features = "cursor,sudo,title,no-cursor";

          # GTK settings
          gtk-single-instance = true;

          # DMS color integration (absolute path required)
          config-file = "/home/zekurio/.config/ghostty/config-dankcolors";
        };
      };
    };
  };
}
