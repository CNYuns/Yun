# Yun Panel - Xray Management Panel

> **Disclaimer**: This project is for learning and communication purposes only. It is prohibited for illegal use. Users are not related to the project developers.

**Current Version**: v3.1.5
**Update Date**: 2025-11-08
**Project**: [GitHub](https://github.com/CNYuns/yun) | [Gitee](https://gitee.com/cnyuns/yun)

Yun Panel is a multi-protocol, multi-user Xray management panel that provides an easy-to-use Web interface and supports mainstream proxy protocols such as VMess, VLESS, Trojan, Shadowsocks, Socks5, etc.

---

## ✨ Features

### 🎨 Modern UI
- **Modern Design** - Rebuilt with Bootstrap 5 + jQuery, purple gradient theme
- **Responsive Layout** - Perfect for desktop, tablet, mobile
- **Smooth Animations** - Elegant interaction experience
- **Dark Mode** - Coming soon

### 🔒 Security Enhancements
- **Input Validation** - Prevent SQL injection, XSS, path traversal attacks
- **Login Rate Limiting** - Prevent brute force (5 failures in 15 minutes, block for 15 minutes)
- **Security Headers** - CSP, X-Frame-Options, HSTS, etc.
- **Session Hardening** - HttpOnly, Secure, SameSite strict mode
- **Crypto Random** - Use crypto/rand to generate passwords and tokens
- **bcrypt Password** - Cost factor 12, high-strength encryption
- **Long Session Time** - 360 minutes session timeout
- **API Hiding** - Unauthenticated requests return 404 (prevent endpoint detection)

### 📊 Core Features
- 🖥️ Real-time system monitoring (CPU, memory, network, disk)
- 👥 Multi-protocol multi-user management
- 📊 Traffic statistics and limits
- ⏰ Scheduled tasks (traffic reset, backup, etc.)
- 🔄 One-click update Xray Core
- 🌍 Multi-language support (Chinese, English, Persian, Vietnamese)

---

## 🚀 Quick Start

### One-Click Installation

```bash
bash <(curl -Ls https://raw.githubusercontent.com/CNYuns/yun/main/install.sh)
# Or use Gitee mirror
bash <(curl -Ls https://gitee.com/cnyuns/yun/raw/main/install.sh)
```

The installation script will automatically:
- ✅ Detect system type and architecture
- ✅ Download corresponding version binary files
- ✅ Configure systemd service
- ✅ Generate random admin account, password, port, and path
- ✅ Start service

**⚠️ Please save the login information displayed after installation!**

### System Requirements

- **Operating System**: Linux (Ubuntu, Debian, CentOS, Fedora, Arch, Alpine, OpenSUSE, etc.) / Windows
- **Architecture**:
  - Linux: amd64, arm64
  - Windows: amd64, 386
- **Minimum Configuration**: 1 CPU core, 512MB memory, 10GB hard disk

---

## 📦 Protocol Support

### Mainstream Protocols
- ✅ VMess
- ✅ VLESS
- ✅ Trojan
- ✅ Shadowsocks
- ✅ Socks5
- ✅ Dokodemo-door
- ✅ HTTP/HTTPS

### Transport Methods
- TCP
- WebSocket
- gRPC
- HTTP Upgrade
- mKCP
- QUIC

---

## 🎛️ Management Commands

After installation, use the `yun` command to manage the panel:

```bash
yun                  # Display management menu
yun start            # Start panel
yun stop             # Stop panel
yun restart          # Restart panel
yun status           # View status
yun enable           # Enable auto-start
yun disable          # Disable auto-start
yun log              # View logs
yun update           # Update panel to latest version
yun install          # Reinstall
yun uninstall        # Uninstall panel
```

---

## ⚙️ Configuration

### Default Paths

- **Installation Directory**: `/usr/local/yun/`
- **Configuration File**: `/usr/local/yun/config.json`
- **Database**: `/usr/local/yun/yun.db`
- **Log Directory**: `/var/log/yun/`
- **Service File**: `/etc/systemd/system/yun.service`

### Access Panel

After installation, visit:
```
http://Server_IP:Port/Path
```

For example: `http://192.168.1.100:12345/admin/`

**First login** uses the random username and password displayed during installation.

---

## 🔐 Security Recommendations

### Deployment Security
1. ✅ **Enable HTTPS** - Must use HTTPS in production
2. ✅ **Firewall Restrictions** - Only allow necessary IPs to access management panel
3. ✅ **Strong Password** - Change default account password to complex password (16+ characters recommended)
4. ✅ **Regular Updates** - Update Yun Panel and Xray Core in time
5. ✅ **Change Default Port** - Don't use default ports like 54321
6. ✅ **Custom Path** - Don't use `/` as panel path

---

## 🌐 Reverse Proxy

### Nginx Configuration Example

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location /your-path/ {
        proxy_pass http://127.0.0.1:54321/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🛠️ Tech Stack

- **Backend**: Go 1.23+
- **Web Framework**: Gin
- **Database**: SQLite + GORM
- **Frontend**: Bootstrap 5 + jQuery 3.7.1
- **Core**: Xray Core v25.6.8
- **UI Components**: Bootstrap Icons, Moment.js, QRCode.js

---

## 📄 License

This project is for learning and communication purposes only. Please comply with local laws and regulations.

---

## 🤝 Contribution

Welcome to submit Issues and Pull Requests!

### Contribution Guide
1. Fork this repository
2. Create new branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📬 Contact

- **Project**:
  - GitHub: https://github.com/CNYuns/yun
  - Gitee: https://gitee.com/cnyuns/yun
- **Issue**:
  - GitHub: https://github.com/CNYuns/yun/issues
  - Gitee: https://gitee.com/cnyuns/yun/issues
- **QQ Group**: [Click to Join](https://qm.qq.com/q/ZEXU9SNqYm)
- **Email**: admin@quanx.org

---

## ⚠️ Disclaimer

**This project is for learning and communication purposes only**. Please comply with local laws and regulations and prohibit illegal use.

Any consequences arising from the use of this project shall be borne by the user and have nothing to do with the developer.

---

## 🌟 Star History

If you like this project, please give it a Star ⭐!

---

**Last Update**: 2025-11-08

---

## 📝 Changelog

### v3.1.5 (2025-11-08)

**Gitee Pipeline Fixes**
- 🔧 **Fixed Artifact Packaging** - Generate independent archives directly in build directory, avoid Gitee auto-packaging
- 📦 **Fixed File Output** - Linux versions output tar.gz, Windows versions output zip
- 🚀 **Fixed Release Publishing** - Fixed publish@release_artifacts configuration, auto-upload 4 independent files
- ✅ **Artifact Optimization** - Removed intermediate release directory, generate final artifacts directly

**Technical Improvements**
- Changed artifacts.path to specific file list, avoid wildcard packaging issues
- Changed dependArtifact to BUILD_ARTIFACT, ensure correct artifact transfer
- Unified archive naming: yun-linux-amd64.tar.gz, yun-windows-amd64.zip

---

### v3.1.4 (2025-11-08)

**Pipeline Fixes**
- 🔧 **Fixed All Gitee Go Pipeline Configurations** - Unified upgrade to Go 1.21
- 🚀 **Fixed branch-pipeline.yml** - Go 1.12 → 1.21, added GOPROXY configuration
- ⚡ **Fixed master-pipeline.yml** - Go 1.16 → 1.21, added GOPROXY configuration
- 🎯 **Optimized Build Commands** - All pipelines use consistent build parameters and mirror configuration

---

### v3.1.3 (2025-11-08)

**Build Fixes**
- 🔧 **Fixed Gitee Go Pipeline Build Failure** - Go version upgraded from 1.16 to 1.21
- 🚀 **Configured GOPROXY China Mirrors** - Using goproxy.cn and goproxy.io for acceleration
- ⚡ **Optimized Build Process** - Added dependency pre-download and error handling

---

### v3.1.2 (2025-11-08)

**Critical Fixes (Code Audit)**
- 🐛 **Fixed Route Duplication** - InboundController nested routing groups caused duplicate registration
- 🔧 **Fixed Wrong Error Messages** - 11 instances showing success messages on validation failures
- 🛡️ **Fixed XSS Vulnerability** - Frontend directly inserted user data without escaping, added escapeHtml function

**Technical Improvements**
- ✅ InboundController.initRouter() no longer creates nested groups
- ✅ All error handling unified to use "somethingWentWrong" message
- ✅ All user input data HTML-escaped before display
- ✅ Enhanced code security and robustness

---

### v3.1.1 (2025-11-08)
