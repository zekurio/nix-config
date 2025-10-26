{ lib
, config
, pkgs
, inputs
, pkgsUnstable
, ...
}:
let
  inherit (lib)
    hasAttrByPath
    mkAfter
    mkEnableOption
    mkIf
    mkOption
    types;
  cfg = config.modules.desktop.hyprland;
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
          pkgs.fira-code
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
        programs.dankMaterialShell.enable = true;
      };
    }
  );
}
