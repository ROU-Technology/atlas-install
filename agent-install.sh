#!/usr/bin/env bash
set -euo pipefail

# Shortcut: install agent only
curl -sL "https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh" | bash -s -- install agent
