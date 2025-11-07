#!/bin/bash

# 定义颜色变量
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 检查系统类型
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif grep -Eqi "debian" /etc/issue; then
    release="debian"
elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
elif grep -Eqi "debian" /proc/version; then
    release="debian"
elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系开发者！${plain}\n" && exit 1
fi

# 检测系统架构
arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

# 检查系统位数
if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi

# 随机生成端口（10000-65000之间）
gen_random_port() {
    shuf -i 10000-65000 -n 1
}

# 生成随机字符串
gen_random_string() {
    local length=$1
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "${length}" | head -n 1
}

# 生成随机用户名（8位字符）
gen_random_username() {
    gen_random_string 8
}

# 生成随机密码（16位字符）
gen_random_password() {
    gen_random_string 16
}

# 生成随机URL路径（8位字符）
gen_random_path() {
    gen_random_string 8
}

# 获取服务器公网IP地址
get_server_ip() {
    local ip=""
    # 尝试多种获取公网IP的方法
    ip=$(curl -s https://api.ipify.org || 
         curl -s https://ipinfo.io/ip || 
         curl -s https://api.ip.sb/ip || 
         curl -s https://ifconfig.me/ip)
    
    if [[ -z "$ip" ]]; then
        # 如果无法获取公网IP，尝试获取本地IP
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    if [[ -z "$ip" ]]; then
        # 如果仍然无法获取IP，返回占位符
        ip="您的服务器IP"
    fi
    
    echo "$ip"
}

# 生成随机安全参数
PANEL_PORT=$(gen_random_port)
PANEL_USER=$(gen_random_username)
PANEL_PASS=$(gen_random_password)
PANEL_PATH="/$(gen_random_path)"

# 国内镜像源替换函数
use_china_mirror() {
    if [ -f /etc/apt/sources.list ]; then
        # 备份原始源
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        
        # Debian/Ubuntu镜像源替换为阿里云
        case $release in
            debian)
                sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
                sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
                ;;
            ubuntu)
                sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
                sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
                ;;
        esac
        
        apt update
    elif [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
        # CentOS镜像源替换为阿里云
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
        yum clean all
        yum makecache
    fi
}

# 检测国内环境并替换镜像源
ping -c 1 -W 2 google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${yellow}检测到国内网络环境，将使用国内镜像源进行安装${plain}"
    use_china_mirror
fi

# 获取系统版本
os_version=""

if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

# 检查系统版本
if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

