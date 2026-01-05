# Agent Guidelines for nix-config

NixOS configurations for homelab infrastructure.

## Build & Verification

```bash
# Build specific host (fastest verification) - hosts: adam, tabris, lilith
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Check all flake outputs
nix flake check

# Switch config (on target host)
nixos-rebuild switch --flake .#<host>

# Remote deployment
nixos-rebuild switch --flake .#<host> --use-remote-sudo

# Preview changes
nixos-rebuild dry-run --flake .#<host>
```

### Linting & Testing
- **No formatter**: This project does not use alejandra/nixfmt
- **No unit tests**: Configuration validated by building only
- **Always verify**: Run build command after every change

## Code Style

### Formatting
- **Indentation**: 2 spaces
- **Lists/attrs**: One item per line
- **Function args**: Multi-line, opening brace on first line

### Naming Conventions
- **Variables**: `camelCase` (e.g., `shareUser`, `networkIP`)
- **Wrapper services**: `-wrapped` suffix (e.g., `jellyfin-wrapped`)
- **Hosts**: lowercase (e.g., `adam`, `tabris`)

### Module Pattern
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "service.example.com";
  port = 8080;
in
{
  options.services.<name>-wrapped = {
    enable = lib.mkEnableOption "Service description";
  };

  config = lib.mkIf config.services.<name>-wrapped.enable {
    services.<name>.enable = true;
    
    services.caddy-wrapper.virtualHosts."<name>" = {
      domain = domain;
      reverseProxy = "localhost:${toString port}";
    };
  };
}
```

### Key Functions
- `lib.mkEnableOption`: Boolean toggles
- `lib.mkOption`: Typed options with `lib.types.*`
- `lib.mkIf`: Conditional config blocks
- `lib.mkMerge`: Merge conditional attrsets
- `lib.mkForce`: Override inherited values
- `lib.mkDefault`: Overridable defaults

### Secrets (sops-nix)
- **NEVER commit plain text secrets**
- Secrets: `secrets/<host>.yaml` (encrypted with age)
- Keys: `.sops.yaml` defines age keys per host
- Reference: `config.sops.secrets.<name>.path`

## Repository Structure

```
├── machines/nixos/<host>/   # Host configs (configuration.nix, disko.nix)
├── modules/
│   ├── homelab/services/    # Service modules (immich, jellyfin, etc.)
│   ├── system/              # System-level modules
│   └── users/               # User configurations
├── overlays/                # Package modifications
├── secrets/                 # SOPS-encrypted secrets
└── flake.nix                # Flake entry point
```

## Common Patterns

### Shared User/Group
```nix
let
  shareUser = "share";
  shareGroup = "share";
  shareUmask = "0002";
in {
  services.<name>.user = shareUser;
  systemd.services.<name>.serviceConfig.UMask = lib.mkForce shareUmask;
}
```

### SOPS in Host Config
```nix
sops = {
  defaultSopsFile = ../../../secrets/<host>.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";
  secrets.<name> = { };
};

# In service
systemd.services.<name>.serviceConfig.EnvironmentFile = 
  [ config.sops.secrets.<name>_env.path ];
```

## Hosts

| Host    | Description     | Special Modules                  |
|---------|-----------------|----------------------------------|
| `adam`  | Homelab server  | disko, sops-nix, vpn-confinement |
| `tabris`| WSL workstation | nixos-wsl                        |
| `lilith`| Additional host | disko                            |

## Workflow

1. Read `flake.nix` to understand inputs and structure
2. Read existing files before editing
3. Build to verify after changes
4. Use sops-nix for secrets (never hardcode)
5. Commit atomic changes

## Tips

- `nix flake show` to list all outputs
- `nix-collect-garbage -d` to clean old generations
- Check `nixConfig` in flake.nix for binary caches
- Use `lib.trace` for debugging evaluation
