#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 请使用root权限运行此脚本" && exit 1

# 检查Docker是否已安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${yellow}Docker 未安装，正在安装...${plain}"
        install_docker
    else
        echo -e "${green}Docker 已安装${plain}"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${yellow}Docker Compose 未安装，正在安装...${plain}"
        install_docker_compose
    else
        echo -e "${green}Docker Compose 已安装${plain}"
    fi
}

# 安装Docker（使用国内镜像源）
install_docker() {
    echo -e "${green}正在安装 Docker...${plain}"
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
    else
        echo -e "${red}无法检测操作系统${plain}"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            # 更新包索引
            apt-get update
            # 安装依赖
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            # 添加阿里云Docker GPG密钥
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            # 更新包索引
            apt-get update
            # 安装Docker
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        centos|rhel|rocky|almalinux)
            # 安装依赖
            yum install -y yum-utils
            # 添加Docker仓库
            yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            # 安装Docker
            yum install -y docker-ce docker-ce-cli containerd.io
            ;;
        *)
            echo -e "${red}不支持的操作系统: $OS${plain}"
            exit 1
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 配置Docker镜像加速器
    configure_docker_mirror
    
    echo -e "${green}Docker 安装完成${plain}"
}

# 配置Docker镜像加速器
configure_docker_mirror() {
    echo -e "${green}配置Docker镜像加速器...${plain}"
    
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com",
        "https://ccr.ccs.tencentyun.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    }
}
EOF
    
    systemctl restart docker
    echo -e "${green}Docker镜像加速器配置完成${plain}"
}

# 安装Docker Compose
install_docker_compose() {
    echo -e "${green}正在安装 Docker Compose...${plain}"
    
    # 使用国内镜像下载
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # 尝试从不同源下载
    if ! curl -L "https://ghproxy.com/https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    fi
    
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo -e "${green}Docker Compose 安装完成${plain}"
}

# 部署3X-UI
deploy_3xui() {
    echo -e "${green}正在部署 3X-UI...${plain}"
    
    # 创建工作目录
    mkdir -p /opt/3x-ui
    cd /opt/3x-ui
    
    # 下载项目文件
    if ! wget -q "https://gitee.com/YX-love/3x-ui/repository/archive/master.zip"; then
        echo -e "${yellow}从Gitee下载失败，尝试GitHub...${plain}"
        wget -q "https://github.com/MHSanaei/3x-ui/archive/refs/heads/main.zip"
        mv main.zip master.zip
    fi
    
    # 解压文件
    unzip -q master.zip
    cd 3x-ui-master 2>/dev/null || cd 3x-ui-main
    
    # 创建必要的目录
    mkdir -p db cert logs
    
    # 使用国内优化的Docker配置
    if [[ -f docker-compose-cn.yml ]]; then
        echo -e "${green}使用国内优化的Docker配置${plain}"
        docker-compose -f docker-compose-cn.yml up -d
    else
        echo -e "${yellow}使用标准Docker配置${plain}"
        docker-compose up -d
    fi
    
    # 等待服务启动
    echo -e "${green}等待服务启动...${plain}"
    sleep 10
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        echo -e "${green}3X-UI 部署成功！${plain}"
        
        # 获取服务器IP
        SERVER_IP=$(curl -s --connect-timeout 5 ip.sb || curl -s --connect-timeout 5 ipinfo.io/ip || echo "YOUR_SERVER_IP")
        
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${green}                    3X-UI Docker 部署完成${plain}"
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${blue}访问地址:${plain} http://${SERVER_IP}:54321"
        echo -e "${blue}默认用户名:${plain} admin"
        echo -e "${blue}默认密码:${plain} admin"
        echo -e ""
        echo -e "${yellow}常用管理命令:${plain}"
        echo -e "  docker-compose logs -f          # 查看日志"
        echo -e "  docker-compose restart          # 重启服务"
        echo -e "  docker-compose stop             # 停止服务" 
        echo -e "  docker-compose down             # 停止并删除容器"
        echo -e ""
        echo -e "${red}注意: 请立即登录面板修改默认用户名和密码！${plain}"
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo -e "${red}3X-UI 部署失败，请检查日志${plain}"
        docker-compose logs
    fi
}

# 主函数
main() {
    echo -e "${blue}3X-UI Docker 一键部署脚本 [国内优化版]${plain}"
    echo -e "${green}项目地址: https://gitee.com/YX-love/3x-ui${plain}"
    echo ""
    
    check_docker
    deploy_3xui
}

# 运行主函数
main
