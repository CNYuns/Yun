#!/bin/bash

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# 当前目录
cur_dir=$(pwd)

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}错误: ${plain}请使用root权限运行此脚本\n"
    exit 1
fi

# 检查操作系统
check_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        release=$ID
    elif [[ -f /usr/lib/os-release ]]; then
        source /usr/lib/os-release
        release=$ID
    else
        echo "无法检测系统类型，请联系作者！" >&2
        exit 1
    fi
    echo "检测到操作系统: $release"
}

# 检测架构
get_arch() {
    case "$(uname -m)" in
        x86_64 | x64 | amd64) echo 'amd64' ;;
        i*86 | x86) echo '386' ;;
        armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
        armv7* | armv7 | arm) echo 'armv7' ;;
        armv6* | armv6) echo 'armv6' ;;
        armv5* | armv5) echo 'armv5' ;;
        s390x) echo 's390x' ;;
        *) echo -e "${red}不支持的CPU架构! ${plain}" && exit 1 ;;
    esac
}

# 检查GLIBC版本
check_glibc() {
    if command -v ldd >/dev/null 2>&1; then
        glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
        required_version="2.32"
        if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
            echo -e "${red}GLIBC版本 $glibc_version 太旧! 需要: 2.32 或更高版本${plain}"
            echo "请升级到更新版本的操作系统以获得更高的GLIBC版本。"
            exit 1
        fi
        echo "GLIBC版本: $glibc_version (满足2.32+要求)"
    else
        echo -e "${yellow}警告: 无法检测GLIBC版本，继续安装...${plain}"
    fi
}

# 安装基础依赖
install_dependencies() {
    echo -e "${blue}正在安装基础依赖...${plain}"
    
    case "${release}" in
        ubuntu | debian | armbian)
            apt-get update -qq && apt-get install -y -qq wget curl tar tzdata
            ;;
        centos | rhel | almalinux | rocky | ol)
            yum -y update -q && yum install -y -q wget curl tar tzdata
            ;;
        fedora | amzn | virtuozzo)
            dnf -y update -q && dnf install -y -q wget curl tar tzdata
            ;;
        arch | manjaro | parch)
            pacman -Syu --noconfirm -q && pacman -S --noconfirm -q wget curl tar tzdata
            ;;
        opensuse-tumbleweed)
            zypper refresh -q && zypper -q install -y wget curl tar timezone
            ;;
        *)
            apt-get update -qq && apt-get install -y -qq wget curl tar tzdata
            ;;
    esac
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}安装依赖失败！${plain}"
        exit 1
    fi
    echo -e "${green}依赖安装完成${plain}"
}

# 生成随机字符串
generate_random_string() {
    local length="$1"
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result=""
    for ((i=0; i<length; i++)); do
        result="${result}${chars:RANDOM%${#chars}:1}"
    done
    echo "$result"
}

# 获取服务器IP
get_server_ip() {
    local ip=""
    # 尝试多个IP获取服务
    for service in "https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
        ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null)
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    echo "127.0.0.1"
}

# 配置安装后的设置
configure_after_install() {
    echo -e "${blue}正在配置面板设置...${plain}"
    
    # 等待服务启动
    sleep 3
    
    # 检查x-ui是否正常运行
    if ! /usr/local/x-ui/x-ui status >/dev/null 2>&1; then
        echo -e "${red}x-ui服务未正常运行，请检查日志${plain}"
        return 1
    fi
    
    local server_ip=$(get_server_ip)
    local config_username=$(generate_random_string 10)
    local config_password=$(generate_random_string 10)
    local config_webBasePath=$(generate_random_string 15)
    local config_port=$(shuf -i 1024-62000 -n 1)
    
    # 询问是否自定义端口
    echo -e "${yellow}是否要自定义面板端口设置？(如果不设置，将使用随机端口) [y/n]: ${plain}"
    read -r config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        echo -e "${yellow}请输入面板端口: ${plain}"
        read -r config_port
        if [[ ! "$config_port" =~ ^[0-9]+$ ]] || [[ "$config_port" -lt 1024 ]] || [[ "$config_port" -gt 65535 ]]; then
            echo -e "${red}端口号无效，使用随机端口${plain}"
            config_port=$(shuf -i 1024-62000 -n 1)
        fi
    fi
    
    # 应用配置
    /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
    
    # 运行数据库迁移
    /usr/local/x-ui/x-ui migrate
    
    echo -e "${green}配置完成！以下是您的登录信息：${plain}"
    echo -e "###############################################"
    echo -e "${green}用户名: ${config_username}${plain}"
    echo -e "${green}密码: ${config_password}${plain}"
    echo -e "${green}端口: ${config_port}${plain}"
    echo -e "${green}Web路径: ${config_webBasePath}${plain}"
    echo -e "${green}访问地址: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
    echo -e "###############################################"
    echo -e "${yellow}请保存好以上信息！${plain}"
}

