# Agent Guidelines for nix-config

## Build & Verification

- **Build**: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- **Check**: `nix flake check` to verify flake outputs.
- **Apply**: `nixos-rebuild switch --flake .#<host>` (use `--use-remote-sudo` if needed).
- **Test**: No unit tests. Verify by building.
- **Format**: No auto-formatter. Follow existing style manually.

### Available Hosts

| Host | Type | Key Features |
|------|------|--------------|
| `adam` | Homelab server | Podman services, backups, VPN |
| `lilith` | Desktop workstation | Niri compositor, DMS greeter |

## Code Style & Conventions

- **Style**: 2 spaces indent, `camelCase` naming, sorted imports at top.
- **Structure**:
  - `machines/nixos/<host>/`: Host-specific configuration (configuration.nix, disko.nix).
  - `modules/`: Reusable modules (prefer over ad-hoc config).
  - `modules/homelab/`: Self-hosted services (adam only).
  - `modules/desktop/`: Desktop environment modules (lilith only).
  - `modules/gaming/`, `modules/graphics/`, `modules/virtualization/`: Hardware & feature modules.
  - `secrets/`: Managed via `sops-nix`. NEVER commit plain text.
- **Flake**: Uses `flake-parts` with nixpkgs-25.11 and nixpkgs-unstable.
- **Safety**: Verify `flake.lock` changes. Use `nix repl` to inspect.
- **Formatting**: Mimic existing code. Align lists/attrs.
- **Functions**: Use `let` bindings for complex logic, avoid inline expressions.
- **Options**: Define custom options with proper types and defaults.
- **Imports**: Keep at top of file, sorted alphabetically.

## Workflow

- **Plan**: Analyze `flake.nix` and imports first.
- **Edit**: Use `read` to verify file content before editing.
- **Verify**: Run build command after changes.
- **Secrets**: Always use `sops-nix` for sensitive data. Never commit plain text.
