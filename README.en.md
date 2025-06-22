# 3x-ui

> **Disclaimer**: This project is only for personal learning and communication, please do not use it for illegal purposes, its use is not related to the project developer

> **Note**: This repository is a China-optimized version of [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui), optimized for Chinese network environment

3x-ui is a panel supporting multi-protocol and multi-user, supporting protocols like V2ay, Trojan, and Shadowsocks.

**If you think this project is helpful to you, please give it a star ⭐, thanks for your support!**

## Features

- System status monitoring
- Support multi-protocol and multi-user management
- Traffic statistics
- Customizable xray configuration templates
- Support https access to the panel
- Support cross-node management
- gRPC-based node-to-node communication

English | [简体中文](./README.md)

## One-click Installation & Upgrade

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install.sh)
```

## Manual Installation & Upgrade

1. First, download the latest compressed package from [releases](https://gitee.com/YX-love/3x-ui/releases)
2. Then extract it and enter the directory, execute the following command to install or upgrade

```bash
chmod +x install.sh
./install.sh
```

## Usage

### Start/Stop/Restart/Check Status

```bash
# Start the panel and xray core
x-ui start

# Stop the panel and xray core
x-ui stop

# Restart the panel and xray core
x-ui restart

# View running status
x-ui status
```

### Configuration

The panel configuration file is located at `/usr/local/x-ui/config.json`, you can configure the panel through commands or by directly modifying the file

```bash
# Modify panel settings
x-ui setting
```

### Common Commands

```bash
# Generate SSL certificate in the current directory
x-ui cert

# Modify panel settings
x-ui setting

# Reset username and password
x-ui reset

# Show all commands
x-ui help
```

## FAQ

### Migrating from v2-ui

First, install the latest version of x-ui on the server where v2-ui is installed, then use the following command to migrate, which will migrate user data to 3x-ui:

```bash
x-ui v2-ui
```

### Changing Default Web Port

Use the command `x-ui setting` to modify the panel listening port

### Resetting Username and Password

```bash
x-ui reset
```

## Notes

- If you modify the panel port, please also open the corresponding port in the firewall
- When using Nginx and other reverse proxies for the panel, please configure WebSocket support

## Sponsorship

If you find this project helpful, sponsorships are welcome.

## Discussion

TG Group: [Click to Join](https://t.me/ChatGPTools)

## Screenshots

![Dashboard](./media/dashboard.png)
![System Status](./media/system.png)
![Inbounds List](./media/inbounds.png)