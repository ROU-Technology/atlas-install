# Atlas Installation Scripts

Public installation scripts for Atlas CLI and Agent.

## Quick Install

### Install Everything (CLI + Agent)

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash
```

### CLI Only

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/cli-install.sh | bash
```

### Agent Only

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/agent-install.sh | bash
```

## Install Specific Version

```bash
ATLAS_VERSION=v1.0.0 curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash
```

## Uninstall

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash -s uninstall
```

## Requirements

- Linux/macOS
- `curl`
- Systemd (optional, for Agent service management)
- `sudo` access (for system-wide installation)

## Environment Variables

| Variable        | Default                        | Description               |
| --------------- | ------------------------------ | ------------------------- |
| `ATLAS_VERSION` | `latest`                       | Version to install        |
| `ATLAS_REPO`    | `ROU-Technology/atlas-install` | Public repo with releases |
| `INSTALL_DIR`   | `/usr/local/bin`               | Installation directory    |
| `CONFIG_DIR`    | `/etc/atlas-agent`             | Agent config directory    |

## Architecture Support

- x86_64 (x64)
- aarch64 (arm64)

## Troubleshooting

### Permission Denied

If you get permission errors, run with sudo:

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | sudo bash
```

### Binary Not Found

Make sure releases exist in the public repo:

- Check https://github.com/ROU-Technology/atlas-install/releases

## License

See LICENSE file.
