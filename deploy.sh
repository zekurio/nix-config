#!/usr/bin/env bash

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
    --skip-disko            Skip disko partitioning step

EXAMPLES:
    # Interactive mode (will prompt for missing values)
    $0

    # With all parameters
    $0 --host 192.168.2.100 --flake adam

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

# Function to run disko
run_disko() {
    local host=$1
    local flake=$2
    
    print_info "Running disko partitioning..."
    # Copy disko configuration to remote host
    scp "$SCRIPT_DIR/machines/nixos/$flake/disko.nix" "root@$host:/tmp/disko.nix"
    
    # Run disko (disko will ask for confirmation)
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
    
    print_info "Cloning configuration repository to remote host..."
    # Get the git remote URL
    GIT_REMOTE=$(git -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || echo "")
    
    if [ -n "$GIT_REMOTE" ]; then
        print_info "Cloning from: $GIT_REMOTE"
        ssh "root@$host" "cd /mnt/etc && git clone $GIT_REMOTE nixos"
        
        # Checkout current branch
        CURRENT_BRANCH=$(git -C "$SCRIPT_DIR" branch --show-current)
        if [ -n "$CURRENT_BRANCH" ]; then
            print_info "Checking out branch: $CURRENT_BRANCH"
            ssh "root@$host" "cd /mnt/etc/nixos && git checkout $CURRENT_BRANCH"
        fi
    else
        print_warning "No git remote found, falling back to rsync"
        rsync -av --delete \
            --exclude '.git' \
            --exclude '*.bak' \
            --exclude 'result' \
            "$SCRIPT_DIR/" "root@$host:/mnt/etc/nixos/"
    fi
    
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
    SKIP_DISKO=false
    
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
            --skip-disko)
                SKIP_DISKO=true
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
    
    # Handle disko partitioning
    if [ "$SKIP_DISKO" = false ]; then
        run_disko "$HOST" "$FLAKE"
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
