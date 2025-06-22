# 3x-ui

> **声明**: 该项目仅供学习交流使用，禁止用于非法用途，使用者与本项目开发者无关

> **注意**: 本仓库是 [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) 的国内优化版本，已针对国内网络环境进行优化

3x-ui 是一个支持多协议多用户的 xray 面板，支持 V2ay、Trojan、Shadowsocks 等协议。

**如果您觉得本项目对您有帮助，请给个 star ⭐，感谢您的支持！**

## 功能介绍

- 系统状态监控
- 支持多协议和多用户管理
- 流量统计
- 可自定义 xray 配置模板
- 支持 https 访问面板
- 支持跨节点管理
- 基于 gRPC 的节点间通信

[English](./README.en.md) | 简体中文

## 一键安装 & 升级

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install.sh)
```

## 手动安装 & 升级

1. 首先从 [releases](https://gitee.com/YX-love/3x-ui/releases) 下载最新的压缩包
2. 解压后进入目录，执行以下命令安装或升级

```bash
chmod +x install.sh
./install.sh
```

## 使用方法

### 启动/停止/重启/查看状态

```bash
# 启动面板和 xray 内核
x-ui start

# 停止面板和 xray 内核
x-ui stop

# 重启面板和 xray 内核
x-ui restart

# 查看运行状态
x-ui status
```

### 修改配置

面板配置文件在 `/usr/local/x-ui/config.json`，可以通过命令或直接修改文件来配置面板

```bash
# 修改面板配置
x-ui setting
```

### 常用命令

```bash
# 在当前目录生成 SSL 证书
x-ui cert

# 修改面板设置
x-ui setting

# 重置用户名和密码
x-ui reset

# 显示所有命令
x-ui help
```

## 常见问题

### 从 v2-ui 迁移

首先在安装了 v2-ui 的服务器上安装最新版 x-ui，然后使用以下命令进行迁移，将迁移用户数据至 3x-ui：

```bash
x-ui v2-ui
```

### 更改默认 Web 端口

使用命令 `x-ui setting` 修改面板监听端口

### 重置用户名和密码

```bash
x-ui reset
```

## 注意事项

- 若修改面板端口，请同时在防火墙放行对应端口
- 使用 Nginx 等反向代理面板请配置 WebSocket 支持

## 赞助

如果您觉得本项目对您有帮助，欢迎赞助。

## 交流讨论

TG 群组：[点击加入](https://t.me/ChatGPTools)

## 截图

![页面展示](./media/dashboard.png)
![系统状态](./media/system.png)
![节点列表](./media/inbounds.png)