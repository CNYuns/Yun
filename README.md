# 3X-UI 管理面板

> **免责声明：此项目仅供个人学习交流使用，请勿用于商业用途，请勿用于非法用途，否则后果自负，请在下载后24小时内删除，谢谢合作！**

一个基于 Web 的 Xray 管理面板，支持多协议、多用户的代理管理系统。

[English](README_EN.md)

## 功能特性

- **系统状态监控** - CPU、内存、系统负载、网络状态
- **支持多协议** - VMess、VLESS、Trojan、Shadowsocks、Dokodemo-door、Socks、HTTP
- **支持多种传输配置**
- **流量统计** - 支持在线用户统计，多用户流量统计
- **日志监控** - 观察传输日志
- **数据库** - 支持 SQLite/MySQL/PostgreSQL
- **TLS 证书管理** - SSL 证书申请和续签
- **Telegram Bot** - 支持每日流量报告、面板登录提醒
- **备份恢复** - 支持面板设置及 Xray 配置导入导出

## 安装和升级

### 一键安装脚本

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/main/install.sh)
```

### 一键升级脚本

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/main/install.sh) update
```

### 手动安装

1. 下载最新版本的压缩包：https://gitee.com/YX-love/3x-ui/releases
2. 一般选择 `amd64` 架构
3. 解压并安装

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

## 默认设置

- **端口：** 54321
- **用户名和密码：** 登录面板后设置
- **数据库：** SQLite3
- **Xray 版本：** 最新版本
- **证书申请：** ACME v2

安装完成后，请使用 `x-ui` 命令打开控制菜单。

## 建议系统

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

## 架构支持

- amd64
- arm64
- armv7

## 常用命令

```bash
x-ui              # 显示管理菜单
x-ui start        # 启动 x-ui 面板
x-ui stop         # 停止 x-ui 面板
x-ui restart      # 重启 x-ui 面板
x-ui status       # 查看 x-ui 状态
x-ui enable       # 设置 x-ui 开机自启
x-ui disable      # 取消 x-ui 开机自启
x-ui log          # 查看 x-ui 日志
x-ui update       # 更新 x-ui 面板
x-ui install      # 安装 x-ui 面板
x-ui uninstall    # 卸载 x-ui 面板
```

## API 接口

面板提供了一套 RESTful API，可以通过 HTTP 请求与面板进行交互。

API 文档：[API.md](docs/API.md)

## 环境变量

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| XUI_LOG_LEVEL | string | info | 日志级别: `debug`, `info`, `warn`, `error` |
| XUI_DEBUG | boolean | false | 调试模式 |
| XUI_BIN_FOLDER | string | bin | xray 核心的文件夹 |
| XUI_DB_FOLDER | string | /etc/x-ui | 数据库文件夹 |

## 问题反馈

如果您在使用过程中遇到问题，请通过以下方式反馈：

- [Issues](https://gitee.com/YX-love/3x-ui/issues)

## 感谢

- [vaxilu/x-ui](https://github.com/vaxilu/x-ui)
- [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- [gin-gonic/gin](https://github.com/gin-gonic/gin)

## 开源协议

[GPL v3](https://gitee.com/YX-love/3x-ui/blob/main/LICENSE)

## 捐赠

如果您觉得这个项目对您有帮助，可以请作者喝杯咖啡 ☕

### 支付宝
[捐赠二维码]

### 微信支付
[捐赠二维码]

感谢您的支持！
