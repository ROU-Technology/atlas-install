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
ATLAS_VERSION=v2026.03.15.123456 curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash
```

## Uninstall

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash -s uninstall
```

## Requirements

- Linux/macOS
- `curl`
- `gzip`
- `sha256sum` (for checksum verification)
- Systemd (optional, for Agent service management)
- `sudo` access (for system-wide installation)

## Environment Variables

| Variable          | Default                        | Description                                   |
| ----------------- | ------------------------------ | --------------------------------------------- |
| `ATLAS_VERSION`   | `latest`                       | Version to install (e.g., v2026.03.15.123456) |
| `ATLAS_REPO`      | `ROU-Technology/atlas-install` | Public repo with releases                     |
| `INSTALL_DIR`     | `/usr/local/bin`               | Installation directory                        |
| `CONFIG_DIR`      | `/etc/atlas-agent`             | Agent config directory                        |
| `VERIFY_CHECKSUM` | `true`                         | Verify checksums before installing            |

## Architecture Support

- x86_64 (x64)
- aarch64 (arm64)

## Security

All binaries are GPG-signed and include SHA256 checksums. The installer verifies checksums automatically.

To skip verification (not recommended):

```bash
VERIFY_CHECKSUM=false curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | bash
```

## Verify Checksum Manually

```bash
# Download checksums
curl -fSL https://github.com/ROU-Technology/atlas-install/releases/latest/download/checksums.txt -o checksums.txt

# Verify
sha256sum -c checksums.txt
```

## Troubleshooting

### Permission Denied

If you get permission errors, run with sudo:

```bash
curl -sL https://raw.githubusercontent.com/ROU-Technology/atlas-install/main/install.sh | sudo bash
```

### Binary Not Found

Make sure releases exist in the public repo:

- Check https://github.com/ROU-Technology/atlas-install/releases

### Checksum Verification Failed

This usually means the download was corrupted or tampered with. Try:

1. Clear cache: `rm -rf /tmp/atlas-*`
2. Retry installation

## License

See LICENSE file.
