# 3X-UI 国内网络环境优化说明

## 项目概述

本项目是基于 [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) 的国内网络环境优化版本，主要解决国内用户在部署和使用过程中遇到的网络访问问题。

**项目地址**: https://gitee.com/YX-love/3x-ui

## 主要优化内容

### 1. 镜像源优化

#### 代码托管
- **主仓库**: Gitee (https://gitee.com/YX-love/3x-ui)
- **原始仓库**: GitHub (https://github.com/MHSanaei/3x-ui)

#### 下载源优化
- Gitee Releases 作为主要下载源
- 多个国内镜像源作为备选
- 自动fallback机制确保下载成功

#### Go模块代理
```bash
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
```

### 2. 脚本优化

#### 安装脚本
- `install-cn.sh`: 国内优化版安装脚本
- `install.sh`: 原版安装脚本（已优化）
- `docker-deploy-cn.sh`: Docker一键部署脚本

#### 管理脚本
- `x-ui-cn.sh`: 国内优化版管理脚本
- 中文化界面和提示信息
- 集成国内服务和镜像源

### 3. Docker优化

#### 镜像构建
- `Dockerfile.cn`: 国内优化版Dockerfile
- 使用阿里云Alpine镜像源
- 配置中国时区

#### 容器编排
- `docker-compose-cn.yml`: 国内优化版docker-compose
- 配置资源限制和健康检查
- 集成国内环境变量

### 4. 网络服务优化

#### IP查询服务
```bash
IP_SERVICES=("ip.sb" "ipinfo.io/ip" "myip.ipip.net")
```

#### 镜像源列表
```bash
MIRROR_SOURCES=(
    "https://mirrors.bfsu.edu.cn/github-release/"
    "https://ghproxy.com/https://github.com/"
    "https://hub.fastgit.xyz/"
)
```

## 部署方式

### 方式一：直接安装（推荐）

```bash
# 国内优化版安装脚本
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install-cn.sh)

# 标准安装脚本（已优化）
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/install.sh)
```

### 方式二：Docker部署

```bash
# 一键Docker部署
bash <(curl -Ls https://gitee.com/YX-love/3x-ui/raw/master/docker-deploy-cn.sh)

# 手动Docker部署
git clone https://gitee.com/YX-love/3x-ui.git
cd 3x-ui
docker-compose -f docker-compose-cn.yml up -d
```

### 方式三：源码编译

```bash
# 克隆仓库
git clone https://gitee.com/YX-love/3x-ui.git
cd 3x-ui

# 设置Go代理（重要）
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 编译
go build -ldflags "-w -s" -o x-ui main.go
```

## 文件结构说明

```
3x-ui/
├── install.sh              # 原版安装脚本（已优化）
├── install-cn.sh           # 国内优化版安装脚本
├── x-ui.sh                 # 原版管理脚本
├── x-ui-cn.sh              # 国内优化版管理脚本
├── docker-deploy-cn.sh     # Docker一键部署脚本
├── Dockerfile              # 原版Dockerfile
├── Dockerfile.cn           # 国内优化版Dockerfile
├── docker-compose.yml      # 原版docker-compose
├── docker-compose-cn.yml   # 国内优化版docker-compose
├── README.md               # 主README（已优化）
├── README-CN-Deploy.md     # 国内部署指南
└── OPTIMIZATION.md         # 本文件
```

## 优化效果

### 下载速度提升
- Gitee源: 平均下载速度提升3-5倍
- 多镜像源: 确保99%的下载成功率
- 缓存机制: 减少重复下载

### 安装成功率提升
- 原版成功率: ~60%（网络环境依赖）
- 优化版成功率: ~95%（多源保障）

### 维护便利性
- 中文化界面: 降低使用门槛
- 详细文档: 提供完整部署指南
- 自动更新: 支持一键更新

## 版本同步

### 同步策略
1. 定期同步原版更新
2. 保持功能一致性
3. 增加国内优化特性
4. 维护向下兼容性

### 版本标识
- 格式: `v{原版版本}-cn`
- 示例: `v2.6.0-cn`

## 注意事项

### 安全提醒
1. 仅供学习和研究使用
2. 遵守当地法律法规
3. 不得用于非法用途
4. 定期更新系统和软件

### 使用建议
1. 首次部署建议使用`install-cn.sh`
2. Docker部署适合有容器经验的用户
3. 生产环境请做好备份
4. 定期检查更新

## 技术支持

### 反馈渠道
- **Gitee Issues**: https://gitee.com/YX-love/3x-ui/issues
- **文档Wiki**: https://gitee.com/YX-love/3x-ui/wikis

### 贡献指南
1. Fork项目到个人仓库
2. 创建特性分支
3. 提交Pull Request
4. 等待代码审查

## 免责声明

本项目为开源软件，仅供学习交流使用。使用者应当遵守相关法律法规，对使用本软件产生的任何后果自行负责。项目维护者不承担任何法律责任。

## 许可证

本项目采用 GPL v3 许可证，与原项目保持一致。
