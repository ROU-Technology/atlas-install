#!/usr/bin/env bash
set -euo pipefail

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_REPO="${ATLAS_REPO:-ROU-Technology/atlas-install}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERIFY_CHECKSUM="${VERIFY_CHECKSUM:-true}"

if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

get_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  
  case "$arch" in
    x86_64) arch="x64" ;;
    aarch64|arm64) 
      if [ "$os" = "linux" ]; then
        echo "Linux arm64 builds not yet available. Please use x64 or Darwin arm64." >&2
        exit 1
      fi
      arch="arm64" 
      ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
  esac
  
  echo "${os}-${arch}"
}

install_cli() {
  echo "Installing Atlas CLI ${ATLAS_VERSION}..."

  PLATFORM=$(get_platform)

  if [ "$ATLAS_VERSION" = "latest" ]; then
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/atlas-${PLATFORM}.gz"
    CHECKSUM_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/checksums.txt"
  else
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/atlas-${PLATFORM}.gz"
    CHECKSUM_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/checksums.txt"
  fi

  echo "Downloading Atlas CLI for ${PLATFORM} from ${BINARY_URL}..."
  curl -fSL "$BINARY_URL" -o "/tmp/atlas-${PLATFORM}.gz"
  
  if [ "$VERIFY_CHECKSUM" = "true" ]; then
    echo "Verifying checksum..."
    curl -fSL "$CHECKSUM_URL" -o "/tmp/checksums.txt"
    cd /tmp
    sha256sum -c checksums.txt --strict || { echo "Checksum verification failed!"; exit 1; }
    cd -
  fi
  
  gunzip -f "/tmp/atlas-${PLATFORM}.gz" -c > "/tmp/atlas"
  $SUDO mv "/tmp/atlas" "$INSTALL_DIR/atlas"
  $SUDO chmod +x "$INSTALL_DIR/atlas"
  rm -f "/tmp/atlas-${PLATFORM}.gz"

  echo "Atlas CLI installed successfully!"
}

uninstall_cli() {
  echo "Uninstalling Atlas CLI..."
  $SUDO rm -f "$INSTALL_DIR/atlas"
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
  ATLAS_VERSION     Version to install (default: latest)
  ATLAS_REPO        Public repo with releases (default: ROU-Technology/atlas-install)
  INSTALL_DIR       Installation directory (default: /usr/local/bin)
  VERIFY_CHECKSUM   Verify checksums (default: true)

Examples:
  ./install.sh                              # Install latest
  ATLAS_VERSION=v2026.03.15.123456 ./install.sh  # Specific version
  VERIFY_CHECKSUM=false ./install.sh       # Skip checksum verification
  ./install.sh uninstall                    # Uninstall CLI
HELPEOF
}

case "${1:-install}" in
  install) install_cli ;;
  uninstall) uninstall_cli ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1" && show_help && exit 1 ;;
esac
