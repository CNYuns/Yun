# 3X-UI 国内网络环境部署指南

## 概述

本版本是基于 [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) 项目针对国内网络环境进行的优化版本，托管在 Gitee 上以提供更稳定的访问和下载体验。

## 主要优化内容

### 1. 镜像源优化
- 使用 Gitee 作为主要代码托管平台
- 所有下载链接优先使用国内镜像源
- 提供多个备用下载源以确保可用性

### 2. 安装脚本优化
- **install-cn.sh**: 专门针对国内环境的安装脚本
- **x-ui-cn.sh**: 国内优化版管理脚本
- 集成多个国内IP查询服务
- 支持国内镜像源的地理位置数据库更新

### 3. 文档本地化
- 中文化操作界面和提示信息
- 提供详细的中文部署文档
- 国内用户友好的使用说明

## 快速部署

### 方法一：使用国内优化安装脚本（推荐）

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install-cn.sh)
```

### 方法二：使用标准安装脚本

```bash
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install.sh)
```

## 国内环境优化特性

### 1. 网络连接优化
- 使用国内IP查询服务：`ip.sb`、`ipinfo.io/ip`、`myip.ipip.net`
- 集成多个镜像源：北京外国语大学镜像、FastGit、ghproxy等
- 自动fallback机制，确保下载成功

### 2. 地理位置数据库更新
支持从多个国内镜像源更新：
- 标准版本（推荐）
- 伊朗版本
- 俄罗斯版本

### 3. Go 模块代理
推荐设置国内 Go 代理以加速编译：
```bash
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
```

## 管理命令

安装完成后，可以使用以下命令管理 3X-UI：

```bash
x-ui              # 显示管理菜单
x-ui start        # 启动服务
x-ui stop         # 停止服务
x-ui restart      # 重启服务
x-ui status       # 查看状态
x-ui enable       # 设置开机自启
x-ui disable      # 取消开机自启
x-ui log          # 查看日志
x-ui update       # 更新面板
x-ui install      # 安装面板
x-ui uninstall    # 卸载面板
```

## 系统要求

- **操作系统**: Ubuntu 20.04+, Debian 10+, CentOS 8+, 或其他主流 Linux 发行版
- **架构**: x86_64, arm64, armv7, armv6, armv5
- **内存**: 最少 512MB RAM
- **存储**: 最少 100MB 可用空间
- **网络**: 需要访问互联网进行安装和更新

## 防火墙配置

确保以下端口开放：
```bash
# 面板访问端口（默认随机生成）
ufw allow [面板端口]/tcp

# Xray 代理端口（根据配置而定）
ufw allow [代理端口]/tcp
ufw allow [代理端口]/udp
```

## 安全建议

1. **更改默认端口**: 安装后立即修改面板访问端口
2. **使用强密码**: 设置复杂的用户名和密码
3. **定期更新**: 保持面板和系统的最新版本
4. **网络安全**: 配置防火墙规则，限制不必要的访问
5. **备份配置**: 定期备份面板配置和数据

## 故障排除

### 1. 安装失败
- 检查网络连接
- 确认系统架构支持
- 查看安装日志：`journalctl -u x-ui -f`

### 2. 无法访问面板
- 检查防火墙设置
- 确认服务状态：`x-ui status`
- 查看面板配置：`x-ui`（选择"查看当前面板设置"）

### 3. 代理连接问题
- 检查端口是否开放
- 确认配置文件正确
- 查看 Xray 日志

## 更新记录

### v2.6.0-cn (当前版本)
- 基于原版 v2.6.0 优化
- 添加 Gitee 镜像源支持
- 优化国内网络环境部署
- 中文化界面和文档
- 集成多个备用下载源

## 技术支持

- **项目地址**: https://gitee.com/YX-love/3x-ui
- **原版项目**: https://github.com/MHSanaei/3x-ui
- **问题反馈**: 请在 Gitee 项目页面提交 Issue
- **使用文档**: 查看项目 Wiki 获取详细说明

## 许可证

本项目遵循 GPL v3 许可证，详情请参见 [LICENSE](LICENSE) 文件。

## 免责声明

本项目仅供学习和研究使用，请遵守当地法律法规，不得用于非法用途。作者不对使用本软件产生的任何后果承担责任。
