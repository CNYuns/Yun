# Yun Panel - Xray 管理面板

> **声明**: 该项目仅供学习交流使用，禁止用于非法用途，使用者与本项目开发者无关

**当前版本**: v3.1.0
**更新日期**: 2025-11-05
**项目地址**: [gitee.com/CN-yun/yun](https://gitee.com/CN-yun/yun)

Yun Panel 是一个支持多协议多用户的 Xray 管理面板，提供简洁易用的 Web 界面，支持 VMess、VLESS、Trojan、Shadowsocks、Socks5 等主流代理协议。

---

## ✨ 特性亮点

### 🎨 全新界面
- **现代化设计** - Bootstrap 5 + jQuery 重构，紫色渐变主题
- **响应式布局** - 完美适配桌面、平板、手机
- **流畅动画** - 优雅的交互体验
- **深色模式** - 即将推出

### 🔒 安全增强
- **输入验证** - 防止 SQL 注入、XSS、路径遍历攻击
- **登录速率限制** - 防止暴力破解（15分钟5次失败封禁15分钟）
- **安全响应头** - CSP、X-Frame-Options、HSTS 等
- **会话加固** - HttpOnly、Secure、SameSite 严格模式
- **加密随机数** - 使用 crypto/rand 生成密码和 Token
- **bcrypt 密码** - Cost 因子 12，高强度加密
- **长会话时间** - 360 分钟会话超时
- **API 隐藏** - 未认证请求返回 404（防止端点探测）

### 📊 核心功能
- 🖥️ 系统状态实时监控（CPU、内存、网络、磁盘）
- 👥 多协议多用户管理
- 📊 流量统计和限制
- ⏰ 定时任务（流量重置、备份等）
- 🔄 一键更新 Xray Core
- 🌍 多语言支持（中文、英语、波斯语、越南语）

---

## 🚀 快速开始

### 一键安装

```bash
bash <(curl -Ls https://gitee.com/CN-yun/yun/raw/master/install.sh)
```

安装脚本会自动：
- ✅ 检测系统类型和架构
- ✅ 下载对应版本的二进制文件
- ✅ 配置 systemd 服务
- ✅ 生成随机的管理员账号、密码、端口和路径
- ✅ 启动服务

**⚠️ 安装完成后请务必保存显示的登录信息！**

### 系统要求

- **操作系统**: Linux (Ubuntu, Debian, CentOS, Fedora, Arch, Alpine, OpenSUSE 等)
- **架构**: amd64, arm64, armv7, armv6, armv5, 386, s390x
- **最低配置**: 1核 CPU, 512MB 内存, 10GB 硬盘

---

## 📦 协议支持

### 主流协议
- ✅ VMess
- ✅ VLESS
- ✅ Trojan
- ✅ Shadowsocks
- ✅ Socks5
- ✅ Dokodemo-door
- ✅ HTTP/HTTPS

### 传输方式
- TCP
- WebSocket
- gRPC
- HTTP Upgrade
- mKCP
- QUIC

---

## 🎛️ 管理命令

安装完成后，使用 `yun` 命令管理面板：

```bash
yun                  # 显示管理菜单
yun start            # 启动面板
yun stop             # 停止面板
yun restart          # 重启面板
yun status           # 查看状态
yun enable           # 设置开机自启
yun disable          # 取消开机自启
yun log              # 查看日志
yun update           # 更新面板到最新版本
yun install          # 重新安装
yun uninstall        # 卸载面板
```

---

## ⚙️ 配置说明

### 默认路径

- **安装目录**: `/usr/local/yun/`
- **配置文件**: `/usr/local/yun/config.json`
- **数据库**: `/usr/local/yun/yun.db`
- **日志目录**: `/var/log/yun/`
- **服务文件**: `/etc/systemd/system/yun.service`

### 访问面板

安装完成后，访问：
```
http://服务器IP:端口/路径
```

例如：`http://192.168.1.100:12345/admin/`

**首次登录**使用安装时显示的随机用户名和密码。

### 修改配置

可以通过以下方式修改配置：
1. **Web 界面** - 面板设置 → 面板配置
2. **命令行** - `yun` 进入管理菜单
3. **直接编辑** - 修改 `/usr/local/yun/config.json` 后执行 `yun restart`

---

## 🔐 安全建议

### 部署安全
1. ✅ **启用 HTTPS** - 生产环境必须使用 HTTPS
2. ✅ **防火墙限制** - 仅允许必要的 IP 访问管理面板
3. ✅ **强密码** - 修改默认账号密码为复杂密码（建议16位以上）
4. ✅ **定期更新** - 及时更新 Yun Panel 和 Xray Core
5. ✅ **修改默认端口** - 不要使用 54321 等默认端口
6. ✅ **自定义路径** - 不要使用 `/` 作为面板路径

### 网络安全
1. ✅ **使用 TLS** - 为入站规则启用 TLS 加密
2. ✅ **域名伪装** - 配置合法域名证书
3. ✅ **流量混淆** - 使用 WebSocket 或 gRPC 传输
4. ✅ **IP 限制** - 为客户端设置 IP 数量限制
5. ✅ **定期更换密钥** - 定期更新 UUID 和密码

### 日志管理
1. ✅ **定期清理** - 自动清理过期日志
2. ✅ **异常监控** - 关注失败的登录尝试
3. ✅ **流量审计** - 定期检查异常流量

---

## 🌐 反向代理

### Nginx 配置示例

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

        # 安全头
        proxy_set_header X-Frame-Options "SAMEORIGIN";
        proxy_set_header X-Content-Type-Options "nosniff";
        proxy_set_header X-XSS-Protection "1; mode=block";
    }
}
```

**重要提示**:
- ✅ 必须配置 WebSocket 支持（`Upgrade` 和 `Connection` 头）
- ✅ 设置 `X-Forwarded-Proto` 确保 HTTPS 检测正常
- ✅ 修改端口后记得在防火墙放行
- ✅ 配置 SSL 证书，推荐使用 Let's Encrypt

---

## ❓ 常见问题

### Q: 忘记登录密码怎么办？
A: 使用命令重置：
```bash
cd /usr/local/yun/
./yun setting -username 新用户名 -password 新密码
yun restart
```

### Q: 如何更换面板端口？
A:
1. **通过 Web 界面**：面板设置 → 面板配置 → 监听端口
2. **通过命令**：`yun` → 修改面板设置
3. **直接编辑**：修改 `/usr/local/yun/config.json` 中的 `webPort`
4. **重启面板**：`yun restart`
5. **放行端口**：`firewall-cmd --add-port=新端口/tcp --permanent && firewall-cmd --reload`

### Q: 如何备份数据？
A:
```bash
# 方法1: 命令行备份
cp /usr/local/yun/yun.db ~/yun-backup-$(date +%Y%m%d).db

