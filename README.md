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
   - Lists available disks on the remote system

2. **Password Configuration** (Optional)
   - Generates a SHA-512 password hash for the user
   - Updates `modules/users/zekurio/default.nix` with the new hash
   - Replaces `PLACEHOLDER-HASH` in the user configuration
   - Creates a backup of the user file before modification

3. **Disk Partitioning** (Optional, can be skipped)
   - Copies the disko configuration to the target host
   - Replaces `PLACEHOLDER-DISK` with the actual disk device path
   - Runs [disko](https://github.com/nix-community/disko) to partition and format the disk
   - Mounts the filesystems at `/mnt`

4. **NixOS Installation**
   - Ensures git is available on the target system
   - Copies the entire configuration to `/mnt/etc/nixos` via rsync
   - Runs `nixos-install` with the specified flake configuration
   - Excludes `.git`, `*.bak`, and `result` from the copy

5. **Cleanup and Reboot**
   - Optionally unmounts all filesystems
   - Reboots the system into the new installation

### Usage

**Interactive Mode** (prompts for all required values):
```bash
./deploy.sh
```

**Automated Mode** (all parameters provided):
```bash
# Full automated deploy with password
./deploy.sh --host 192.168.2.100 --flake adam --disk /dev/nvme0n1 --password mypassword

# With pre-hashed password
./deploy.sh --host 192.168.2.100 --flake adam --disk /dev/sda --password-hash '$6$...'

# Skip disko (when disk is already partitioned and mounted)
./deploy.sh --host 192.168.2.100 --flake adam --skip-disko

# Skip password update (use PLACEHOLDER-HASH from config)
./deploy.sh --host 192.168.2.100 --flake adam --skip-password

# Combine options
./deploy.sh --host 192.168.2.100 --flake lilith --skip-disko --skip-password
```

**Show Help**:
```bash
./deploy.sh --help
```

### Prerequisites

Before running the deploy script:

1. **On the target machine** (via TTY or console):
   ```bash
   # Boot from NixOS installer ISO
   # Set a root password
   sudo su
   passwd
   ```

2. **From your local machine**:
   ```bash
   # Copy your SSH key to the target
   ssh-copy-id root@<TARGET_HOST>
   
   # Ensure password hashing tools are available
   # (mkpasswd is preferred, openssl is fallback)
   which mkpasswd || which openssl
   ```

3. **Network connectivity**:
   - Ensure the target host is accessible via SSH
   - The target needs internet access to download Nix packages

### Configuration Placeholders

The deploy script uses two placeholders that get replaced during deployment:

- **`PLACEHOLDER-DISK`** - In `machines/nixos/*/disko.nix`
  - Replaced with the actual disk device path (e.g., `/dev/nvme0n1`)
  - Used for declarative disk partitioning

- **`PLACEHOLDER-HASH`** - In `modules/users/zekurio/default.nix`
  - Replaced with the generated password hash
  - Allows setting custom passwords per deployment

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
DISK="/dev/nvme0n1" # adjust as needed
FLAKE="adam" # the flake name in this repo to use, adjust as needed

# Download the disko configuration
curl https://raw.githubusercontent.com/zekurio/nix-config/refs/heads/master/machines/nixos/$FLAKE/disko.nix \
    -o /tmp/disko.nix

# Replace the placeholder with the actual disk
sed -i "s|PLACEHOLDER-DISK|$DISK|" /tmp/disko.nix

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

**8. (Optional) Update the user password**:

```bash
# Generate a password hash
mkpasswd -m sha-512

# Edit the user configuration and replace PLACEHOLDER-HASH with your hash
nano /mnt/etc/nixos/modules/users/zekurio/default.nix
```

**9. Install the system**:

```bash
nixos-install \
    --root "/mnt" \
    --no-root-passwd \
    --flake "git+file:///mnt/etc/nixos#$FLAKE"
```

**10. Unmount the filesystems**:

```bash
umount "/mnt/boot"
umount -R "/mnt"
```

**11. Reboot**:

```bash
reboot
```

After reboot, you can SSH into the system as `zekurio@<HOST>` using the SSH key configured in the user module.