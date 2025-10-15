#!/usr/bin/env bash

# THIS WAS BUILT BY CLAUDE, NEEDS TO BE TESTED AND VERIFIED

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy NixOS configuration to a remote host

OPTIONS:
    -h, --help              Show this help message
    -H, --host HOST         Target host IP or hostname (required)
    -f, --flake FLAKE       Flake name (e.g., adam, lilith) (required)
    -d, --disk DISK         Disk device path (e.g., /dev/nvme0n1, /dev/sda)
    -p, --password PASS     Plain text password for user (will be hashed)
    --password-hash HASH    Pre-hashed password for user
    --skip-disko            Skip disko partitioning step
    --skip-password         Skip password configuration

EXAMPLES:
    # Interactive mode (will prompt for missing values)
    $0

    # With all parameters
    $0 --host 192.168.2.100 --flake adam --disk /dev/nvme0n1 --password mypassword

    # With pre-hashed password
    $0 --host 192.168.2.100 --flake adam --disk /dev/sda --password-hash '\$6\$...'

    # Skip disko (when disk is already partitioned)
    $0 --host 192.168.2.100 --flake adam --skip-disko

EOF
    exit 0
}

# Function to validate host connectivity
check_host() {
    local host=$1
    print_info "Checking connectivity to $host..."
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "root@$host" "echo 'Connected'" &>/dev/null; then
        print_error "Cannot connect to root@$host"
        print_info "Make sure you have copied your SSH key: ssh-copy-id root@$host"
        exit 1
    fi
    print_success "Successfully connected to $host"
}

# Function to list available disks on remote host
list_disks() {
    local host=$1
    print_info "Available disks on $host:"
    ssh "root@$host" "lsblk -dno NAME,SIZE,TYPE | grep disk"
}

# Function to generate password hash
generate_password_hash() {
    local password=$1
    print_info "Generating password hash..."
    # Using mkpasswd with SHA-512
    if command -v mkpasswd &> /dev/null; then
        mkpasswd -m sha-512 "$password"
    else
        print_warning "mkpasswd not found, using openssl"
        openssl passwd -6 "$password"
    fi
}

# Function to update user password in default.nix
update_user_password() {
    local password_hash=$1
    local user_file="$SCRIPT_DIR/modules/users/zekurio/default.nix"
    
    print_info "Updating user password hash in $user_file..."
    
    # Escape special characters in the hash for sed
    local escaped_hash=$(echo "$password_hash" | sed 's/[\/&]/\\&/g' | sed 's/\$/\\$/g')
    
    # Create a backup
    cp "$user_file" "$user_file.bak"
    
    # Update the hashedPassword line (using PLACEHOLDER-HASH as the target)
    sed -i "s/PLACEHOLDER-HASH/$escaped_hash/g" "$user_file"
    
    print_success "Password hash updated"
}

# Function to prepare disko configuration
prepare_disko() {
    local host=$1
    local flake=$2
    local disk=$3
    local disko_file="$SCRIPT_DIR/machines/nixos/$flake/disko.nix"
    
    if [ ! -f "$disko_file" ]; then
        print_error "Disko configuration not found: $disko_file"
        exit 1
    fi
    
    print_info "Preparing disko configuration for $disk..."
    
    # Copy disko file to remote host
    scp "$disko_file" "root@$host:/tmp/disko.nix"
    
    # Update the disk device path on remote host
    ssh "root@$host" "sed -i 's|PLACEHOLDER-DISK|$disk|g' /tmp/disko.nix"
    
    print_success "Disko configuration prepared"
}

# Function to run disko
run_disko() {
    local host=$1
    
    print_warning "This will DESTROY all data on the selected disk!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Aborted by user"
        exit 0
    fi
    
    print_info "Running disko partitioning..."
    ssh "root@$host" "nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- -m destroy,format,mount /tmp/disko.nix"
    
    print_success "Disko partitioning completed"
}

