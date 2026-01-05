# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Deploy to a running system (run on the target host)
sudo nixos-rebuild switch --flake .#<hostname>

# Test configuration without switching
sudo nixos-rebuild test --flake .#<hostname>

# Build and show what would change
nixos-rebuild dry-run --flake .#<hostname>

# Update flake inputs
nix flake update
```

Hosts: `adam` (homelab server), `tabris` (WSL), `lilith` (workstation)

## Architecture

### Flake Structure
- `flake.nix` defines hosts in the `hosts` attrset with system architecture and modules
- Each host gets `sharedModules` (from `machines/nixos/default.nix`) plus host-specific modules
- Overlays are applied globally via `./overlays`

### Module Organization

**machines/nixos/**: Host-specific configurations
- `default.nix`: Shared settings for all NixOS hosts (locale, nix settings, gc)
- `<hostname>/configuration.nix`: Per-host hardware, services, networking
- `<hostname>/disko.nix`: Declarative disk partitioning (disko)

**modules/homelab/**: Self-hosted service modules (adam only)
- Services follow a `-wrapped` pattern: `services.<name>-wrapped.enable = true`
- Each service module defines its own NixOS options and integrates with `caddy-wrapper`
- `caddy.nix` provides `services.caddy-wrapper.virtualHosts` for automatic reverse proxy configuration

**modules/users/**: User configurations with home-manager integration

**modules/virtualization/**: Podman container runtime (`modules.virtualization.enable`)

### Key Patterns

**Service wrapper pattern** (in `modules/homelab/services/`):
```nix
options.services.<name>-wrapped = {
  enable = lib.mkEnableOption "...";
};
config = lib.mkIf config.services.<name>-wrapped.enable {
  services.<name> = { /* actual service config */ };
  services.caddy-wrapper.virtualHosts."<name>" = {
    domain = "example.com";
    reverseProxy = "localhost:PORT";
  };
};
```

**Secrets**: SOPS-nix with age encryption. Keys defined in `.sops.yaml`, secrets in `secrets/`.

**VPN Confinement**: qBittorrent runs in a WireGuard namespace (`vpnNamespaces.mullvad`).
