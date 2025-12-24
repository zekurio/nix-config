# Agent Guidelines for nix-config

## Build & Verification
- **Build**: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- **Check**: `nix flake check` to verify flake outputs
- **Apply**: `nixos-rebuild switch --flake .#<host>` (use `--use-remote-sudo` if needed)
- **Test**: No unit tests. Verify by building. No auto-formatter.
- **Hosts**: `adam` (homelab server), `tabris` (WSL)

## Code Style
- **Indent**: 2 spaces. **Naming**: `camelCase` for variables/functions
- **Module pattern**: `{ config, lib, pkgs, ... }:` with `let cfg = config.services.<name>;`
- **Imports**: Keep at file top, sorted alphabetically
- **Options**: Use `lib.mkOption` with proper types; use `lib.mkEnableOption` for toggles
- **Conditionals**: Use `lib.mkIf` for conditional config blocks
- **Lists/attrs**: Align items vertically, one per line for readability

## Structure
- `machines/nixos/<host>/`: Host configs (configuration.nix, disko.nix)
- `modules/`: Reusable modules. `modules/homelab/`: Services for adam
- `secrets/`: Managed via `sops-nix`. **NEVER commit plain text secrets**

## Workflow
1. Analyze `flake.nix` and imports first
2. Read files before editing to verify content
3. Run build command after changes to verify
4. Use `sops-nix` for all sensitive data
