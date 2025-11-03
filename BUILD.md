# 3x-ui 多架构构建指南

## 📋 构建所需平台

- ✅ x-ui-linux-amd64.tar.gz
- ✅ x-ui-linux-arm64.tar.gz
- ✅ x-ui-linux-armv7.tar.gz
- ✅ x-ui-linux-armv6.tar.gz
- ✅ x-ui-linux-armv5.tar.gz
- ✅ x-ui-linux-386.tar.gz
- ✅ x-ui-linux-s390x.tar.gz
- ✅ x-ui-windows-amd64.zip

---

## 🛠️ 构建步骤

### 步骤 1: 准备 Linux 构建环境

**推荐使用 Ubuntu 22.04 或更高版本**

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y
```

---

### 步骤 2: 安装 Go 环境

```bash
# 下载 Go 1.21+ (根据 go.mod 中的版本)
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz

# 解压
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz

# 设置环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
source ~/.bashrc

# 验证安装
go version
```

应该显示：`go version go1.21.6 linux/amd64` 或更高版本

---

### 步骤 3: 安装交叉编译工具链

**这是最重要的步骤！需要为每个架构安装对应的 GCC 编译器。**

```bash
# 更新包列表
sudo apt update

# 安装所有必需的交叉编译工具
sudo apt install -y \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    gcc-arm-linux-gnueabi \
    gcc-i686-linux-gnu \
    gcc-s390x-linux-gnu \
    gcc-mingw-w64-x86-64 \
    unzip \
    zip \
    wget \
    curl

# 验证安装
which gcc                           # 本地 gcc
which aarch64-linux-gnu-gcc         # ARM64
which arm-linux-gnueabihf-gcc       # ARMv6/v7
which arm-linux-gnueabi-gcc         # ARMv5
which i686-linux-gnu-gcc            # 386
which s390x-linux-gnu-gcc           # s390x
which x86_64-w64-mingw32-gcc        # Windows
```

**如果所有命令都返回路径，说明安装成功！**

---

### 步骤 4: 进入项目目录

```bash
cd /path/to/3x-ui
```

---

### 步骤 5: 执行构建脚本

```bash
# 给脚本执行权限
chmod +x build.sh

# 运行构建（大约需要 10-30 分钟，取决于网络速度）
./build.sh
```

---

## 📦 构建过程

脚本会自动执行以下操作：

1. **清理旧文件**
   - 删除之前的构建产物

2. **编译 x-ui 二进制文件**（每个平台）
   - 使用对应的交叉编译器
   - 启用 CGO（因为使用了 SQLite）
   - 优化编译（-ldflags "-w -s"）

3. **下载 Xray-core**（每个平台）
   - 从 GitHub 下载对应架构的 Xray
   - 版本：v25.6.8

4. **下载 Geo 数据库文件**
   - geoip.dat / geosite.dat（通用）
   - geoip_IR.dat / geosite_IR.dat（伊朗）
   - geoip_RU.dat / geosite_RU.dat（俄罗斯）

5. **打包发布文件**
   - Linux 平台：tar.gz
   - Windows 平台：zip

---

## ✅ 验证构建结果

构建成功后，会在项目根目录生成以下文件：

```bash
ls -lh x-ui-*.tar.gz x-ui-*.zip
```

应该看到：

```
x-ui-linux-amd64.tar.gz
x-ui-linux-arm64.tar.gz
x-ui-linux-armv7.tar.gz
x-ui-linux-armv6.tar.gz
x-ui-linux-armv5.tar.gz
x-ui-linux-386.tar.gz
x-ui-linux-s390x.tar.gz
x-ui-windows-amd64.zip
```

---

## 🔍 故障排查

### 问题 1: Go 命令未找到

**错误**: `go: command not found`

**解决**:
```bash
# 重新加载环境变量
source ~/.bashrc

# 或手动设置
export PATH=$PATH:/usr/local/go/bin
```

---

### 问题 2: 交叉编译器未找到

**错误**: `arm-linux-gnueabihf-gcc: command not found`

**解决**:
```bash
# 重新安装缺失的编译器
sudo apt install gcc-arm-linux-gnueabihf
```

---

### 问题 3: 下载 Xray 失败

**错误**: `下载 Xray 失败`

**解决**:
```bash
# 检查网络连接
ping github.com

# 或手动下载后放到项目目录，脚本会跳过下载
```

---

### 问题 4: CGO 编译错误

**错误**: `cgo: C compiler not available`

**解决**:
```bash
# 确保安装了对应平台的 gcc
sudo apt install gcc-<arch>-linux-gnu
```

---

### 问题 5: 内存不足

**错误**: `signal: killed`

**解决**:
```bash
# 增加 swap 空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📋 包内容

每个压缩包包含以下文件：

```
x-ui/
├── x-ui              # 主程序（或 x-ui.exe）
├── x-ui.sh           # 管理脚本（仅 Linux）
├── x-ui.service      # Systemd 服务（仅 Linux）
└── bin/
    ├── xray-linux-<arch>        # Xray 核心
    ├── geoip.dat                # IP 地理数据库
    ├── geosite.dat              # 域名地理数据库
    ├── geoip_IR.dat             # 伊朗 IP 数据库
    ├── geosite_IR.dat           # 伊朗域名数据库
    ├── geoip_RU.dat             # 俄罗斯 IP 数据库
    └── geosite_RU.dat           # 俄罗斯域名数据库
```

---

## 🚀 快速命令总结

**完整的一键构建命令（在 Ubuntu 22.04 上）：**

```bash
# 1. 安装 Go
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# 2. 安装交叉编译工具
sudo apt update && sudo apt install -y \
    gcc gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf \
    gcc-arm-linux-gnueabi gcc-i686-linux-gnu \
    gcc-s390x-linux-gnu gcc-mingw-w64-x86-64 \
    unzip zip wget curl

# 3. 构建
cd /path/to/3x-ui
chmod +x build.sh
./build.sh
```

---

## ⏱️ 预估时间

- 安装 Go 和工具链：5-10 分钟
- 编译所有平台：10-20 分钟（取决于 CPU）
- 下载 Xray 和 geo 文件：5-15 分钟（取决于网络）
- **总计：约 20-45 分钟**

---

## 📝 注意事项

1. ⚠️ **必须在 Linux 环境执行**
   - 推荐 Ubuntu 22.04
   - 或使用 WSL2 (Windows Subsystem for Linux)

2. ⚠️ **需要良好的网络**
   - 需要下载 Xray 核心（每个平台约 10-20MB）
   - 需要下载 geo 文件（共约 10MB）

3. ⚠️ **磁盘空间**
   - 至少需要 2GB 可用空间
   - Go 模块缓存会占用约 500MB

4. ⚠️ **内存要求**
   - 推荐至少 2GB RAM
   - 编译时会同时使用多个核心

---

## 🎉 完成后

构建完成后，你可以：

1. **上传到 GitHub Releases**
   ```bash
   # 使用 gh CLI 工具
   gh release create v1.0.0 x-ui-*.tar.gz x-ui-*.zip
   ```

2. **或手动上传**
   - 登录 GitHub
   - 进入仓库的 Releases 页面
   - 创建新 Release
   - 上传所有生成的 .tar.gz 和 .zip 文件

3. **验证包内容**
   ```bash
   # 查看 Linux 包内容
   tar -tzf x-ui-linux-amd64.tar.gz

   # 查看 Windows 包内容
   unzip -l x-ui-windows-amd64.zip
   ```

---

**祝构建顺利！** 🚀

如有问题，请检查故障排查部分或提交 Issue。
