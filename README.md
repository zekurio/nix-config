# nix-config

my personal nix configs, heavily WIP

## Quick Deploy (Recommended)

Use the automated deploy script for easy deployment:

```bash
./deploy.sh
```

The script will interactively prompt for:
- Target host IP or hostname
- Flake configuration (adam, lilith, etc.)
- Disk device for partitioning
- Optional password for the user

### Deploy Script Options

```bash
# Full automated deploy
./deploy.sh --host 192.168.2.100 --flake adam --disk /dev/nvme0n1 --password mypassword

# With pre-hashed password
./deploy.sh --host 192.168.2.100 --flake adam --disk /dev/sda --password-hash '$6$...'

# Skip disko (when disk is already partitioned)
./deploy.sh --host 192.168.2.100 --flake adam --skip-disko

# Skip password update (use existing hash in config)
./deploy.sh --host 192.168.2.100 --flake adam --skip-password

# Show help
./deploy.sh --help
```

### Prerequisites

Before running the deploy script:

1. Set a root password on the target machine (via TTY)
2. Copy your SSH key to the target:
   ```bash
   ssh-copy-id root@<TARGET_HOST>
   ```
3. Ensure `mkpasswd` or `openssl` is installed locally (for password hashing)

## Manual Installation runbook (NixOS)

Create a root password using the TTY

```bash
sudo su
passwd
```

From your host, copy the public SSH key to the server

```bash
export NIXOS_HOST=192.168.2.xxx
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@$NIXOS_HOST
```

SSH into the host with agent forwarding enabled (for the secrets repo access)

```bash
ssh -A root@$NIXOS_HOST
```

Enable flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Partition and mount the drives using [disko](https://github.com/nix-community/disko)

```bash
DISK="/dev/nvme0n1" # adjust as needed
FLAKE="adam" # the flake name in this repo to use, adjust as needed

curl https://raw.githubusercontent.com/zekurio/nix-config/refs/heads/master/machines/nixos/$FLAKE/disko.nix \
    -o /tmp/disko.nix
sed -i "s|to-be-filled-during-installation|$DISK|" /tmp/disko.nix
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
    -- -m destroy,format,mount /tmp/disko.nix
```

Install git

```bash
nix-env -f '<nixpkgs>' -iA git
```

Clone this repository

```bash
mkdir -p /mnt/etc/nixos
git clone https://github.com/zekurio/nix-config.git /mnt/etc/nixos
```

Install the system

```bash
nixos-install \
--root "/mnt" \
--no-root-passwd \
--flake "git+file:///mnt/etc/nixos#adam"
```

Unmount the filesystems

```bash
umount "/mnt/boot"
umount -R "/mnt"
```

Reboot

```bash
reboot
```