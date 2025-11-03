# 3x-ui

> **声明**: 该项目仅供学习交流使用，禁止用于非法用途，使用者与本项目开发者无关

> **注意**: 本仓库是 [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) 的国内优化版本，已针对国内网络环境进行优化

具体的使用请参考GitHub原版！当前版本为 v2.6.1，文档更新时间 2025.11.3

3x-ui 是一个支持多协议多用户的 xray 面板，支持 V2ay、Trojan、Shadowsocks 等协议。

## 一键安装 & 升级

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install.sh)
```

## 核心功能

- 系统状态监控
- 多协议和多用户管理
- 流量统计和限制
- 自定义 xray 配置模板
- 支持 HTTPS 访问面板
- 支持跨节点管理
- 基于 gRPC 的节点间通信
- Web 安全增强（输入验证、速率限制、安全头）

## 安全特性

本版本增强了以下安全特性：

- 🔒 输入验证中间件 - 防止 SQL 注入、XSS 攻击
- 🚦 速率限制 - 防止暴力破解和 DDoS 攻击
- 🛡️ 安全响应头 - 增强浏览器安全策略
- 🔐 会话安全加固 - HttpOnly、Secure、SameSite
- 🎲 随机安全参数 - 安装时自动生成随机用户名、密码、端口和路径

## 构建说明

如需自行构建多平台版本，请参阅 [BUILD.md](BUILD.md)

支持平台：
- Linux (amd64, arm64, armv7, armv6, armv5, 386, s390x)
- Windows (amd64)

## 重要提示

- 修改面板端口后，请同时在防火墙放行对应端口
- 使用 Nginx 等反向代理面板时，请配置 WebSocket 支持
- 面板配置文件位于 `/usr/local/x-ui/config.json`，可通过命令或直接修改文件来配置面板
- 首次安装会自动生成随机的用户名、密码、端口和访问路径，请务必保存安装完成后显示的信息

## 交流讨论

QQ群：[点击加入](https://qm.qq.com/q/ZEXU9SNqYm)
