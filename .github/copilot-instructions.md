# NixOS Configuration Copilot Instructions

## Project Overview

This is a personal NixOS flake-based configuration managing multiple machines (`adam` - media server, `lilith` - Hyprland desktop). Uses `flake-parts` for modular structure, `disko` for declarative disk partitioning, and custom overlays for package modifications.

## Architecture & Structure

### Flake Organization
- **`flake.nix`**: Central entry point defining all `nixosConfigurations` and inputs
- **`machines/nixos/*/`**: Per-machine configurations (hardware, services, boot params)
- **`modules/`**: Reusable configuration modules
  - `nixos/common.nix`: Shared settings (flakes, cachix substituters)
  - `users/zekurio/`: User account definition with SSH keys
- **`overlays/`**: Package modifications (e.g., `jellyfin-ffmpeg.nix` enables VPL hardware acceleration)

### Import Pattern
Machine configs follow this layering:
```nix
imports = [
  (modulesPath + "/installer/scan/not-detected.nix")  # Hardware detection
  ./disko.nix                                          # Disk layout
  ../default.nix                                       # Users (imports ../../modules/users/zekurio)
  ../../../overlays                                    # Package overrides (adam only)
  ../../../modules/nixos/common.nix                    # Shared Nix settings
];
```

## Critical Conventions

### Disko Configuration
- **Always update `device = "/dev/sda"` in `disko.nix` before deploying** (must match target hardware)
- Standard layout: 512M ESP boot partition + LUKS-encrypted ext4 root
- LUKS settings: `allowDiscards = true` and `bypassWorkqueues = true` for SSD optimization

### SSH & Security
- **Remote LUKS unlock**: `adam` enables SSH in initrd with `boot.initrd.network.ssh.enable = true`
- User SSH keys defined once in `modules/users/zekurio/default.nix` and reused everywhere (including initrd)
- Default password hash in user module **must be changed before production** (`openssl passwd -6`)

### State Version
- `system.stateVersion = "25.05"` tracks initial install version - **never modify on existing systems**
- When adding new machines, match the current NixOS release version

## Development Workflows

### Deploying a Configuration
Use the automated `deploy.sh` script (preferred):
```bash
./deploy.sh --host 192.168.2.100 --flake adam
```

Skip disk partitioning if already configured:
```bash
./deploy.sh --host 192.168.2.100 --flake adam --skip-disko
```

### Testing Configuration Changes Locally
```bash
# Build without switching
nixos-rebuild build --flake .#adam

# Test on current system (if compatible)
sudo nixos-rebuild test --flake .#adam
```

### Adding a New Machine
1. Create `machines/nixos/<name>/configuration.nix` and `disko.nix`
2. Add to `flake.nix` under `flake.nixosConfigurations`
3. Update disko device path for target hardware
4. Follow import pattern from existing machines

## Machine-Specific Notes

### adam (Media Server)
- **Services**: Jellyfin with hardware transcoding (Intel VPL)
- **Overlay**: Custom `jellyfin-ffmpeg` with `withVpl = true` for QSV
- **Hardware**: AMD CPU with `k10temp` monitoring, Intel GPU with `vpl-gpu-rt`
- **Remote unlock**: SSH into initrd on port 22, auto-prompts for LUKS password (`shell = "/bin/cryptsetup-askpass"`)
- **Auto-login**: `getty.autologinUser = "zekurio"` for headless operation

### lilith (Desktop)
- **WM**: Hyprland with UWSM session management
- **Display**: AMD GPU with all power features (`amdgpu.ppfeaturemask=0xffffffff`)
- **Audio**: PipeWire with ALSA/PulseAudio compatibility
- **Tools**: LACT for AMD GPU control (systemd service enabled)
- **Boot**: Latest kernel (`linuxPackages_latest`) with quiet splash screen

## Common Tasks

### Modifying Package Dependencies
- Add packages to `environment.systemPackages` in machine config
- For nixpkgs-wide changes, use overlays in `overlays/default.nix`
- Override pattern: `prev.package.override { option = value; }`

### Adding Cachix Substituters
Update both `flake.nix` (nixConfig) and `modules/nixos/common.nix` (nix.settings) to ensure consistency across bare installs and built systems

### Debugging Boot Issues
- Check kernel params in `boot.kernelParams` (e.g., `acpi_enforce_resources=lax` for hardware quirks)
- For initrd issues, SSH into adam's initrd or use `boot.shell_on_fail` (lilith)
- Verify module loading with `boot.kernelModules`

## External Dependencies

- **flake inputs**: `nixpkgs` (25.05), `disko`, `flake-parts`, `autoaspm` (adam only)
- **Cachix**: Three substituters configured (cachix.org, nixpkgs, nix-community)
- **Hardware**: Expects AMD CPUs (`k10temp`, `kvm-amd` modules)

## Do NOT

- Change `system.stateVersion` on existing systems (only set during first install)
- Deploy without updating disko device paths
- Use default password hash in production
- Add `nixpkgs.config.allowUnfree = true` outside overlays (already set globally)
- Forget to test overlay changes against actual jellyfin-ffmpeg package version (FFmpeg major version matters)