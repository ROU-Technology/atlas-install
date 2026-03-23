#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Atlas Installer Bootstrap
# =============================================================================
# This script downloads the atlas-installer binary and delegates to it.
# Usage:
#   curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash
#   curl -sL ... | bash -s -- install agent
#   curl -sL ... | bash -s -- install cli
#   curl -sL ... | bash -s -- install both
#   curl -sL ... | bash -s -- uninstall agent
# =============================================================================

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_REPO="${ATLAS_REPO:-ROU-Technology/atlas-install}"
INSTALLER_DIR="/tmp/atlas-installer-$$"

cleanup() {
  rm -rf "$INSTALLER_DIR"
}
trap cleanup EXIT

get_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$arch" in
    x86_64)
      if [ "$os" = "darwin" ]; then
        echo "Darwin x64 not available - use arm64 machine or Linux" >&2
        return 1
      fi
      arch="x64"
      ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch" >&2; return 1 ;;
  esac

  echo "${os}-${arch}"
}

main() {
  PLATFORM=$(get_platform) || exit 1

  if [ "$ATLAS_VERSION" = "latest" ]; then
    INSTALLER_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/atlas-installer-${PLATFORM}.gz"
  else
    INSTALLER_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/atlas-installer-${PLATFORM}.gz"
  fi

  echo "Downloading Atlas Installer for ${PLATFORM}..."
  mkdir -p "$INSTALLER_DIR"
  curl -fSL "$INSTALLER_URL" -o "$INSTALLER_DIR/atlas-installer.gz"
  gunzip -f "$INSTALLER_DIR/atlas-installer.gz"
  chmod +x "$INSTALLER_DIR/atlas-installer"

  echo "Running Atlas Installer..."
  "$INSTALLER_DIR/atlas-installer" "$@"
}

main "$@"
