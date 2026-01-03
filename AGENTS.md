# Agent Guidelines for nix-config

This repository contains NixOS configurations for homelab infrastructure. Agents should follow these guidelines when making changes.

## Build & Verification

### Build Commands
- **Build specific host**: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- **Build all**: `nix build .#`
- **Check flake outputs**: `nix flake check`
- **List available packages**: `nix flake show`

### Apply Changes
- **Switch config**: `nixos-rebuild switch --flake .#<host>` (e.g., `adam`, `tabris`)
- **Remote sudo**: Add `--use-remote-sudo` for remote deployments
- **Dry run**: Add `--dry-run` to preview changes without applying
- **Show diff**: `nixos-rebuild diff --flake .#<host>` before switching

### Linting & Formatting
- **No auto-formatter**: This project does not use alejandra or other formatters
- **Manual review**: Review changes carefully before committing
- **Validate flake**: `nix fmt --check .` (reports syntax errors only)

### Testing
- **No unit tests**: Configuration is validated by building only
- **VM test**: Not configured; verify by building

## Code Style

### Indentation & Formatting
- **Indentation**: 2 spaces (soft tabs)
- **Line length**: No hard limit, but keep lines readable
- **No trailing whitespace**: Remove on save
- **Lists/attrs**: One item per line, aligned vertically

### Naming Conventions
- **Variables/functions**: `camelCase` (e.g., `myVariable`, `enableService`)
- **Module options**: `camelCase` within `services.<name>` namespace
- **Host names**: lowercase (e.g., `adam`, `tabris`)
- **Package names**: Follow nixpkgs convention (hyphens allowed)

### Module Pattern
```nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.services.<name>;
  domain = "example.com";
in
{
  options.services.<name> = {
    enable = lib.mkEnableOption "Service description";
    # ... other options
  };

  config = lib.mkIf cfg.enable {
    # ... configuration
  };
}
```

### Imports & Dependencies
- **Keep imports at file top**: Sorted alphabetically
- **Use inputs parameter**: Access flake inputs via `inputs.<name>`
- **Minimize redundancy**: Leverage shared modules in `modules/`

### Options Definition
- **Use lib.mkEnableOption**: For boolean toggles
- **Use lib.mkOption**: For typed options with proper types
- **Document options**: Add `description` to every option
- **Types**: Use `lib.types.str`, `lib.types.int`, `lib.types.bool`, `lib.types.path`

### Conditionals
- **Use lib.mkIf**: For conditional config blocks
- **Avoid if-then-else**: Prefer `lib.mkIf cfg.enable { ... }`
- **Complex conditions**: Use `lib.mkMerge` for merging conditional attrsets

### Error Handling
- **No exceptions**: Nix configs don't have runtime errors
- **Validate types**: Ensure option types match expected values
- **Check null values**: Use `lib.mkDefault` for optional sensible defaults
- **Debug**: Use `lib.trace` or `lib.traceSeq` for debugging config evaluation

### Secrets Management
- **NEVER commit plain text secrets**: Use `sops-nix` only
- **Secrets location**: `secrets/<host>.yaml` encrypted with SOPS
- **Reference secrets**: Use `sops.secrets.<name>.path` or `config.sops.secrets.<name>.yaml`

## Repository Structure

```
├── machines/nixos/<host>/     # Host-specific configs (configuration.nix, disko.nix)
├── modules/                   # Reusable modules
│   ├── homelab/services/      # Service modules (immich, jellyfin, etc.)
│   ├── system/                # System-level modules
│   ├── users/                 # User configurations
│   └── virtualization/        # VM/container modules
├── overlays/                  # Nix overlays (package modifications)
├── secrets/                   # SOPS-encrypted secrets
├── flake.nix                  # Flake entry point
└── AGENTS.md                  # This file
```

## Workflow

1. **Analyze dependencies**: Start by reading `flake.nix` to understand inputs and structure
2. **Read existing files**: Always read files before editing to understand context
3. **Build to verify**: Run build command after any changes
4. **Use sops-nix**: For all sensitive data - never hardcode credentials
5. **Commit atomic changes**: Group related changes in single commits

## Common Patterns

### Service Module Skeleton
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.<service-name>;
in
{
  options.services.<service-name> = {
    enable = lib.mkEnableOption "Service description";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    # Service config
    # Firewall rules
    # Environment variables
    # User/group setup
  };
}
```

### Caddy Integration Pattern
```nix
services.caddy-wrapper.virtualHosts."<name>" = {
  domain = domain;
  reverseProxy = "localhost:${toString port}";
  # or
  fileServer = "/var/www";
};
```

### Database/Storage Pattern
```nix
services.postgresql.enable = true;
# or
services.<service>.database.createLocally = true;
```

## Hosts Reference

| Host | Description | Platform |
|------|-------------|----------|
| `adam` | Homelab server | x86_64-linux |
| `tabris` | Workstation/WSL | x86_64-linux |

## Tips for Agents

- **Incremental builds**: Use `--max-jobs` to limit parallel builds
- **Offline mode**: Use `--offline` with pre-fetched dependencies
- **Garbage collection**: `nix-collect-jarbage -d` to clean old generations
- **Cache reuse**: Builds use cached substitutes when available
