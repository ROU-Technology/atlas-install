#!/usr/bin/env bash
set -euo pipefail

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_PRIVATE_REPO="${ATLAS_PRIVATE_REPO:-ROU-Technology/atlas-ts}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

install_cli() {
  echo "Installing Atlas CLI ${ATLAS_VERSION}..."

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  if [ "$ATLAS_VERSION" = "latest" ]; then
    BINARY_URL="https://github.com/${ATLAS_PRIVATE_REPO}/releases/latest/download/atlas-${ARCH}"
  else
    BINARY_URL="https://github.com/${ATLAS_PRIVATE_REPO}/releases/download/${ATLAS_VERSION}/atlas-${ARCH}"
  fi

  echo "Downloading Atlas CLI from ${BINARY_URL}..."
  curl -fSL "$BINARY_URL" -o "$INSTALL_DIR/atlas"
  chmod +x "$INSTALL_DIR/atlas"

  echo ""
  echo "Atlas CLI installed successfully!"
  echo "Run 'atlas --help' to get started."
}

uninstall_cli() {
  echo "Uninstalling Atlas CLI..."
  rm -f "$INSTALL_DIR/atlas"
  echo "Atlas CLI uninstalled."
}

show_help() {
  cat << 'HELPEOF'
Atlas CLI Installation Script

Usage:
  ./install.sh [command]

Commands:
  install         Install Atlas CLI (default)
  uninstall       Uninstall Atlas CLI
  help            Show this help message

Environment Variables:
  ATLAS_VERSION       Version to install (default: latest)
  ATLAS_PRIVATE_REPO  Private repo (default: ROU-Technology/atlas-ts)
  INSTALL_DIR         Installation directory (default: /usr/local/bin)

Examples:
  ./install.sh                              # Install latest
  ATLAS_VERSION=v1.0.0 ./install.sh        # Install specific version
  ATLAS_PRIVATE_REPO=my-org/atlas ./install.sh  # Different repo
  ./install.sh uninstall                   # Uninstall CLI

Note: This script downloads binaries from your private repository's releases.
      The repository must have public releases enabled.
HELPEOF
}

case "${1:-install}" in
  install) install_cli ;;
  uninstall) uninstall_cli ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1" && show_help && exit 1 ;;
esac
