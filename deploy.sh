#!/usr/bin/env bash
# Quick deployment script for nixos-anywhere

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <system-name> <target-ip>"
    echo ""
    echo "Example:"
    echo "  $0 adam 192.168.1.100"
    echo ""
    echo "Note: Edit machines/nixos/<system>/disko.nix to change the target disk"
    exit 1
fi

SYSTEM=$1
TARGET=$2

echo "🚀 Deploying $SYSTEM to $TARGET..."
echo ""

nix run github:nix-community/nixos-anywhere -- \
    --flake ".#$SYSTEM" \
    "root@$TARGET"

echo ""
echo "✅ Deployment complete! The system will reboot."
