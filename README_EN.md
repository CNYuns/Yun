# 3X-UI Management Panel

> **Disclaimer: This project is only for personal learning and communication, please do not use it for commercial purposes, please do not use it for illegal purposes, otherwise you will be responsible for the consequences, please delete it within 24 hours after downloading, thank you for your cooperation!**

A web-based Xray management panel supporting multi-protocol and multi-user proxy management system.

[中文](README.md)

## Features

- **System Status Monitoring** - CPU, memory, system load, network status
- **Multi-protocol Support** - VMess, VLESS, Trojan, Shadowsocks, Dokodemo-door, Socks, HTTP
- **Multiple Transport Configurations**
- **Traffic Statistics** - Online user statistics, multi-user traffic statistics
- **Log Monitoring** - Observe transmission logs
- **Database** - Support SQLite/MySQL/PostgreSQL
- **TLS Certificate Management** - SSL certificate application and renewal
- **Telegram Bot** - Support daily traffic reports, panel login reminders
- **Backup & Restore** - Support panel settings and Xray configuration import/export

## Installation and Upgrade

### One-click Installation Script

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/main/install.sh)
```

### One-click Upgrade Script

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/main/install.sh) update
```

### Manual Installation

1. Download the latest release package: https://gitee.com/YX-love/3x-ui/releases
2. Generally choose `amd64` architecture
3. Extract and install

```bash
cd /root/
wget https://gitee.com/YX-love/3x-ui/releases/download/v2.6.0/x-ui-linux-amd64.tar.gz
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui
```

## Default Settings

- **Port:** 54321
- **Username and Password:** Set after logging into the panel
- **Database:** SQLite3
- **Xray Version:** Latest version
- **Certificate Application:** ACME v2

After installation, please use the `x-ui` command to open the control menu.

## Recommended Systems

- CentOS 8+
- Ubuntu 20+
- Debian 11+
- Fedora 36+
- Arch Linux
- Parch Linux
- Manjaro
- Armbian
- AlmaLinux 9+
- Rocky Linux 9+
- Oracle Linux 8+
- OpenSUSE Tumbleweed

## Architecture Support

- amd64
- arm64
- armv7

## Common Commands

```bash
x-ui              # Show management menu
x-ui start        # Start x-ui panel
x-ui stop         # Stop x-ui panel
x-ui restart      # Restart x-ui panel
x-ui status       # View x-ui status
x-ui enable       # Set x-ui auto-start
x-ui disable      # Disable x-ui auto-start
x-ui log          # View x-ui logs
x-ui update       # Update x-ui panel
x-ui install      # Install x-ui panel
x-ui uninstall    # Uninstall x-ui panel
```

## API Interface

The panel provides a set of RESTful APIs for HTTP interaction with the panel.

API Documentation: [API.md](docs/API.md)

## Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| XUI_LOG_LEVEL | string | info | Log level: `debug`, `info`, `warn`, `error` |
| XUI_DEBUG | boolean | false | Debug mode |
| XUI_BIN_FOLDER | string | bin | xray core folder |
| XUI_DB_FOLDER | string | /etc/x-ui | Database folder |

## Issue Feedback

If you encounter problems during use, please provide feedback through:

- [Issues](https://gitee.com/YX-love/3x-ui/issues)

## Acknowledgments

- [vaxilu/x-ui](https://github.com/vaxilu/x-ui)
- [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- [gin-gonic/gin](https://github.com/gin-gonic/gin)

## License

[GPL v3](https://gitee.com/YX-love/3x-ui/blob/main/LICENSE)

## Donation

If you find this project helpful, you can buy the author a cup of coffee ☕

### Alipay
[Donation QR Code]

### WeChat Pay
[Donation QR Code]

Thank you for your support!
