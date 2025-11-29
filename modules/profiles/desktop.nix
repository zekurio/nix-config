{ lib
, pkgs
, config
, inputs
, ...
}:
let
  inherit
    (lib)
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

  bravePackage = pkgs':
    pkgs'.brave.override {
      commandLineArgs = [
        "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    };

  desktopPackages = pkgs': desktopSet:
    (with pkgs'; [
      accountsservice
      adw-gtk3
      bibata-cursors
      blueman
      brightnessctl
      (bravePackage pkgs')
      cliphist
      gcr
      grim
      grimblast
      loupe
      matugen
      nautilus
      seahorse
      showtime
      slurp
      wayland-utils
      wl-clip-persist
      wl-clipboard
      xdg-user-dirs
      xdg-user-dirs-gtk
      xwayland-satellite
    ])
    ++ (with desktopSet; [
      bitwarden-desktop
      deezer-enhanced
      ghostty
      jetbrains.goland
      jetbrains.idea-ultimate
      tsukimi
      vesktop
      zed-editor
    ]);

  niriSettings = { config, ... }: {
    config-notification.disable-failed = true;

    gestures.hot-corners.enable = false;

    input = {
      keyboard = {
        xkb = { };
        numlock = true;
      };
      touchpad = { };
      mouse = { };
      trackpoint = { };
    };

    outputs."DP-2" = {
      mode = {
        width = 2560;
        height = 1440;
        refresh = 164.835;
      };
      variable-refresh-rate = true;
    };

    layout = {
      gaps = 5;
      background-color = "transparent";
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];

      default-column-width = { proportion = 0.5; };

      border = {
        enable = false;
        width = 4;
        active.color = "#707070";
        inactive.color = "#d0d0d0";
        urgent.color = "#cc4444";
      };

      focus-ring = {
        width = 2;
        active.color = "#808080";
        inactive.color = "#505050";
      };

      shadow = {
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "#0007";
      };

      struts = { };
    };

    layer-rules = [
      {
        matches = [{ namespace = "^quickshell$"; }];
        place-within-backdrop = true;
      }
    ];

    overview.workspace-shadow.enable = false;

    spawn-at-startup = [
      { argv = [ "bash" "-c" "wl-paste --watch cliphist store &" ]; }
      { argv = [ "dms" "run" ]; }
      { argv = [ "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1" ]; }
    ];

    environment = {
      XDG_CURRENT_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
      TERMINAL = "ghostty";
    };

    hotkey-overlay.skip-at-startup = true;

    prefer-no-csd = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    animations = {
      workspace-switch.kind.spring = {
        damping-ratio = 0.80;
        stiffness = 523;
        epsilon = 0.0001;
      };
      window-open.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-expo";
      };
      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-quad";
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 423;
        epsilon = 0.0001;
      };
      window-movement.kind.spring = {
        damping-ratio = 0.75;
        stiffness = 323;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 423;
        epsilon = 0.0001;
      };
      config-notification-open-close.kind.spring = {
        damping-ratio = 0.65;
        stiffness = 923;
        epsilon = 0.001;
      };
      screenshot-ui-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-quad";
      };
      overview-open-close.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };

    window-rules = [
      # WezTerm initial configure bug workaround
      {
        matches = [{ app-id = ''^org\.wezfurlong\.wezterm$''; }];
        default-column-width = { };
      }
      # GNOME apps styling
      {
        matches = [{ app-id = ''^org\.gnome\.''; }];
        draw-border-with-background = false;
        geometry-corner-radius = {
          top-left = 12.0;
          top-right = 12.0;
          bottom-left = 12.0;
          bottom-right = 12.0;
        };
        clip-to-geometry = true;
      }
      # Settings/control apps
      {
        matches = [
          { app-id = ''^gnome-control-center$''; }
          { app-id = ''^pavucontrol$''; }
          { app-id = ''^nm-connection-editor$''; }
        ];
        default-column-width = { proportion = 0.5; };
        open-floating = false;
      }
      # Floating windows
      {
        matches = [
          { app-id = ''^gnome-calculator$''; }
          { app-id = ''^galculator$''; }
          { app-id = ''^blueman-manager$''; }
          { app-id = ''^org\.gnome\.Nautilus$''; }
          { app-id = ''^steam$''; }
          { app-id = ''^xdg-desktop-portal$''; }
        ];
        open-floating = true;
      }
      # Terminal apps - no border background
      {
        matches = [
          { app-id = ''^org\.wezfurlong\.wezterm$''; }
          { app-id = "Alacritty"; }
          { app-id = "zen"; }
          { app-id = "com.mitchellh.ghostty"; }
          { app-id = "kitty"; }
        ];
        draw-border-with-background = false;
      }
      # Inactive window opacity
      {
        matches = [{ is-active = false; }];
        opacity = 0.9;
      }
      # PiP and Zoom floating
      {
        matches = [
          { app-id = ''^firefox$''; title = "^Picture-in-Picture$"; }
          { app-id = "zoom"; }
        ];
        open-floating = true;
      }
      # Global corner radius
      {
        geometry-corner-radius = {
          top-left = 12.0;
          top-right = 12.0;
          bottom-left = 12.0;
          bottom-right = 12.0;
        };
        clip-to-geometry = true;
      }
    ];

    binds = let
      inherit (config.lib.niri.actions)
        spawn
        toggle-overview
        show-hotkey-overlay
        quit
        close-window
        maximize-column
        fullscreen-window
        toggle-window-floating
        switch-focus-between-floating-and-tiling
        toggle-column-tabbed-display
        focus-column-left
        focus-column-right
        focus-window-down
        focus-window-up
        focus-column-first
        focus-column-last
        move-column-left
        move-column-right
        move-window-down
        move-window-up
        move-column-to-first
        move-column-to-last
        focus-monitor-left
        focus-monitor-right
        focus-monitor-down
        focus-monitor-up
        move-column-to-monitor-left
        move-column-to-monitor-right
        move-column-to-monitor-down
        move-column-to-monitor-up
        focus-workspace-down
        focus-workspace-up
        focus-workspace
        move-column-to-workspace-down
        move-column-to-workspace-up
        move-workspace-down
        move-workspace-up
        consume-or-expel-window-left
        consume-or-expel-window-right
        expel-window-from-column
        switch-preset-column-width
        switch-preset-window-height
        reset-window-height
        expand-column-to-available-width
        center-column
        center-visible-columns
        set-column-width
        set-window-height
        toggle-keyboard-shortcuts-inhibit
        power-off-monitors
        ;
    in {
      # === System & Overview ===
      "Mod+D".action = spawn "niri" "msg" "action" "toggle-overview";
      "Mod+Tab" = { action = toggle-overview; repeat = false; };
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      # === Application Launchers ===
      "Mod+T" = {
        action = spawn "ghostty";
        hotkey-overlay.title = "Open Terminal";
      };
      "Mod+Space" = {
        action = spawn "dms" "ipc" "call" "spotlight" "toggle";
        hotkey-overlay.title = "Application Launcher";
      };
      "Mod+V" = {
        action = spawn "dms" "ipc" "call" "clipboard" "toggle";
        hotkey-overlay.title = "Clipboard Manager";
      };
      "Mod+M" = {
        action = spawn "dms" "ipc" "call" "processlist" "toggle";
        hotkey-overlay.title = "Task Manager";
      };
      "Mod+Comma" = {
        action = spawn "dms" "ipc" "call" "settings" "toggle";
        hotkey-overlay.title = "Settings";
      };
      "Mod+Y" = {
        action = spawn "dms" "ipc" "call" "dankdash" "wallpaper";
        hotkey-overlay.title = "Browse Wallpapers";
      };
      "Mod+N" = {
        action = spawn "dms" "ipc" "call" "notifications" "toggle";
        hotkey-overlay.title = "Notification Center";
      };
      "Mod+Shift+N" = {
        action = spawn "dms" "ipc" "call" "notepad" "toggle";
        hotkey-overlay.title = "Notepad";
      };

      # === Security ===
      "Mod+Alt+L" = {
        action = spawn "dms" "ipc" "call" "lock" "lock";
        hotkey-overlay.title = "Lock Screen";
      };
      "Mod+Shift+E".action = quit;
      "Ctrl+Alt+Delete" = {
        action = spawn "dms" "ipc" "call" "processlist" "toggle";
        hotkey-overlay.title = "Task Manager";
      };

      # === Audio Controls ===
      "XF86AudioRaiseVolume" = {
        action = spawn "dms" "ipc" "call" "audio" "increment" "3";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn "dms" "ipc" "call" "audio" "decrement" "3";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn "dms" "ipc" "call" "audio" "mute";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn "dms" "ipc" "call" "audio" "micmute";
        allow-when-locked = true;
      };

      # === Brightness Controls ===
      "XF86MonBrightnessUp" = {
        action = spawn "dms" "ipc" "call" "brightness" "increment" "5" "";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn "dms" "ipc" "call" "brightness" "decrement" "5" "";
        allow-when-locked = true;
      };

      # === Window Management ===
      "Mod+Q" = { action = close-window; repeat = false; };
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+Shift+T".action = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
      "Mod+W".action = toggle-column-tabbed-display;

      # === Focus Navigation ===
      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+L".action = focus-column-right;

      # === Window Movement ===
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+L".action = move-column-right;

      # === Column Navigation ===
      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action = move-column-to-last;

      # === Monitor Navigation ===
      "Mod+Ctrl+Left".action = focus-monitor-left;
      "Mod+Ctrl+Right".action = focus-monitor-right;
      "Mod+Ctrl+H".action = focus-monitor-left;
      "Mod+Ctrl+J".action = focus-monitor-down;
      "Mod+Ctrl+K".action = focus-monitor-up;
      "Mod+Ctrl+L".action = focus-monitor-right;

      # === Move to Monitor ===
      "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
      "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

      # === Workspace Navigation ===
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+U".action = focus-workspace-down;
      "Mod+I".action = focus-workspace-up;
      "Mod+Ctrl+Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+U".action = move-column-to-workspace-down;
      "Mod+Ctrl+I".action = move-column-to-workspace-up;

      # === Move Workspaces ===
      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action = move-workspace-up;
      "Mod+Shift+U".action = move-workspace-down;
      "Mod+Shift+I".action = move-workspace-up;

      # === Mouse Wheel Navigation ===
      "Mod+WheelScrollDown" = { action = focus-workspace-down; cooldown-ms = 150; };
      "Mod+WheelScrollUp" = { action = focus-workspace-up; cooldown-ms = 150; };
      "Mod+Ctrl+WheelScrollDown" = { action = move-column-to-workspace-down; cooldown-ms = 150; };
      "Mod+Ctrl+WheelScrollUp" = { action = move-column-to-workspace-up; cooldown-ms = 150; };

      "Mod+WheelScrollRight".action = focus-column-right;
      "Mod+WheelScrollLeft".action = focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

      "Mod+Shift+WheelScrollDown".action = focus-column-right;
      "Mod+Shift+WheelScrollUp".action = focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

      # === Numbered Workspaces ===
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      # === Move to Numbered Workspaces ===
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      # === Column Management ===
      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;
      "Mod+Period".action = expel-window-from-column;

      # === Sizing & Layout ===
      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+R".action = reset-window-height;
      "Mod+Ctrl+F".action = expand-column-to-available-width;
      "Mod+C".action = center-column;
      "Mod+Ctrl+C".action = center-visible-columns;

      # === Manual Sizing ===
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # === Screenshots ===
      "XF86Launch1".action.screenshot = { };
      "Ctrl+XF86Launch1".action.screenshot-screen = { };
      "Alt+XF86Launch1".action.screenshot-window = { };
      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };

      # === System Controls ===
      "Mod+Escape" = { action = toggle-keyboard-shortcuts-inhibit; allow-inhibiting = false; };
      "Mod+Shift+P".action = power-off-monitors;
    };

    debug = {
      honor-xdg-activation-with-invalid-serial = [ ];
    };
  };
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

  config =
    mkIf cfg.enable (
      mkMerge [
        {
          assertions = [
            {
              assertion = config.profiles.dev.enable;
              message = "profiles.desktop requires profiles.dev to be enabled";
            }
          ];

          home-manager.sharedModules =
            mkAfter [
              inputs.dankMaterialShell.homeModules.dankMaterialShell.default
              inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
            ];

          home-manager.users.${cfg.user} = { pkgs, config, ... }:
            mkMerge [
              {
                home.packages =
                  mkAfter (desktopPackages pkgs cfg.desktopPackageSet);
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

                home.file.".config/BraveSoftware/Brave-Browser/Policies/Managed/policies.json".text = ''
                  {
                    "BraveRewardsDisabled": true,
                    "BraveWalletDisabled": true,
                    "BraveVPNDisabled": 1,
                    "BraveAIChatEnabled": false,
                    "TorDisabled": true,
                    "DnsOverHttpsMode": "automatic"
                  }
                '';

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

          environment.etc."brave/policies/managed/policies.json".text = ''
            {
              "BraveRewardsDisabled": true,
              "BraveWalletDisabled": true,
              "BraveVPNDisabled": 1,
              "BraveAIChatEnabled": false,
              "TorDisabled": true,
              "DnsOverHttpsMode": "automatic"
            }
          '';
        })
      ]
    );
}
