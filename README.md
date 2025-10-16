# nix-config

my personal nix configs, heavily WIP

## Quick Deploy (Recommended)

Use the automated deploy script for easy, repeatable deployments. This script handles everything from disk partitioning to NixOS installation.

### When to Use the Deploy Script

The deploy script is ideal for:
- **Fresh installations** - Setting up a new NixOS machine from scratch
- **Bare metal deployments** - Installing NixOS on physical hardware or VMs
- **Consistent deployments** - Using declarative configurations across multiple machines
- **Quick reprovisioning** - Rebuilding a system with a known configuration

**Warning**: This script will **destroy all data** on the target disk during partitioning!

### How the Deploy Script Works

The script automates the entire NixOS installation process:

1. **Validation Phase**
   - Checks SSH connectivity to the target host
   - Validates the selected flake configuration exists

2. **Disk Partitioning** (Optional, can be skipped)
   - Copies the disko configuration to the target host
   - Runs [disko](https://github.com/nix-community/disko) to partition and format the disk
   - Mounts the filesystems at `/mnt`
   - **Note**: Edit the disk device path in `machines/nixos/*/disko.nix` before deploying

3. **NixOS Installation**
   - Ensures git is available on the target system
   - Copies the entire configuration to `/mnt/etc/nixos` via rsync
   - Runs `nixos-install` with the specified flake configuration
   - Excludes `.git`, `*.bak`, and `result` from the copy

4. **Cleanup and Reboot**
   - Optionally unmounts all filesystems
   - Reboots the system into the new installation

### Usage

**Interactive Mode** (prompts for required values):
```bash
./deploy.sh
```

**Automated Mode**:
```bash
# Full automated deploy
./deploy.sh --host 192.168.2.100 --flake adam

# Skip disko (when disk is already partitioned and mounted)
./deploy.sh --host 192.168.2.100 --flake adam --skip-disko
```

**Show Help**:
```bash
./deploy.sh --help
```

### Prerequisites

Before running the deploy script:

1. **Update configuration files**:
   - Set the disk device path in `machines/nixos/*/disko.nix`
   - Change the default password by editing `modules/users/zekurio/default.nix`
     ```bash
     # Generate a new password hash
     openssl passwd -6 "your-password"
     ```

2. **On the target machine** (via TTY or console):
   ```bash
   # Boot from NixOS installer ISO
   # Set a root password
   sudo su
   passwd
   ```

3. **From your local machine**:
   ```bash
   # Copy your SSH key to the target
   ssh-copy-id root@<TARGET_HOST>
   ```

4. **Network connectivity**:
   - Ensure the target host is accessible via SSH
   - The target needs internet access to download Nix packages

## Manual Installation Runbook (Advanced)

Use this method if you need more control over the installation process or if the automated script doesn't fit your use case.

### When to Use Manual Installation

- You need to customize the installation steps
- You want to understand the underlying process
- You need to troubleshoot a failed automated deployment
- You're installing on unusual hardware or network configurations

### Steps

**1. Create a root password on the target** (via TTY or console):

```bash
sudo su
passwd
```

**2. Copy your SSH key from your local machine**:

```bash
export NIXOS_HOST=192.168.2.xxx
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@$NIXOS_HOST
```

**3. SSH into the target host**:

```bash
ssh -A root@$NIXOS_HOST
```

**4. Enable flakes on the target**:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**5. Partition and mount the drives using [disko](https://github.com/nix-community/disko)**:

```bash
# Download the disko configuration for your machine
FLAKE="adam" # the flake name in this repo to use, adjust as needed
curl https://raw.githubusercontent.com/zekurio/nix-config/refs/heads/master/machines/nixos/$FLAKE/disko.nix \
    -o /tmp/disko.nix

# Run disko to partition, format, and mount
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
    -- -m destroy,format,mount /tmp/disko.nix
```

**6. Install git**:

```bash
nix-env -f '<nixpkgs>' -iA git
```

**7. Clone this repository**:

```bash
mkdir -p /mnt/etc/nixos
git clone https://github.com/zekurio/nix-config.git /mnt/etc/nixos
```

**8. Install the system**:

```bash
nixos-install \
    --root "/mnt" \
    --no-root-passwd \
    --flake "git+file:///mnt/etc/nixos#$FLAKE"
```

**9. Unmount the filesystems**:

```bash
umount "/mnt/boot"
umount -R "/mnt"
```

**10. Reboot**:

```bash
reboot
```

After reboot, you can SSH into the system as `zekurio@<HOST>` using the SSH key configured in the user module.