# 方法2: 通过面板
# 面板设置 → 备份/恢复 → 导出数据库

# 恢复数据
cp ~/yun-backup.db /usr/local/yun/yun.db
yun restart
```

### Q: 更新后无法启动？
A:
```bash
# 1. 查看日志
yun log

# 2. 检查服务状态
systemctl status yun

# 3. 检查端口占用
netstat -tunlp | grep 54321

# 4. 重新安装（保留数据）
bash <(curl -Ls https://gitee.com/CN-yun/yun/raw/master/install.sh)
```

### Q: 如何卸载面板？
A:
```bash
yun uninstall
# 或
cd /usr/local/yun/ && bash yun.sh uninstall
```

---

## 🏗️ 构建说明

Yun Panel 使用 `install.sh` 脚本自动检测系统并下载对应的预编译二进制文件。

如需自行构建，请参考 [BUILD.md](BUILD.md) 文档。

### 支持的平台

| 操作系统 | 架构 | 说明 |
|---------|------|------|
| Linux | amd64 | 64位 Intel/AMD |
| Linux | arm64 | 64位 ARM（如树莓派4） |
| Linux | armv7 | 32位 ARMv7（如树莓派3） |
| Linux | armv6 | 32位 ARMv6（如树莓派1） |
| Linux | armv5 | 32位 ARMv5 |
| Linux | 386 | 32位 Intel/AMD |
| Linux | s390x | IBM S390x |
| Windows | amd64 | 64位 Intel/AMD |

### 快速构建

```bash
# 方法1: 快速构建当前平台
./build-quick.sh

# 方法2: 构建所有平台（需要交叉编译工具链）
./build.sh

# 方法3: 手动构建
go build -ldflags "-w -s" -o yun main.go
```

---

## 📝 版本更新

### v3.1.0 (2025-11-05)

**重大更新**
- 🎨 **前端重构** - Vue.js + Ant Design → Bootstrap 5 + jQuery
- 🌈 **UI 美化** - 全新紫色渐变主题，响应式设计
- 🏷️ **项目重命名** - 3x-ui → Yun Panel

**安全增强**
- 🔒 随机密码生成（crypto/rand，16位强密码）
- 🚫 未认证 API 请求返回 404（防止端点探测）
- 🕐 Session 超时延长至 360 分钟
- 🛡️ 新增 Web 安全中间件（输入验证、速率限制、安全头）

**功能改进**
- 📱 新增客户端配置生成器
- 🎯 修复命令注入漏洞
- 🔧 优化多处 Bug
- 📦 清理 14.4 MB 冗余文件

**架构优化**
- 🏗️ 完全独立的代码库
- 📦 优化项目结构
- 📝 完善文档

---

## 🛠️ 技术栈

- **后端**: Go 1.23+
- **Web 框架**: Gin
- **数据库**: SQLite + GORM
- **前端**: Bootstrap 5 + jQuery 3.7.1
- **核心**: Xray Core v25.6.8
- **UI 组件**: Bootstrap Icons, Moment.js, QRCode.js

---

## 📄 许可证

本项目仅供学习交流使用，请遵守当地法律法规。

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南
1. Fork 本仓库
2. 创建新分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📬 联系方式

- **项目地址**: https://gitee.com/CN-yun/yun
- **Issue**: https://gitee.com/CN-yun/yun/issues
- **QQ 群**: [点击加入](https://qm.qq.com/q/ZEXU9SNqYm)
- **邮箱**: admin@quanx.org

---

## ⚠️ 免责声明

**本项目仅供学习交流使用**，请遵守当地法律法规，禁止用于非法用途。

使用本项目产生的任何后果由使用者自行承担，与开发者无关。

---

## 🌟 Star History

如果觉得项目不错，请给个 Star ⭐ 支持一下！

---

**最后更新**: 2025-11-05
