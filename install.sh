#!/bin/bash

# 定义颜色变量
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Gitee仓库信息
GITEE_OWNER="YX-love"
GITEE_REPO="3x-ui"
GITEE_URL="https://gitee.com/${GITEE_OWNER}/${GITEE_REPO}"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 检查系统类型
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
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
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

# 获取Gitee最新版本
get_latest_version() {
    # 使用curl获取最新的release信息
    local result=$(curl -s "https://gitee.com/api/v5/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/latest")
    
    # 解析JSON获取tag_name
    local tag_name=$(echo "$result" | grep -o '"tag_name":"[^"]*' | sed 's/"tag_name":"//')
    
    # 如果tag_name为空，则使用手动设置的默认版本
    if [[ -z "$tag_name" ]]; then
        echo "v2.6.0"
    else
        echo "$tag_name"
    fi
}

# 从Gitee下载资源
download_from_gitee() {
    local version=$1
    local file_name="x-ui-linux-${arch}.tar.gz"
    local download_url="${GITEE_URL}/releases/download/${version}/${file_name}"
    
    echo "开始从Gitee下载 ${download_url}"
    wget -N --no-check-certificate -O "/usr/local/${file_name}" "${download_url}"
    
    if [[ $? -ne 0 ]]; then
        # 如果第一种链接格式失败，尝试另一种
        download_url="${GITEE_URL}/releases/v2.6.0/download/${file_name}"
        echo "尝试备用链接: ${download_url}"
        wget -N --no-check-certificate -O "/usr/local/${file_name}" "${download_url}"
        
        if [[ $? -ne 0 ]]; then
            # 如果还是失败，尝试直接下载release列表中的第一个附件
            echo "尝试直接下载release附件"
            release_id=$(curl -s "https://gitee.com/api/v5/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/latest" | grep -o '"id":[0-9]*' | head -1 | awk -F':' '{print $2}')
            
            if [[ -n "$release_id" ]]; then
                # 获取该release的所有附件
                assets=$(curl -s "https://gitee.com/api/v5/repos/${GITEE_OWNER}/${GITEE_REPO}/releases/${release_id}/assets")
                # 获取对应架构的附件下载链接
                download_url=$(echo "$assets" | grep -o "\"browser_download_url\":\"[^\"]*${arch}[^\"]*\"" | head -1 | awk -F'"' '{print $4}')
                
                if [[ -n "$download_url" ]]; then
                    echo "使用API获取的下载链接: ${download_url}"
                    wget -N --no-check-certificate -O "/usr/local/${file_name}" "${download_url}"
                    
                    if [[ $? -ne 0 ]]; then
                        echo -e "${red}下载 x-ui 失败，请手动上传 ${file_name} 到 /usr/local/ 目录下${plain}"
                        return 1
                    fi
                else
                    echo -e "${red}未找到适合 ${arch} 架构的下载链接${plain}"
                    return 1
                fi
            else
                echo -e "${red}未找到最新的release ID${plain}"
                return 1
            fi
        fi
    fi
    
    return 0
}

# 安装x-ui面板
install_x_ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        # 获取最新版本号
        last_version=$(get_latest_version)
        echo -e "检测到 x-ui 最新版本：${last_version}，开始安装"
        
        # 下载最新版本
        download_from_gitee "${last_version}"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保服务器能够访问 Gitee${plain}"
            exit 1
        fi
    else
        # 安装指定版本
        last_version=$1
        echo -e "开始安装 x-ui v$1"
        download_from_gitee "${last_version}"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    # 删除旧目录并解压
    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    
    # 下载管理脚本
    wget --no-check-certificate -O /usr/bin/x-ui "${GITEE_URL}/raw/master/x-ui.sh"
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    
    # 安装后配置
    config_after_install
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    echo -e "${green}x-ui v${last_version}${plain} 安装完成，面板已启动，"
    echo -e ""
    echo -e "x-ui 管理脚本使用方法: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - 显示管理菜单 (功能更多)"
    echo -e "x-ui start        - 启动 x-ui 面板"
    echo -e "x-ui stop         - 停止 x-ui 面板"
    echo -e "x-ui restart      - 重启 x-ui 面板"
    echo -e "x-ui status       - 查看 x-ui 状态"
    echo -e "x-ui enable       - 设置 x-ui 开机自启"
    echo -e "x-ui disable      - 取消 x-ui 开机自启"
    echo -e "x-ui log          - 查看 x-ui 日志"
    echo -e "x-ui v2-ui        - 迁移本机器的 v2-ui 账号数据至 x-ui"
    echo -e "x-ui update       - 更新 x-ui 面板"
    echo -e "x-ui install      - 安装 x-ui 面板"
    echo -e "x-ui uninstall    - 卸载 x-ui 面板"
    echo -e "----------------------------------------------"
}

# 安装后配置
config_after_install() {
    echo -e "${yellow}正在进行安装后配置...${plain}"
    
    # 设置中文为默认语言
    sed -i 's/"English"/"中文"/g' /usr/local/x-ui/config.json
    
    echo -e "${green}配置完成！${plain}"
}

# 执行安装
install_base
install_x_ui $1