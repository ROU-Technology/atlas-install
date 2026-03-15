#!/usr/bin/env bash
set -euo pipefail

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_REPO="${ATLAS_REPO:-ROU-Technology/atlas-install}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/atlas-agent}"

install_agent() {
  echo "Installing Atlas Agent ${ATLAS_VERSION}..."

  mkdir -p "$CONFIG_DIR"

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  if [ "$ATLAS_VERSION" = "latest" ]; then
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/latest/download/atlas-agent-${ARCH}"
  else
    BINARY_URL="https://github.com/${ATLAS_REPO}/releases/download/${ATLAS_VERSION}/atlas-agent-${ARCH}"
  fi
  
  echo "Downloading Atlas Agent from ${BINARY_URL}..."
  curl -fSL "$BINARY_URL" -o "$INSTALL_DIR/atlas-agent"
  chmod +x "$INSTALL_DIR/atlas-agent"

  cat > "$CONFIG_DIR/atlas-agent.env" << 'ENVEOF'
ATLAS_AGENT_PORT=3001
ATLAS_AGENT_AUTH_ENABLED=false
ATLAS_AGENT_TOKEN=change-me
ATLAS_CONFIG_PATH=/etc/atlas/atlas.yaml
ENVEOF

  if command -v systemctl &> /dev/null; then
    echo "Creating systemd service..."
    cat > /etc/systemd/system/atlas-agent.service << 'SYSDEOF'
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
    systemctl daemon-reload
  fi

  echo "Atlas Agent installed successfully!"
}

uninstall_agent() {
  echo "Uninstalling Atlas Agent..."
  
  if command -v systemctl &> /dev/null; then
    systemctl stop atlas-agent 2>/dev/null || true
    systemctl disable atlas-agent 2>/dev/null || true
    rm -f /etc/systemd/system/atlas-agent.service
    systemctl daemon-reload
  fi
  
  rm -rf "$CONFIG_DIR"
  rm -f "$INSTALL_DIR/atlas-agent"
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
  ATLAS_VERSION   Version to install (default: latest)
  ATLAS_REPO      Public repo with releases (default: ROU-Technology/atlas-install)
  INSTALL_DIR     Installation directory (default: /usr/local/bin)
  CONFIG_DIR      Config directory (default: /etc/atlas-agent)

Examples:
  ./install.sh                              # Install latest
  ATLAS_VERSION=v1.0.0 ./install.sh        # Specific version
  ./install.sh uninstall                    # Uninstall agent
HELPEOF
}

case "${1:-install}" in
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1" && show_help && exit 1 ;;
esac
