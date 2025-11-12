{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkAfter
    mkIf
    mkMerge
    optionalAttrs
    ;
  cfg = config.modules.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    home-manager.sharedModules = mkAfter [
      inputs.dankMaterialShell.homeModules.dankMaterialShell.default
      ({pkgs, ...}: {
        services.gnome-keyring.enable = true;
        home.packages = mkAfter [
          pkgs.gcr
        ];
      })
    ];

    home-manager.users.${cfg.user} = {
      wayland.windowManager.hyprland = {
        enable = true;
        settings = mkMerge [
          {
            env = [
              "QT_QPA_PLATFORM,wayland"
              "ELECTRON_OZONE_PLATFORM_HINT,auto"
              "QT_QPA_PLATFORMTHEME,gtk3"
              "QT_QPA_PLATFORMTHEME_QT6,gtk3"
              "TERMINAL,ghostty"
            ];

            exec-once = [
              "uwsm app -- wl-clip-persist --clipboard both"
              "uwsm app -- wl-paste --watch cliphist store &"
              "uwsm app -- dms run"
              "uwsm app -- /usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
              "uwsm app -- ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
            ];

            general = {
              gaps_in = 5;
              gaps_out = 5;
              border_size = 0;
              "col.active_border" = "rgba(707070ff)";
              "col.inactive_border" = "rgba(d0d0d0ff)";
              layout = "dwindle";
            };

            decoration = {
              rounding = 6;
              shadow = {
                enabled = true;
                range = 30;
                render_power = 5;
                offset = "0 5";
                color = "rgba(00000070)";
              };
            };

            animations = {
              enabled = true;
              animation = [
                "windowsIn, 1, 3, default"
                "windowsOut, 1, 3, default"
                "workspaces, 1, 5, default"
                "windowsMove, 1, 4, default"
                "fade, 1, 3, default"
                "border, 1, 3, default"
              ];
            };

            dwindle = {
              preserve_split = true;
            };

            master = {
              mfact = 0.5;
            };

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              vrr = 1;
            };

            windowrulev2 = [
              "rounding 6, class:^(org.gnome.)"
              "noborder, class:^(org.gnome.)"
              "float, class:^(.blueman-manager-wrapped)$"
              "size 720 480, class:^(.blueman-manager-wrapped)$"
              "float, class:^(blender)$, title:^(Blender Render)$"
              "float, class:^(blender)$, title:^(Preferences)$"
              "float, class:^(steam)$"
              "float, class:^(org.gnome.FileRoller)$"
              "float, class:^(brave-.*-Default)$"
              "float, opacity 1, title:^(Picture in picture)$"
              "size 1280 720, class:^(steam)$"
              "float, class:^(xdg-desktop-portal)$"
              "size 1280 720, class:^(xdg-desktop-portal)$"
              "float, class:^(xdg-desktop-portal-gtk)$"
              "size 1280 720, class:^(xdg-desktop-portal-gtk)$"
              "float, class:^(org.gnome.Showtime)$"
              "size 1280 720, class:^(org.gnome.Showtime)$"
              "float, class:^(org.gnome.Loupe)$"
              "size 1280 720, class:^(org.gnome.Loupe)$"
              "float, class:^(Bitwarden)$"
              "size 1280 720, class:^(Bitwarden)$"
              "float, class:^(org.gnome.Nautilus)$"
              "size 1280 720, class:^(org.gnome.Nautilus)$"
              "float, class:^(com.saivert.pwvucontrol)$"
              "size 1280 720, class:^(com.saivert.pwvucontrol)$"
              "float, class:^(org.coolercontrol.CoolerControl)$"
              "size 1280 720, class:^(org.coolercontrol.CoolerControl)$"
              "noborder, class:^(com.mitchellh.ghostty)$"
              "workspace special:term, class:^(com.mitchellh.ghostty.zellij)$"
              "workspace special:comms, class:^(vesktop)$"
              "workspace special:music, class:^(feishin)$"
            ];

            layerrule = [
              "noanim, ^(quickshell)$"
            ];

            "$mainMod" = "Super";
            "$altMod" = "Alt";
            "$shiftMod" = "Shift";
            "$ctrlMod" = "Control";
            "$mainAlt" = "$mainMod $altMod";
            "$mainCtrl" = "$mainMod $ctrlMod";
            "$mainShift" = "$mainMod $shiftMod";
            "$ctrlShift" = "$ctrlMod $shiftMod";
            "$ctrlAlt" = "$ctrlMod $altMod";
            "$handbreaker" = "$mainCtrl $mainShift";

            bind = [
              "$mainMod, Return, exec, ghostty"
              "$mainMod, E, exec, nautilus"
              "$mainMod, Space, exec, dms ipc call spotlight toggle"
              "$mainMod, V, exec, dms ipc call clipboard toggle"
              "$mainMod, M, exec, dms ipc call processlist toggle"
              "$mainMod, comma, exec, dms ipc call settings toggle"
              "$mainMod, N, exec, dms ipc call notifications toggle"
              "$mainShift, N, exec, dms ipc call notepad toggle"
              "$mainMod, Y, exec, dms ipc call dankdash wallpaper"
              "$mainMod, TAB, exec, dms ipc call hypr toggleOverview"
              "$mainMod, L, exec, dms ipc call lock lock"
              "$mainMod, Escape, exec, dms ipc call powermenu toggle"
              "CTRL ALT, Delete, exec, dms ipc call processlist toggle"
              "$mainMod, Q, killactive"
              "$mainAlt, F, fullscreen, 1"
              "$mainShift, F, fullscreen, 0"
              "$mainMod, F, togglefloating"
              "$mainMod, W, togglegroup"
              "$mainMod, left, movefocus, l"
              "$mainMod, down, movefocus, d"
              "$mainMod, up, movefocus, u"
              "$mainMod, right, movefocus, r"
              "$mainMod, H, movefocus, l"
              "$mainMod, J, movefocus, d"
              "$mainMod, K, movefocus, u"
              "$mainMod, L, movefocus, r"
              "$mainShift, left, movewindow, l"
              "$mainShift, down, movewindow, d"
              "$mainShift, up, movewindow, u"
              "$mainShift, right, movewindow, r"
              "$mainShift, H, movewindow, l"
              "$mainShift, J, movewindow, d"
              "$mainShift, K, movewindow, u"
              "$mainShift, L, movewindow, r"
              "$mainMod, Home, focuswindow, first"
              "$mainMod, End, focuswindow, last"
              "$mainMod, Page_Down, workspace, e+1"
              "$mainMod, Page_Up, workspace, e-1"
              "$mainMod, U, workspace, e+1"
              "$mainMod, I, workspace, e-1"
              "$mainCtrl, down, movetoworkspace, e+1"
              "$mainCtrl, up, movetoworkspace, e-1"
              "$mainCtrl, U, movetoworkspace, e+1"
              "$mainCtrl, I, movetoworkspace, e-1"
              "$mainShift, Page_Down, movetoworkspace, e+1"
              "$mainShift, Page_Up, movetoworkspace, e-1"
              "$mainShift, U, movetoworkspace, e+1"
              "$mainShift, I, movetoworkspace, e-1"
              "$mainMod, mouse_down, workspace, e+1"
              "$mainMod, mouse_up, workspace, e-1"
              "$mainCtrl, mouse_down, movetoworkspace, e+1"
              "$mainCtrl, mouse_up, movetoworkspace, e-1"
              "$mainMod, 1, workspace, 1"
              "$mainMod, 2, workspace, 2"
              "$mainMod, 3, workspace, 3"
              "$mainMod, 4, workspace, 4"
              "$mainMod, 5, workspace, 5"
              "$mainMod, 6, workspace, 6"
              "$mainMod, 7, workspace, 7"
              "$mainMod, 8, workspace, 8"
              "$mainMod, 9, workspace, 9"
              "$mainShift, 1, movetoworkspace, 1"
              "$mainShift, 2, movetoworkspace, 2"
              "$mainShift, 3, movetoworkspace, 3"
              "$mainShift, 4, movetoworkspace, 4"
              "$mainShift, 5, movetoworkspace, 5"
              "$mainShift, 6, movetoworkspace, 6"
              "$mainShift, 7, movetoworkspace, 7"
              "$mainShift, 8, movetoworkspace, 8"
              "$mainShift, 9, movetoworkspace, 9"
              "$mainCtrl, F, resizeactive, exact 100%"
              "$altMod, T, togglespecialworkspace, term"
              "$altMod, M, togglespecialworkspace, music"
              "$altMod, C, togglespecialworkspace, comms"
              "$altMod, S, togglespecialworkspace, scratchpad"
              '' , Print, exec, bash -lc 'd="$(xdg-user-dir PICTURES)/screenshots"; mkdir -p "$d"; f="$d/$(date +%F_%H-%M-%S).png"; grimblast copysave area "$f" && notify-send -i "$f" "Screenshot saved" "$f"' ''
              '' $mainMod, Print, exec, bash -lc 'd="$(xdg-user-dir PICTURES)/screenshots"; mkdir -p "$d"; f="$d/$(date +%F_%H-%M-%S).png"; grimblast copysave screen "$f" && notify-send -i "$f" "Screenshot saved" "$f"' ''
              ", XF86AudioPlay, exec, dms ipc call mpris playPause"
              ", XF86AudioPause, exec, dms ipc call mpris playPause"
              ", XF86AudioNext, exec, dms ipc call mpris next"
              ", XF86AudioPrev, exec, dms ipc call mpris previous"
            ];

            bindel = [
              ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
              ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
              ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
              ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
            ];

            bindl = [
              ", XF86AudioMute, exec, dms ipc call audio mute"
              ", XF86AudioMicMute, exec, dms ipc call audio micmute"
            ];

            binde = [
              "$mainMod, minus, resizeactive, -10% 0"
              "$mainMod, equal, resizeactive, 10% 0"
              "$mainShift, minus, resizeactive, 0 -10%"
              "$mainShift, equal, resizeactive, 0 10%"
            ];

            bindm = [
              "$mainMod, mouse:272, movewindow"
              "$mainMod, mouse:273, resizewindow"
            ];
          }
          (optionalAttrs (cfg.monitors != []) { monitor = cfg.monitors; })
          (optionalAttrs (cfg.input != {}) { input = cfg.input; })
        ];
      };

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

      gtk = {
        enable = true;
        font = {
          name = "Geist";
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      xdg = {
        userDirs = {
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
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 20;
      };

      programs.dankMaterialShell = {
        enable = true;
        quickshell.package = inputs.quickshell.packages.${pkgs.system}.default;
      };
    };
  };
}