# Function to deploy nixos
deploy_nixos() {
    local host=$1
    local flake=$2
    
    print_info "Ensuring git is available on remote host..."
    ssh "root@$host" "command -v git || nix-env -f '<nixpkgs>' -iA git"
    
    print_info "Creating nixos configuration directory..."
    ssh "root@$host" "mkdir -p /mnt/etc/nixos"
    
    print_info "Copying configuration to remote host..."
    rsync -av --delete \
        --exclude '.git' \
        --exclude '*.bak' \
        --exclude 'result' \
        "$SCRIPT_DIR/" "root@$host:/mnt/etc/nixos/"
    
    print_info "Installing NixOS..."
    ssh "root@$host" "nixos-install --root /mnt --no-root-passwd --flake /mnt/etc/nixos#$flake"
    
    print_success "NixOS installation completed"
}

# Function to cleanup and reboot
cleanup_and_reboot() {
    local host=$1
    
    read -p "Unmount filesystems and reboot? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Skipping reboot. Manual cleanup required."
        return
    fi
    
    print_info "Unmounting filesystems..."
    ssh "root@$host" "umount /mnt/boot || true; umount -R /mnt || true"
    
    print_info "Rebooting system..."
    ssh "root@$host" "reboot" || true
    
    print_success "System is rebooting. Deployment complete!"
}

# Main script
main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Parse arguments
    HOST=""
    FLAKE=""
    DISK=""
    PASSWORD=""
    PASSWORD_HASH=""
    SKIP_DISKO=false
    SKIP_PASSWORD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -H|--host)
                HOST="$2"
                shift 2
                ;;
            -f|--flake)
                FLAKE="$2"
                shift 2
                ;;
            -d|--disk)
                DISK="$2"
                shift 2
                ;;
            -p|--password)
                PASSWORD="$2"
                shift 2
                ;;
            --password-hash)
                PASSWORD_HASH="$2"
                shift 2
                ;;
            --skip-disko)
                SKIP_DISKO=true
                shift
                ;;
            --skip-password)
                SKIP_PASSWORD=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Interactive mode if parameters are missing
    if [ -z "$HOST" ]; then
        read -p "Enter target host IP or hostname: " HOST
    fi
    
    if [ -z "$FLAKE" ]; then
        print_info "Available flakes:"
        ls -1 "$SCRIPT_DIR/machines/nixos" | grep -v default.nix
        read -p "Enter flake name: " FLAKE
    fi
    
    # Validate flake exists
    if [ ! -d "$SCRIPT_DIR/machines/nixos/$FLAKE" ]; then
        print_error "Flake configuration not found: $FLAKE"
        exit 1
    fi
    
    # Check host connectivity
    check_host "$HOST"
    
    # Handle password configuration
    if [ "$SKIP_PASSWORD" = false ]; then
        if [ -z "$PASSWORD_HASH" ] && [ -z "$PASSWORD" ]; then
            read -p "Do you want to set a custom password for the user? (yes/no): " set_password
            if [ "$set_password" = "yes" ]; then
                read -sp "Enter password: " PASSWORD
                echo
                read -sp "Confirm password: " PASSWORD_CONFIRM
                echo
                if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                    print_error "Passwords do not match"
                    exit 1
                fi
            fi
        fi
        
        if [ -n "$PASSWORD" ]; then
            PASSWORD_HASH=$(generate_password_hash "$PASSWORD")
        fi
        
        if [ -n "$PASSWORD_HASH" ]; then
            update_user_password "$PASSWORD_HASH"
        else
            print_info "Using existing password hash from configuration"
        fi
    fi
    
    # Handle disko partitioning
    if [ "$SKIP_DISKO" = false ]; then
        if [ -z "$DISK" ]; then
            list_disks "$HOST"
            read -p "Enter disk device (e.g., /dev/nvme0n1): " DISK
        fi
        
        prepare_disko "$HOST" "$FLAKE" "$DISK"
        run_disko "$HOST"
    else
        print_info "Skipping disko partitioning"
    fi
    
    # Deploy NixOS
    deploy_nixos "$HOST" "$FLAKE"
    
    # Cleanup and reboot
    cleanup_and_reboot "$HOST"
    
    print_success "Deployment script completed!"
    print_info "You can now SSH into the system as zekurio@$HOST after reboot"
}

# Run main function
main "$@"
