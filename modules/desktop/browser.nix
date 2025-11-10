{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkAfter
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.desktop.browser.brave;
in {
  options.modules.desktop.browser.brave.enable =
    mkEnableOption "Managed Brave browser with enterprise policies";

  config = mkIf cfg.enable {
    environment.systemPackages = mkAfter [
      # (pkgs.brave.override {
      #   commandLineArgs = [
      #     "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks"
      #     "--ignore-gpu-blocklist"
      #     "--enable-zero-copy"
      #   ];
      # })
      pkgs.brave
      pkgs.firefox
      pkgs.pywalfox-native
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
  };
}
