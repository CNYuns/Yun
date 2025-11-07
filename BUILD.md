# Yun Panel - 构建和发布指南

版本：v3.1.1

## 📦 构建选项

### 方式一：快速构建（推荐用于开发测试）

快速构建当前平台的版本：

```bash
# 赋予执行权限
chmod +x build-quick.sh

# 运行构建
./build-quick.sh
```

**输出文件：** `yun-linux-{platform}.tar.gz`

**支持的平台：**
- Linux: amd64（x86_64）, arm64（aarch64）
- Windows: amd64（64位）, 386（32位）

---

### 方式二：完整构建（用于发布）

构建所有支持的平台（Linux + Windows）：

```bash
# 赋予执行权限
chmod +x build.sh

# 运行完整构建
./build.sh
```

**构建的平台：**
- Linux: amd64, arm64
- Windows: amd64, 386

**输出文件：**
- `yun-linux-amd64.tar.gz`
- `yun-linux-arm64.tar.gz`
- `yun-windows-amd64.zip`
- `yun-windows-386.zip`

---

### 方式三：手动构建单个平台

```bash
# 设置环境变量
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=amd64

# 编译
go build -ldflags "-w -s" -o yun main.go

# 查看版本
./yun -v
```

---

## 🔧 前置依赖

### Linux 构建环境

**必需：**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gcc golang-go wget unzip

# Go 版本要求：>= 1.21
```

**跨平台编译（可选）：**

如果需要构建其他架构，需要安装对应的交叉编译工具链：

```bash
# ARM64
sudo apt install gcc-aarch64-linux-gnu

# ARMv7/ARMv6
sudo apt install gcc-arm-linux-gnueabihf

# ARMv5
sudo apt install gcc-arm-linux-gnueabi

# 386
sudo apt install gcc-i686-linux-gnu

# s390x
sudo apt install gcc-s390x-linux-gnu

# Windows
sudo apt install gcc-mingw-w64
```

---

## 🚀 发布流程

### 1. 更新版本号

```bash
# 编辑版本文件
nano config/version

# 内容示例：3.1.0
```

### 2. 构建所有平台

```bash
./build.sh
```

### 3. 创建 Git 标签

```bash
# 读取版本号
VERSION=$(cat config/version | tr -d '\n')

# 创建标签
git tag -a v${VERSION} -m "Release v${VERSION}"

# 推送标签
git push origin v${VERSION}
```

### 4. 上传到 Gitee Release

在 Gitee 仓库页面：
1. 进入 **发行版（Releases）** 页面
2. 点击 **创建发行版**
3. 选择标签 `v3.1.0`
4. 填写发行说明
5. 上传所有构建的文件：
   - `yun-linux-*.tar.gz`
   - `yun-windows-*.zip`
6. 发布

---

## 📝 构建输出说明

### Linux 压缩包内容：

```
yun-linux-amd64.tar.gz
├── yun              # 主程序
├── yun.sh           # 管理脚本
├── yun.service      # systemd 服务文件
└── bin/
    ├── xray-linux-amd64    # Xray 核心
    ├── geoip.dat           # IP 数据库
    ├── geosite.dat         # 域名数据库
    ├── geoip_IR.dat        # 伊朗 IP 数据库
    ├── geosite_IR.dat      # 伊朗域名数据库
    ├── geoip_RU.dat        # 俄罗斯 IP 数据库
    └── geosite_RU.dat      # 俄罗斯域名数据库
```

### Windows 压缩包内容：

```
yun-windows-amd64.zip
├── yun.exe                 # 主程序
└── bin/
    ├── xray-windows-amd64.exe  # Xray 核心
    └── geo 文件（同上）
```

---

## 🔍 版本信息

当前版本从以下文件读取：
- **文件位置：** `config/version`
- **当前版本：** 3.1.0

查看版本：
```bash
./yun -v
# 或
cat config/version
```

---

## ⚠️ 常见问题

### Q: 构建失败 "gcc: command not found"
**A:** 安装 GCC 编译器：
```bash
sudo apt-get install gcc
```

### Q: 跨平台编译失败
**A:** 安装对应平台的交叉编译工具链（见上方"前置依赖"部分）

### Q: 下载 Xray 或 geo 文件失败
**A:** 检查网络连接，或使用代理：
```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
./build.sh
```

### Q: Windows 构建失败
**A:** 确保已安装 MinGW-w64：
```bash
sudo apt install gcc-mingw-w64
```

---

## 📚 相关文档

- [安装指南](README.md#安装)
- [使用文档](README.md#使用)
- [GitHub Actions](.github/workflows/release.yml)

---

**构建时间估计：**
- 快速构建（单平台）：~2-5 分钟
- 完整构建（所有平台）：~15-30 分钟（取决于网络速度）

**磁盘空间要求：**
- 单个平台：~50 MB
- 所有平台：~400 MB
