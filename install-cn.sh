#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# 国内镜像源配置
GITEE_REPO="https://gitee.com/YX-love/3x-ui"
GITEE_RAW="https://gitee.com/YX-love/3x-ui/raw/master"
GITEE_RELEASES="https://gitee.com/YX-love/3x-ui/releases/download"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 请使用root权限运行此脚本 \n " && exit 1

# 检查操作系统版本
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "检查系统操作系统失败，请联系作者！" >&2
    exit 1
fi
echo "当前操作系统: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${red}不支持的CPU架构! ${plain}" && rm -f install-cn.sh && exit 1 ;;
    esac
}

echo "系统架构: $(arch)"

check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    
    required_version="2.32"
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC版本 $glibc_version 过低! 要求: 2.32 或更高版本${plain}"
        echo "请升级到更新版本的操作系统以获得更高的GLIBC版本。"
        exit 1
    fi
    echo "GLIBC版本: $glibc_version (满足2.32+要求)"
}
check_glibc_version

install_base() {
    echo -e "${green}正在安装基础软件包...${plain}"
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_hasDefaultCredential=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    
    # 使用国内IP查询服务
    local server_ip=$(curl -s --connect-timeout 5 ip.sb || curl -s --connect-timeout 5 ipinfo.io/ip || curl -s --connect-timeout 5 myip.ipip.net | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -rp "是否要自定义面板端口设置？(如果不设置，将使用随机端口) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -rp "请设置面板端口: " config_port
                echo -e "${yellow}您的面板端口为: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}生成的随机端口: ${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "这是全新安装，为安全起见生成随机登录信息:"
            echo -e "###############################################"
            echo -e "${green}用户名: ${config_username}${plain}"
            echo -e "${green}密码: ${config_password}${plain}"
            echo -e "${green}端口: ${config_port}${plain}"
            echo -e "${green}网页路径: ${config_webBasePath}${plain}"
            echo -e "${green}访问地址: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}网页路径缺失或过短。正在生成新的...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}新的网页路径: ${config_webBasePath}${plain}"
            echo -e "${green}访问地址: http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}检测到默认凭据。需要安全更新...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "生成新的随机登录凭据:"
            echo -e "###############################################"
            echo -e "${green}用户名: ${config_username}${plain}"
            echo -e "${green}密码: ${config_password}${plain}"
            echo -e "###############################################"
        else
            echo -e "${green}用户名、密码和网页路径已正确设置。正在退出...${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        # 使用固定版本 v2.6.0
        tag_version="v2.6.0"
        echo -e "使用 x-ui 版本: ${tag_version}，开始安装..."
        
        # 使用 Gitee 镜像源下载
        download_url="${GITEE_RELEASES}/${tag_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "${green}正在从 Gitee 镜像源下载...${plain}"
        wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz "$download_url"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}从 Gitee 下载 x-ui 失败，尝试备用下载源${plain}"
            # 备用源：直接使用 GitHub（虽然可能较慢）
            wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz "https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz"
            if [[ $? -ne 0 ]]; then
                echo -e "${red}下载 x-ui 失败，请检查网络连接或手动下载${plain}"
                exit 1
            fi
        fi
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.3.5"

        if [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]]; then
            echo -e "${red}请使用更新的版本 (至少 v2.3.5)。退出安装。${plain}"
            exit 1
        fi

        url="${GITEE_RELEASES}/${tag_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "开始安装 x-ui $1"
        wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui $1 失败，请检查版本是否存在${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    # 检查系统架构并重命名文件
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    
    # 使用 Gitee 源下载管理脚本
    wget -O /usr/bin/x-ui "${GITEE_RAW}/x-ui-cn.sh"
    if [[ $? -ne 0 ]]; then
        echo -e "${yellow}从 Gitee 下载管理脚本失败，使用本地脚本${plain}"
        cp -f x-ui.sh /usr/bin/x-ui
    fi
    
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} 安装完成，正在运行中..."
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui 管理脚本使用方法:${plain}                                │
│                                                       │
│  ${blue}x-ui${plain}              - 显示管理菜单                      │
│  ${blue}x-ui start${plain}        - 启动 x-ui 面板                   │
│  ${blue}x-ui stop${plain}         - 停止 x-ui 面板                   │
│  ${blue}x-ui restart${plain}      - 重启 x-ui 面板                   │
│  ${blue}x-ui status${plain}       - 查看 x-ui 状态                   │
│  ${blue}x-ui enable${plain}       - 设置开机自启                     │
│  ${blue}x-ui disable${plain}      - 取消开机自启                     │
│  ${blue}x-ui log${plain}          - 查看 x-ui 日志                   │
│  ${blue}x-ui update${plain}       - 更新 x-ui 面板                   │
│  ${blue}x-ui install${plain}      - 安装 x-ui 面板                   │
│  ${blue}x-ui uninstall${plain}    - 卸载 x-ui 面板                   │
└───────────────────────────────────────────────────────┘"
    echo -e ""
    echo -e "${green}项目地址: ${GITEE_REPO}${plain}"
    echo -e "${green}如果觉得有用，请给项目点个星⭐${plain}"
}

echo -e "${green}正在运行国内优化版安装脚本...${plain}"
install_base
install_x-ui $1
