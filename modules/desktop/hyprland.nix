{ lib
, config
, pkgs
, inputs
, pkgsUnstable
, ...
}:
let
  inherit (lib)
    attrByPath
    hasAttrByPath
    mkAfter
    mkEnableOption
    mkIf
    mkOption
    types;
  cfg = config.modules.desktop.hyprland;
  userCfg = config.users.users.${cfg.user};
  userUid = toString (userCfg.uid or 1000);
  primaryGroup = userCfg.group or "users";
  primaryGroupCfg = attrByPath [ primaryGroup ] config.users.groups { gid = 100; };
  userGid = toString (primaryGroupCfg.gid or 100);
in
{
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
  ];

  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Hyprland desktop with DankMaterialShell integration";

    user = mkOption {
      type = types.str;
      default = "zekurio";
      description = "Primary desktop user that owns the session.";
    };

    greeterCompositor = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Compositor used by the DankMaterialShell greeter.";
      example = "niri";
    };

    greeterConfigHome = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional path copied to the greeter data directory before start.";
      example = "/home/zekurio";
    };
  };

  config = mkIf cfg.enable (
    let
      defaultConfigHome = "/home/${cfg.user}";
      resolvedConfigHome =
        if cfg.greeterConfigHome != null then cfg.greeterConfigHome else defaultConfigHome;
    in
    {
      assertions = [
        {
          assertion = hasAttrByPath [ cfg.user ] config.users.users;
          message = "modules.desktop.hyprland.user must reference an existing user.";
        }
      ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };

      programs.firefox = {
        enable = true;
        package = pkgs.firefox.overrideAttrs (_old: {
          extraNativeMessagingHosts = with pkgs; [ pywalfox-native ];
        });
      };

      services.seatd.enable = true;
      security = {
        pam.services.greetd.enableGnomeKeyring = true;
        polkit.enable = true;
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [ "hyprland" "gtk" ];
        };
      };

      services.dbus.enable = true;
      services.accounts-daemon.enable = true;

      environment = {
        systemPackages = mkAfter [
          pkgs.accountsservice
          pkgs.adw-gtk3
          pkgs.bibata-cursors
          pkgs.bitwarden
          pkgs.blueman
          pkgs.brightnessctl
          pkgs.cliphist
          pkgs.delfin
          pkgs.firefox
          pkgs.ghostty
          pkgs.grim
          pkgs.grimblast
          pkgs.inter
          pkgs.loupe
          pkgs.material-symbols
          pkgs.mate.mate-polkit
          pkgs.matugen
          pkgs.nemo
          pkgs.nemo-fileroller
          pkgs.papirus-icon-theme
          pkgs.papirus-folders
          pkgs.pywalfox-native
          pkgs.seahorse
          pkgs.showtime
          pkgs.slurp
          pkgsUnstable.vesktop
          pkgs.wayland-utils
          pkgs.wl-clipboard
          pkgs.wl-clip-persist
          pkgs.xdg-user-dirs
          pkgs.xdg-user-dirs-gtk
          pkgs.xwayland-satellite
          pkgsUnstable.zed-editor
        ];
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
        variables = { XCURSOR_THEME = "Bibata-Modern-Classic"; XCURSOR_SIZE = "20"; };
      };

      systemd.services.greetd.environment = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "20";
        XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
      };

      users.users.${cfg.user}.extraGroups = mkAfter [
        "audio"
        "render"
        "seat"
      ];

      programs.dankMaterialShell.greeter = {
        enable = true;
        compositor.name = cfg.greeterCompositor;
        configHome = resolvedConfigHome;
      };

      home-manager.sharedModules = mkAfter [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        ({ pkgs, ... }: {
          services.gnome-keyring.enable = true;
          home.packages = mkAfter [
            pkgs.gcr
          ];
        })
      ];

      home-manager.users.${cfg.user} = {
        gtk = {
          enable = true;

          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };

          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
          };

          cursorTheme = {
            name = "Bibata-Modern-Classic";
            package = pkgs.bibata-cursors;
            size = 20;
          };

          gtk4.extraConfig = {
            "gtk-application-prefer-dark-theme" = 1;
          };
        };

        wayland.windowManager.hyprland = {
          enable = true;
          settings = {
            monitor = "DP-2,2560x1440@165,2560x0,1,vrr,1";

            env = [
              "QT_QPA_PLATFORM,wayland"
              "ELECTRON_OZONE_PLATFORM_HINT,auto"
              "QT_QPA_PLATFORMTHEME,gtk3"
              "QT_QPA_PLATFORMTHEME_QT6,gtk3"
              "TERMINAL,ghostty"
            ];

            exec-once = [
              "wl-clip-persist --clipboard both"
              "wl-paste --watch cliphist store &"
              "dms run"
              "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
              "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
              "$HOME/.local/share/scripts/hyprland-extension-popup-manager.sh"
            ];

            input = {
              kb_layout = "eu";
              numlock_by_default = true;
              accel_profile = "flat";
            };

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
              active_opacity = 1.0;
              inactive_opacity = 0.9;
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
              "rounding 6, class:^(org\\.gnome\\.)"
              "noborder, class:^(org\\.gnome\\.)"
              "float, class:^(.blueman-manager-wrapped)$"
              "float, class:^(steam)$"
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
              "float, class:^(nemo)$"
              "size 1280 720, class:^(nemo)$"
              "float, class:^(udiskie)$"
              "size 1280 720, class:^(udiskie)$"
              "noborder, class:^(com\\.mitchellh\\.ghostty)$"
              "float, class:^(firefox)$, title:^(Picture-in-Picture)$"
              "suppressevent maximize, class:^(firefox)$, title:^(Extension:.*)$"
              "opacity 0.9 0.9, floating:0, focus:0"
            ];

            layerrule = [
              "noanim, ^(quickshell)$"
            ];

            "\$mod" = "SUPER";

            bind = [
              "\$mod, T, exec, ghostty"
              "\$mod, E, exec, nemo"
              "\$mod, space, exec, dms ipc call spotlight toggle"
              "\$mod, V, exec, dms ipc call clipboard toggle"
              "\$mod, M, exec, dms ipc call processlist toggle"
              "\$mod, comma, exec, dms ipc call settings toggle"
              "\$mod, N, exec, dms ipc call notifications toggle"
              "\$mod SHIFT, N, exec, dms ipc call notepad toggle"
              "\$mod, Y, exec, dms ipc call dankdash wallpaper"
              "\$mod, TAB, exec, dms ipc call hypr toggleOverview"
              "\$mod, L, exec, dms ipc call lock lock"
              "\$mod SHIFT, E, exit"
              "CTRL ALT, Delete, exec, dms ipc call processlist toggle"
              "\$mod, Q, killactive"
              "\$mod, F, fullscreen, 1"
              "\$mod SHIFT, F, fullscreen, 0"
              "\$mod SHIFT, T, togglefloating"
              "\$mod, W, togglegroup"
              "\$mod, left, movefocus, l"
              "\$mod, down, movefocus, d"
              "\$mod, up, movefocus, u"
              "\$mod, right, movefocus, r"
              "\$mod, H, movefocus, l"
              "\$mod, J, movefocus, d"
              "\$mod, K, movefocus, u"
              "\$mod, L, movefocus, r"
              "\$mod SHIFT, left, movewindow, l"
              "\$mod SHIFT, down, movewindow, d"
              "\$mod SHIFT, up, movewindow, u"
              "\$mod SHIFT, right, movewindow, r"
              "\$mod SHIFT, H, movewindow, l"
              "\$mod SHIFT, J, movewindow, d"
              "\$mod SHIFT, K, movewindow, u"
              "\$mod SHIFT, L, movewindow, r"
              "\$mod, Home, focuswindow, first"
              "\$mod, End, focuswindow, last"
              "\$mod CTRL, left, focusmonitor, l"
              "\$mod CTRL, right, focusmonitor, r"
              "\$mod CTRL, H, focusmonitor, l"
              "\$mod CTRL, J, focusmonitor, d"
              "\$mod CTRL, K, focusmonitor, u"
              "\$mod CTRL, L, focusmonitor, r"
              "\$mod SHIFT CTRL, left, movewindow, mon:l"
              "\$mod SHIFT CTRL, down, movewindow, mon:d"
              "\$mod SHIFT CTRL, up, movewindow, mon:u"
              "\$mod SHIFT CTRL, right, movewindow, mon:r"
              "\$mod SHIFT CTRL, H, movewindow, mon:l"
              "\$mod SHIFT CTRL, J, movewindow, mon:d"
              "\$mod SHIFT CTRL, K, movewindow, mon:u"
              "\$mod SHIFT CTRL, L, movewindow, mon:r"
              "\$mod, Page_Down, workspace, e+1"
              "\$mod, Page_Up, workspace, e-1"
              "\$mod, U, workspace, e+1"
              "\$mod, I, workspace, e-1"
              "\$mod CTRL, down, movetoworkspace, e+1"
              "\$mod CTRL, up, movetoworkspace, e-1"
              "\$mod CTRL, U, movetoworkspace, e+1"
              "\$mod CTRL, I, movetoworkspace, e-1"
              "\$mod SHIFT, Page_Down, movetoworkspace, e+1"
              "\$mod SHIFT, Page_Up, movetoworkspace, e-1"
              "\$mod SHIFT, U, movetoworkspace, e+1"
              "\$mod SHIFT, I, movetoworkspace, e-1"
              "\$mod, mouse_down, workspace, e+1"
              "\$mod, mouse_up, workspace, e-1"
              "\$mod CTRL, mouse_down, movetoworkspace, e+1"
              "\$mod CTRL, mouse_up, movetoworkspace, e-1"
              "\$mod, 1, workspace, 1"
              "\$mod, 2, workspace, 2"
              "\$mod, 3, workspace, 3"
              "\$mod, 4, workspace, 4"
              "\$mod, 5, workspace, 5"
              "\$mod, 6, workspace, 6"
              "\$mod, 7, workspace, 7"
              "\$mod, 8, workspace, 8"
              "\$mod, 9, workspace, 9"
              "\$mod SHIFT, 1, movetoworkspace, 1"
              "\$mod SHIFT, 2, movetoworkspace, 2"
              "\$mod SHIFT, 3, movetoworkspace, 3"
              "\$mod SHIFT, 4, movetoworkspace, 4"
              "\$mod SHIFT, 5, movetoworkspace, 5"
              "\$mod SHIFT, 6, movetoworkspace, 6"
              "\$mod SHIFT, 7, movetoworkspace, 7"
              "\$mod SHIFT, 8, movetoworkspace, 8"
              "\$mod SHIFT, 9, movetoworkspace, 9"
              "\$mod, bracketleft, layoutmsg, preselect l"
              "\$mod, bracketright, layoutmsg, preselect r"
              "\$mod, R, layoutmsg, togglesplit"
              "\$mod CTRL, F, resizeactive, exact 100%"
              ", XF86Launch1, exec, grimblast copy area"
              "CTRL, XF86Launch1, exec, grimblast copy screen"
              "ALT, XF86Launch1, exec, grimblast copy active"
              ", Print, exec, grimblast copy area"
              "CTRL, Print, exec, grimblast copy screen"
              "ALT, Print, exec, grimblast copy active"
              "\$mod SHIFT, P, dpms, off"
            ];

            bindel = [
              ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
              ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
              ", XF86KbdBrightnessUp, exec, kbdbrite.sh up"
              ", XF86KbdBrightnessDown, exec, kbdbrite.sh down"
              ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
              ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
            ];

            bindl = [
              ", XF86AudioMute, exec, dms ipc call audio mute"
              ", XF86AudioMicMute, exec, dms ipc call audio micmute"
            ];

            binde = [
              "\$mod, minus, resizeactive, -10% 0"
              "\$mod, equal, resizeactive, 10% 0"
              "\$mod SHIFT, minus, resizeactive, 0 -10%"
              "\$mod SHIFT, equal, resizeactive, 0 10%"
            ];

            bindm = [
              "\$mod, mouse:272, movewindow"
              "\$mod, mouse:273, resizewindow"
            ];

            bindd = [
              "\$mod, code:20, Expand window left, resizeactive, -100 0"
              "\$mod, code:21, Shrink window left, resizeactive, 100 0"
            ];
          };
        };

        programs.ghostty = {
          enable = true;
          settings = {
            font-family = "Fira Code";
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

        services.udiskie = {
          enable = true;
          automount = true;
          notify = true;
          tray = "auto";
          settings = {
            program_options = {
              automount = true;
              notify = true;
              tray = "auto";
            };
            device_config = {
              defaults = {
                mount_options = [
                  "uid=${userUid}"
                  "gid=${userGid}"
                  "dmask=022"
                  "fmask=133"
                ];
              };
            };
          };
        };

        xdg.userDirs = {
          enable = true;
          desktop = "$HOME/desktop";
          documents = "$HOME/documents";
          download = "$HOME/downloads";
          music = "$HOME/music";
          pictures = "$HOME/pictures";
          publicShare = "$HOME/public";
          templates = "$HOME/templates";
          videos = "$HOME/videos";
        };

        home.pointerCursor = {
          gtk.enable = true;
          x11.enable = true;
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 20;
        };

        fonts.fontconfig = {
          enable = true;
          defaultFonts = {
            sansSerif = [ "Geist" ];
            monospace = [ "Geist Mono" ];
          };
        };

        programs.dankMaterialShell.enable = true;
      };
    }
  );
}