# 安装基础软件包
install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 检查面板状态
# 返回值: 0-运行中, 1-未运行, 2-未安装
check_status() {
    if [[ ! -f /etc/systemd/system/yun.service ]]; then
        return 2
    fi
    temp=$(systemctl status yun | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

# 安装yun面板
install_yun() {
    # 检查服务是否存在，存在则停止
    if [ -f /etc/systemd/system/yun.service ]; then
        systemctl stop yun
    fi
    cd /usr/local/

    if [ $# == 0 ]; then
        # 获取最新版本号
        last_version="v3.1.3"
        echo -e "开始安装 yun ${last_version}"

        # 下载最新版本
        wget -N --no-check-certificate -O /usr/local/yun-linux-${arch}.tar.gz https://gitee.com/cnyuns/yun/releases/download/${last_version}/yun-linux-${arch}.tar.gz

        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 yun 失败，请确保你的服务器能够下载 Gitee 的文件${plain}"
            echo -e "${yellow}正在尝试使用 GitHub 下载链接...${plain}"

            # 备用下载链接（GitHub）
            wget -N --no-check-certificate -O /usr/local/yun-linux-${arch}.tar.gz https://github.com/CNYuns/yun/releases/download/${last_version}/yun-linux-${arch}.tar.gz

            if [[ $? -ne 0 ]]; then
                echo -e "${red}备用下载也失败，请手动下载并上传到服务器${plain}"
                exit 1
            fi
        fi
    else
        # 安装指定版本
        last_version=$1
        url="https://gitee.com/cnyuns/yun/releases/download/${last_version}/yun-linux-${arch}.tar.gz"
        echo -e "开始安装 yun v$1"
        wget -N --no-check-certificate -O /usr/local/yun-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 yun v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    # 删除旧目录并解压
    if [[ -e /usr/local/yun/ ]]; then
        rm /usr/local/yun/ -rf
    fi

    tar zxvf yun-linux-${arch}.tar.gz
    rm yun-linux-${arch}.tar.gz -f
    cd yun
    chmod +x yun bin/xray-linux-${arch}
    cp -f yun.service /etc/systemd/system/

    # 创建必要的目录
    mkdir -p /etc/yun
    mkdir -p /var/log/yun

    # 下载管理脚本
    wget --no-check-certificate -O /usr/bin/yun https://gitee.com/cnyuns/yun/raw/main/yun.sh
    chmod +x /usr/local/yun/yun.sh
    chmod +x /usr/bin/yun

    # 安装后配置 - 设置随机用户名和密码
    config_after_install

    # 启动服务
    systemctl daemon-reload
    systemctl enable yun
    systemctl start yun

    # 等待服务启动
    sleep 3

    # 验证配置是否正确设置
    echo -e "${yellow}正在验证配置...${plain}"
    ACTUAL_CONFIG=$(/usr/local/yun/yun setting -show 2>/dev/null)

    # 从配置输出中提取实际的端口和路径
    if [[ -n "$ACTUAL_CONFIG" ]]; then
        ACTUAL_PORT=$(echo "$ACTUAL_CONFIG" | grep "port:" | awk '{print $2}')
        ACTUAL_PATH=$(echo "$ACTUAL_CONFIG" | grep "webBasePath:" | awk '{print $2}')

        # 如果提取成功，使用实际值；否则使用预设值
        if [[ -n "$ACTUAL_PORT" ]]; then
            PANEL_PORT="$ACTUAL_PORT"
        fi
        if [[ -n "$ACTUAL_PATH" ]]; then
            PANEL_PATH="$ACTUAL_PATH"
        fi
    fi

    # 显示安装信息
    echo -e "${green}yun ${last_version}${plain} 安装完成，面板已启动"
    echo -e ""

    # 获取服务器IP地址
    SERVER_IP=$(get_server_ip)

    echo -e "面板访问信息如下(请妥善保存):"
    echo -e "------------------------"
    echo -e "面板地址: ${green}http://${SERVER_IP}:${PANEL_PORT}${PANEL_PATH}${plain}"
    echo -e "用户名: ${green}${PANEL_USER}${plain}"
    echo -e "密码: ${green}${PANEL_PASS}${plain}"
    echo -e "------------------------"
    echo -e "${red}注意: 以上访问信息是随机生成的，请务必记录保存，丢失将无法找回！${plain}"
    echo -e ""
    echo -e "yun 管理脚本使用方法: "
    echo -e "----------------------------------------------"
    echo -e "yun              - 显示管理菜单 (功能更多)"
    echo -e "yun start        - 启动 yun 面板"
    echo -e "yun stop         - 停止 yun 面板"
    echo -e "yun restart      - 重启 yun 面板"
    echo -e "yun status       - 查看 yun 状态"
    echo -e "yun enable       - 设置 yun 开机自启"
    echo -e "yun disable      - 取消 yun 开机自启"
    echo -e "yun log          - 查看 yun 日志"
    echo -e "yun update       - 更新 yun 面板"
    echo -e "yun install      - 安装 yun 面板"
    echo -e "yun uninstall    - 卸载 yun 面板"
    echo -e "----------------------------------------------"
}

# 安装后配置 - 设置随机用户名和密码
config_after_install() {
    echo -e "${yellow}正在进行安装后配置...${plain}"

    # 运行yun命令设置随机用户名、密码、端口和路径
    /usr/local/yun/yun setting -username ${PANEL_USER} -password ${PANEL_PASS} -port ${PANEL_PORT} -webBasePath ${PANEL_PATH}

    echo -e "${green}面板配置设置成功！${plain}"
}

# 执行安装
install_base
install_yun $1