# 安装x-ui
install_xui() {
    echo -e "${blue}开始安装x-ui...${plain}"
    
    cd /usr/local/ || exit 1
    
    # 获取最新版本
    local tag_version=""
    if [[ $# -eq 0 ]]; then
        echo -e "${blue}正在获取最新版本...${plain}"
        tag_version=$(curl -Ls --connect-timeout 10 "https://gitee.com/api/v5/repos/YX-love/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        
        if [[ -z "$tag_version" ]]; then
            echo -e "${red}获取版本失败，使用默认版本${plain}"
            tag_version="v2.3.5"
        fi
    else
        tag_version=$1
    fi
    
    echo -e "${green}安装版本: ${tag_version}${plain}"
    
    # 下载文件
    local arch_type=$(get_arch)
    local download_url="https://gitee.com/YX-love/3x-ui/releases/download/${tag_version}/x-ui-linux-${arch_type}.tar.gz"
    local download_file="/usr/local/x-ui-linux-${arch_type}.tar.gz"
    
    echo -e "${blue}正在下载x-ui...${plain}"
    if ! wget -O "$download_file" "$download_url"; then
        echo -e "${red}下载失败！请检查网络连接或版本是否存在${plain}"
        exit 1
    fi
    
    # 停止现有服务
    if systemctl is-active --quiet x-ui; then
        echo -e "${blue}停止现有x-ui服务...${plain}"
        systemctl stop x-ui
    fi
    
    # 删除旧版本
    if [[ -d /usr/local/x-ui ]]; then
        echo -e "${blue}删除旧版本...${plain}"
        rm -rf /usr/local/x-ui
    fi
    
    # 解压文件
    echo -e "${blue}正在解压文件...${plain}"
    if ! tar -xzf "$download_file"; then
        echo -e "${red}解压失败！${plain}"
        exit 1
    fi
    
    # 清理下载文件
    rm -f "$download_file"
    
    # 设置权限
    cd /usr/local/x-ui || exit 1
    chmod +x x-ui
    
    # 处理ARM架构
    if [[ "$arch_type" == "armv5" || "$arch_type" == "armv6" || "$arch_type" == "armv7" ]]; then
        if [[ -f "bin/xray-linux-${arch_type}" ]]; then
            mv "bin/xray-linux-${arch_type}" "bin/xray-linux-arm"
            chmod +x bin/xray-linux-arm
        fi
    fi
    
    # 设置xray权限
    if [[ -f "bin/xray-linux-${arch_type}" ]]; then
        chmod +x "bin/xray-linux-${arch_type}"
    fi
    
    # 安装systemd服务
    if [[ -f x-ui.service ]]; then
        cp -f x-ui.service /etc/systemd/system/
    fi
    
    # 下载管理脚本
    echo -e "${blue}下载管理脚本...${plain}"
    if wget -O /usr/bin/x-ui https://gitee.com/YX-love/3x-ui/raw/main/x-ui.sh; then
        chmod +x /usr/bin/x-ui
    else
        echo -e "${yellow}下载管理脚本失败，使用本地脚本${plain}"
        if [[ -f x-ui.sh ]]; then
            cp x-ui.sh /usr/bin/x-ui
            chmod +x /usr/bin/x-ui
        fi
    fi
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 启用并启动服务
    echo -e "${blue}启动x-ui服务...${plain}"
    systemctl enable x-ui
    systemctl start x-ui
    
    # 等待服务启动
    sleep 2
    
    # 检查服务状态
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}x-ui ${tag_version} 安装完成并正在运行！${plain}"
    else
        echo -e "${red}x-ui服务启动失败，请检查日志${plain}"
        systemctl status x-ui
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐"
    echo -e "│ ${blue}x-ui 控制菜单使用方法:${plain}                                    │"
    echo -e "│                                                       │"
    echo -e "│ ${blue}x-ui${plain}              - 管理脚本                            │"
    echo -e "│ ${blue}x-ui start${plain}        - 启动服务                            │"
    echo -e "│ ${blue}x-ui stop${plain}         - 停止服务                            │"
    echo -e "│ ${blue}x-ui restart${plain}      - 重启服务                            │"
    echo -e "│ ${blue}x-ui status${plain}       - 查看状态                            │"
    echo -e "│ ${blue}x-ui settings${plain}     - 查看设置                            │"
    echo -e "│ ${blue}x-ui enable${plain}       - 启用开机自启                        │"
    echo -e "│ ${blue}x-ui disable${plain}      - 禁用开机自启                        │"
    echo -e "│ ${blue}x-ui log${plain}          - 查看日志                            │"
    echo -e "│ ${blue}x-ui banlog${plain}       - 查看封禁日志                        │"
    echo -e "│ ${blue}x-ui update${plain}       - 更新                                │"
    echo -e "│ ${blue}x-ui install${plain}      - 安装                                │"
    echo -e "│ ${blue}x-ui uninstall${plain}    - 卸载                                │"
    echo -e "└───────────────────────────────────────────────────────┘"
}

# 主函数
main() {
    echo -e "${green}开始安装x-ui...${plain}"
    
    # 检查系统
    check_os
    echo -e "${blue}系统架构: $(get_arch)${plain}"
    
    # 检查GLIBC
    check_glibc
    
    # 安装依赖
    install_dependencies
    
    # 安装x-ui
    install_xui "$@"
    
    # 配置设置
    configure_after_install
    
    # 显示使用说明
    show_usage
}

# 执行主函数
main "$@"
