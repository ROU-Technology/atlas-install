#!/usr/bin/env bash
set -euo pipefail

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_REPO="${ATLAS_REPO:-ROU-Technology/atlas-install}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/atlas-agent}"
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
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
  esac
  
  echo "${os}-${arch}"
}

install_agent() {
  echo "Installing Atlas Agent ${ATLAS_VERSION}..."

  $SUDO mkdir -p "$CONFIG_DIR"

  PLATFORM=$(get_platform)
  
  if [ "$ATLAS_VERSION" = "latest" ]; then
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/atlas-agent-${PLATFORM}.gz"
    CHECKSUM_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/checksums.txt"
  else
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/atlas-agent-${PLATFORM}.gz"
    CHECKSUM_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/checksums.txt"
  fi
  
  echo "Downloading Atlas Agent for ${PLATFORM} from ${BINARY_URL}..."
  curl -fSL "$BINARY_URL" -o "/tmp/atlas-agent-${PLATFORM}.gz"
  
  if [ "$VERIFY_CHECKSUM" = "true" ]; then
    echo "Verifying checksum..."
    curl -fSL "$CHECKSUM_URL" -o "/tmp/checksums.txt"
    cd /tmp
    sha256sum -c checksums.txt --strict || { echo "Checksum verification failed!"; exit 1; }
    cd -
  fi
  
  gunzip -f "/tmp/atlas-agent-${PLATFORM}.gz" -c > "/tmp/atlas-agent"
  $SUDO mv "/tmp/atlas-agent" "$INSTALL_DIR/atlas-agent"
  $SUDO chmod +x "$INSTALL_DIR/atlas-agent"
  rm -f "/tmp/atlas-agent-${PLATFORM}.gz"

  $SUDO tee "$CONFIG_DIR/atlas-agent.env" > /dev/null << 'ENVEOF'
ATLAS_AGENT_PORT=3001
ATLAS_AGENT_AUTH_ENABLED=false
ATLAS_AGENT_TOKEN=change-me
ATLAS_CONFIG_PATH=/etc/atlas/atlas.yaml
ENVEOF

  if command -v systemctl &> /dev/null; then
    echo "Creating systemd service..."
    $SUDO tee /etc/systemd/system/atlas-agent.service > /dev/null << 'SYSDEOF'
[Unit]
Description=Atlas Agent
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/atlas-agent
Restart=always
RestartSec=5
EnvironmentFile=/etc/atlas-agent/atlas-agent.env

[Install]
WantedBy=multi-user.target
SYSDEOF

    echo "Reloading systemd..."
    $SUDO systemctl daemon-reload
  fi

  echo "Atlas Agent installed successfully!"
}

uninstall_agent() {
  echo "Uninstalling Atlas Agent..."
  
  if command -v systemctl &> /dev/null; then
    $SUDO systemctl stop atlas-agent 2>/dev/null || true
    $SUDO systemctl disable atlas-agent 2>/dev/null || true
    $SUDO rm -f /etc/systemd/system/atlas-agent.service
    $SUDO systemctl daemon-reload
  fi
  
  $SUDO rm -rf "$CONFIG_DIR"
  $SUDO rm -f "$INSTALL_DIR/atlas-agent"
  echo "Atlas Agent uninstalled."
}

show_help() {
  cat << 'HELPEOF'
Atlas Agent Installation Script

Usage:
  ./install.sh [command]

Commands:
  install         Install Atlas Agent (default)
  uninstall       Uninstall Atlas Agent
  help            Show this help message

Environment Variables:
  ATLAS_VERSION     Version to install (default: latest)
  ATLAS_REPO        Public repo with releases (default: ROU-Technology/atlas-install)
  INSTALL_DIR       Installation directory (default: /usr/local/bin)
  CONFIG_DIR        Config directory (default: /etc/atlas-agent)
  VERIFY_CHECKSUM   Verify checksums (default: true)

Examples:
  ./install.sh                              # Install latest
  ATLAS_VERSION=v2026.03.15.123456 ./install.sh  # Specific version
  VERIFY_CHECKSUM=false ./install.sh       # Skip checksum verification
  ./install.sh uninstall                    # Uninstall agent
HELPEOF
}

case "${1:-install}" in
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1" && show_help && exit 1 ;;
esac
