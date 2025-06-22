# 3X-UI 面板

[![](https://img.shields.io/badge/TG群-@xuifengrui-blue.svg)](https://t.me/xuifengrui)

> **免责声明：此项目仅供个人学习交流使用，请勿用于商业用途，请勿用于非法用途，否则后果自负。**

一个基于Web的Xray面板，支持多协议、多用户的代理管理系统。

## 功能特性

- 系统状态监控（CPU、内存、网络状态、系统负载）
- 支持多协议，网页可视化操作
- 支持的协议：vmess、vless、trojan、shadowsocks、dokodemo-door、socks、http
- 支持配置更多传输配置
- 流量统计，限制流量，限制到期时间
- 可自定义xray配置模板
- 支持https访问面板（自备域名+ssl证书）
- 支持一键SSL证书申请且自动续签
- 更多高级配置项，详见面板

## 安装 & 升级

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/main/install.sh)
```

## 手动安装 & 升级

1. 首先从 https://gitee.com/YX-love/3x-ui/releases 下载最新的压缩包，一般选择 `amd64` 架构
2. 上传压缩包到服务器的 `/root/` 目录并解压

```bash
# 如果你的服务器cpu架构不是amd64，请将命令中的amd64替换为其他架构
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui
```

## 默认设置

- 端口：54321
- 用户名和密码：安装完成后自动生成，请查看安装日志
- 数据库：SQLite3
- 证书申请：acme.sh

## 建议系统

- CentOS 8+
- Ubuntu 20+
- Debian 11+
- Fedora 36+
- Arch Linux
- Manjaro
- Armbian
- AlmaLinux 9+
- Rocky Linux 9+
- Oracle Linux 8+
- OpenSUSE Tumbleweed

## 架构

- x86-64(amd64)
- ARM64
- ARMv7

## 常用命令

```bash
x-ui              # 显示管理菜单
x-ui start        # 启动x-ui面板
x-ui stop         # 停止x-ui面板
x-ui restart      # 重启x-ui面板
x-ui status       # 查看x-ui状态
x-ui enable       # 设置x-ui开机自启
x-ui disable      # 取消x-ui开机自启
x-ui log          # 查看x-ui日志
x-ui update       # 更新x-ui面板
x-ui install      # 安装x-ui面板
x-ui uninstall    # 卸载x-ui面板
```

## 面板截图

![](media/Web.PNG)

## 支持的协议

- vmess
- vless
- trojan
- shadowsocks
- dokodemo-door
- socks
- http

## 环境变量

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| XUI_LOG_LEVEL | string | info | 日志级别: `debug`, `info`, `warn`, `error` |
| XUI_DEBUG | boolean | false | debug模式开关 |
| XUI_BIN_FOLDER | string | bin | xray核心文件夹 |
| XUI_DB_FOLDER | string | /etc/x-ui | 数据库文件夹 |

## 注意事项

1. 请使用最新版本的浏览器
2. 请确保服务器防火墙已开放面板端口
3. 建议使用稳定的网络环境
4. 定期备份面板数据

## 问题反馈

如果您在使用过程中遇到问题，请通过以下方式反馈：

- [Issues](https://gitee.com/YX-love/3x-ui/issues)
- [QQ群：788905815](https://jq.qq.com/?_wv=1027&k=eDIH0Znt)
- [Telegram群](https://t.me/xuifengrui)

## 开源协议

[GPL v3](LICENSE)

## 致谢

- [vaxilu/x-ui](https://github.com/vaxilu/x-ui)
- [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- [gin-gonic/gin](https://github.com/gin-gonic/gin)

## 捐赠

如果您觉得这个项目对您有帮助，欢迎捐赠支持开发者：

**支付宝**: 
![](media/alipay.jpg)

**微信**: 
![](media/wechat.jpg)

感谢您的支持！
