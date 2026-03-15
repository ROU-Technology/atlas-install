#!/usr/bin/env bash
set -euo pipefail

ATLAS_VERSION="${ATLAS_VERSION:-latest}"
ATLAS_REPO="${ATLAS_REPO:-ROU-Technology/atlas-install}"
ATLAS_SAAS_URL="${ATLAS_SAAS_URL:-}"
ATLAS_API_KEY="${ATLAS_API_KEY:-}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/atlas-agent}"
VERIFY_CHECKSUM="${VERIFY_CHECKSUM:-true}"

if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

verify_api_key() {
  if [ -z "$ATLAS_SAAS_URL" ] || [ -z "$ATLAS_API_KEY" ]; then
    return 0
  fi

  echo "Verifying API key with Atlas SaaS..."
  local response
  response=$(curl -fSL -X GET "${ATLAS_SAAS_URL}/api/v1/auth/verify" \
    -H "Authorization: Bearer ${ATLAS_API_KEY}" \
    -H "Content-Type: application/json" \
    2>/dev/null) || {
    echo "Failed to verify API key with Atlas SaaS" >&2
    return 1
  }

  if [ -n "$response" ]; then
    echo "API key verified successfully"
  fi
  return 0
}

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

install_agent() {
  echo "Installing Atlas Agent ${ATLAS_VERSION}..."

  verify_api_key || exit 1

  $SUDO mkdir -p "$CONFIG_DIR"
  $SUDO mkdir -p "$INSTALL_DIR"

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
    grep "${PLATFORM}.gz" checksums.txt > filtered_checksums.txt || true
    sha256sum -c filtered_checksums.txt --strict || { echo "Checksum verification failed!"; cd -; exit 1; }
    cd /tmp
    cd -
  fi
  
  gunzip -fdk "/tmp/atlas-agent-${PLATFORM}.gz"
  $SUDO mv "/tmp/atlas-agent-${PLATFORM}" "$INSTALL_DIR/atlas-agent"
  $SUDO chmod +x "$INSTALL_DIR/atlas-agent"
  rm -f "/tmp/atlas-agent-${PLATFORM}.gz"

  local env_content="ATLAS_AGENT_PORT=3001
ATLAS_AGENT_AUTH_ENABLED=false
ATLAS_AGENT_TOKEN=change-me
ATLAS_CONFIG_PATH=/etc/atlas/atlas.yaml
"

  if [ -n "$ATLAS_SAAS_URL" ]; then
    env_content+="ATLAS_SAAS_URL=${ATLAS_SAAS_URL}
"
  fi

  if [ -n "$ATLAS_API_KEY" ]; then
    env_content+="ATLAS_SAAS_TOKEN=${ATLAS_API_KEY}
"
  fi

  $SUDO tee "$CONFIG_DIR/atlas-agent.env" > /dev/null << EOF
$env_content
EOF

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

install_cli() {
  echo "Installing Atlas CLI ${ATLAS_VERSION}..."

  verify_api_key || exit 1

  $SUDO mkdir -p "$INSTALL_DIR"

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
    grep "${PLATFORM}.gz" checksums.txt > filtered_checksums.txt || true
    sha256sum -c filtered_checksums.txt --strict || { echo "Checksum verification failed!"; cd -; exit 1; }
    cd /tmp
    cd -
  fi
  
  gunzip -fdk "/tmp/atlas-${PLATFORM}.gz"
  $SUDO mv "/tmp/atlas-${PLATFORM}" "$INSTALL_DIR/atlas"
  $SUDO chmod +x "$INSTALL_DIR/atlas"

  echo "Atlas CLI installed successfully!"
}

uninstall_all() {
  uninstall_agent
  uninstall_cli
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

uninstall_cli() {
  echo "Uninstalling Atlas CLI..."
  $SUDO rm -f "$INSTALL_DIR/atlas"
  echo "Atlas CLI uninstalled."
}

show_help() {
  cat << 'HELPEOF'
Atlas Installation Script

Usage:
  ./install.sh [command]

Commands:
  install         Install CLI and Agent (default)
  install-cli     Install CLI only
  install-agent   Install Agent only
  uninstall       Uninstall everything
  help            Show this help message

Environment Variables:
  ATLAS_VERSION     Version to install (default: latest)
  ATLAS_REPO        Public repo with releases (default: ROU-Technology/atlas-install)
  ATLAS_SAAS_URL    Atlas SaaS API URL (optional)
  ATLAS_API_KEY     Atlas SaaS API key (optional, for SaaS mode)
  INSTALL_DIR       Installation directory (default: /usr/local/bin)
  CONFIG_DIR        Agent config directory (default: /etc/atlas-agent)
  VERIFY_CHECKSUM   Verify checksums (default: true)

Examples:
  ./install.sh                              # Install everything
  ./install.sh install-cli                  # CLI only
  ./install.sh install-agent                # Agent only
  ATLAS_VERSION=v2026.03.15.123456 ./install.sh  # Specific version
  VERIFY_CHECKSUM=false ./install.sh       # Skip checksum verification
  ATLAS_SAAS_URL=https://api.atlas.io ATLAS_API_KEY=xxx ./install.sh  # Install with SaaS
  ./install.sh uninstall                    # Remove everything
HELPEOF
}

case "${1:-install}" in
  install) install_cli && install_agent ;;
  install-cli) install_cli ;;
  install-agent) install_agent ;;
  uninstall) uninstall_all ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1" && show_help && exit 1 ;;
esac
