#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# 国内镜像源配置
GITEE_REPO="https://gitee.com/YX-love/3x-ui"
GITEE_RAW="https://gitee.com/YX-love/3x-ui/raw/master"
GITEE_RELEASES="https://gitee.com/YX-love/3x-ui/releases/download"

# 国内IP查询服务
IP_SERVICES=("ip.sb" "ipinfo.io/ip" "myip.ipip.net")

# 国内镜像源列表
MIRROR_SOURCES=(
    "https://mirrors.bfsu.edu.cn/github-release/Loyalsoldier/v2ray-rules-dat/LatestRelease"
    "https://ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download"
    "https://hub.fastgit.xyz/Loyalsoldier/v2ray-rules-dat/releases/latest/download"
    "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download"
)

#添加基础函数
function LOGD() {
    echo -e "${yellow}[调试] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[错误] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[信息] $* ${plain}"
}

# 检查root权限
[[ $EUID -ne 0 ]] && LOGE "错误: 您必须以root权限运行此脚本! \n" && exit 1

# 检查操作系统
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

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

# 声明变量
log_folder="${XUI_LOG_FOLDER:=/var/log}"
iplimit_log_path="${log_folder}/3xipl.log"
iplimit_banned_log_path="${log_folder}/3xipl-banned.log"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -rp "$1 [默认$2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -rp "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "重启面板，重启也会重启 xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo -e "${yellow}* 按任意键返回主菜单 *${plain}"
    read -rsp $'\n'
    show_menu
}

# 获取服务器IP地址（使用国内服务）
get_server_ip() {
    for service in "${IP_SERVICES[@]}"; do
        local ip=$(curl -s --connect-timeout 5 "$service" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi
    done
    echo "127.0.0.1"
}

install() {
    bash <(curl -Ls "${GITEE_RAW}/install-cn.sh")
    if [[ $? == 0 ]]; then
        LOGI "安装完成，面板已启动，"
        echo -e ""
        echo -e "x-ui 管理脚本使用方法: "
        echo -e "----------------------------------------------"
        echo -e "x-ui              - 显示管理菜单 (功能更多)"
        echo -e "x-ui start        - 启动 x-ui 面板"
        echo -e "x-ui stop         - 停止 x-ui 面板"
        echo -e "x-ui restart      - 重启 x-ui 面板"
        echo -e "x-ui status       - 查看 x-ui 状态"
        echo -e "x-ui enable       - 设置开机自启"
        echo -e "x-ui disable      - 取消开机自启"
        echo -e "x-ui log          - 查看 x-ui 日志"
        echo -e "x-ui update       - 更新 x-ui 面板"
        echo -e "x-ui install      - 安装 x-ui 面板"
        echo -e "x-ui uninstall    - 卸载 x-ui 面板"
        echo -e "----------------------------------------------"
    else
        LOGE "安装失败，大概是因为无法连接到网络"
    fi
}

update() {
    confirm "确定要更新面板吗，更新也会重启 xray" "n"
    if [[ $? != 0 ]]; then
        LOGE "已取消"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls "${GITEE_RAW}/install-cn.sh")
    if [[ $? == 0 ]]; then
        LOGI "更新完成，面板已自动重启 "
        exit 0
    fi
}

update_menu() {
    echo -e "${yellow}更新管理脚本${plain}"
    confirm "此功能会将管理脚本更新到最新版本。" "y"
    if [[ $? != 0 ]]; then
        LOGE "已取消"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi

    wget -O /usr/bin/x-ui "${GITEE_RAW}/x-ui-cn.sh"
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui

    if [[ $? == 0 ]]; then
        echo -e "${green}更新成功，面板已自动重启。${plain}"
        exit 0
    else
        echo -e "${red}管理脚本更新失败。${plain}"
        return 1
    fi
}

# 处理脚本文件删除
delete_script() {
    rm "$0"
    exit 1
}

uninstall() {
    confirm "确定要卸载面板吗，xray 也会卸载?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "卸载成功。\n"
    echo "如果需要再次安装此面板，可以使用下面的命令:"
    echo -e "${green}bash <(curl -Ls ${GITEE_RAW}/install-cn.sh)${plain}"
    echo ""
    # 捕获 SIGTERM 信号
    trap delete_script SIGTERM
    delete_script
}

reset_user() {
    confirm "确定要重置面板的用户名和密码吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    read -rp "请设置登录用户名 [默认为随机用户名]: " config_account
    [[ -z $config_account ]] && config_account=$(date +%s%N | md5sum | cut -c 1-8)
    read -rp "请设置登录密码 [默认为随机密码]: " config_password
    [[ -z $config_password ]] && config_password=$(date +%s%N | md5sum | cut -c 1-8)
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password} >/dev/null 2>&1
    echo -e "面板登录用户名已重置为: ${green} ${config_account} ${plain}"
    echo -e "面板登录密码已重置为: ${green} ${config_password} ${plain}"
    echo -e "${green} 请使用新的登录用户名和密码访问 X-UI 面板。记住这些信息！ ${plain}"
    confirm_restart
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

reset_webbasepath() {
    echo -e "${yellow}重置网页路径${plain}"

    read -rp "确定要重置网页路径吗? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${yellow}操作已取消。${plain}"
        return
    fi

    config_webBasePath=$(gen_random_string 10)

    # 应用新的网页路径设置
    /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}" >/dev/null 2>&1

    echo -e "网页路径已重置为: ${green}${config_webBasePath}${plain}"
    echo -e "${green}请使用新的网页路径访问面板。${plain}"
    restart
}

reset_config() {
    confirm "确定要重置所有面板设置吗，账户数据不会丢失，用户名和密码不会改变" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "所有面板设置已重置为默认值。"
    restart
}

check_config() {
    local info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "获取当前设置时出错，请检查日志"
        show_menu
        return
    fi
    LOGI "${info}"

    local existing_webBasePath=$(echo "$info" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(echo "$info" | grep -Eo 'port: .+' | awk '{print $2}')
    local existing_cert=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'cert: .+' | awk '{print $2}')
    local server_ip=$(get_server_ip)

    if [[ -n "$existing_cert" ]]; then
        local domain=$(basename "$(dirname "$existing_cert")")

        if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "${green}访问地址: https://${domain}:${existing_port}${existing_webBasePath}${plain}"
        else
            echo -e "${green}访问地址: https://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
        fi
    else
        echo -e "${green}访问地址: http://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
    fi
}

set_port() {
    echo -n "输入端口号[1-65535]: "
    read -r port
    if [[ -z "${port}" ]]; then
        LOGD "已取消"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "端口设置完毕，现在请重启面板，并使用新端口 ${green}${port}${plain} 访问网页面板"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "面板已运行，无需再次启动，如需重启请选择重启"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "x-ui 启动成功"
        else
            LOGE "面板启动失败，可能是因为启动时间超过了两秒，请稍后查看日志信息"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "面板已停止，无需再次停止!"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "x-ui 与 xray 停止成功"
        else
            LOGE "面板停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "x-ui 与 xray 重启成功"
    else
        LOGE "面板重启失败，可能是因为启动时间超过了两秒，请稍后查看日志信息"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui 设置开机自启成功"
    else
        LOGE "x-ui 设置开机自启失败"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui 取消开机自启成功"
    else
        LOGE "x-ui 取消开机自启失败"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "${green}\t1.${plain} 调试日志"
    echo -e "${green}\t2.${plain} 清空所有日志"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -rp "请选择: " choice

    case "$choice" in
    0)
        show_menu
        ;;
    1)
        journalctl -u x-ui -e --no-pager -f -p debug
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        ;;
    2)
        sudo journalctl --rotate
        sudo journalctl --vacuum-time=1s
        echo "所有日志已清空。"
        restart
        ;;
    *)
        echo -e "${red}无效选项。请选择有效数字。${plain}\n"
        show_log
        ;;
    esac
}

show_banlog() {
    local system_log="/var/log/fail2ban.log"

    echo -e "${green}检查封禁日志...${plain}\n"

    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${red}Fail2ban 服务未运行!${plain}\n"
        return 1
    fi

    if [[ -f "$system_log" ]]; then
        echo -e "${green}来自 fail2ban.log 的近期系统封禁活动:${plain}"
        grep "3x-ipl" "$system_log" | grep -E "Ban|Unban" | tail -n 10 || echo -e "${yellow}未找到近期系统封禁活动${plain}"
        echo ""
    fi

    if [[ -f "${iplimit_banned_log_path}" ]]; then
        echo -e "${green}3X-IPL 封禁日志条目:${plain}"
        if [[ -s "${iplimit_banned_log_path}" ]]; then
            grep -v "INIT" "${iplimit_banned_log_path}" | tail -n 10 || echo -e "${yellow}未找到封禁条目${plain}"
        else
            echo -e "${yellow}封禁日志文件为空${plain}"
        fi
    else
        echo -e "${red}封禁日志文件未找到: ${iplimit_banned_log_path}${plain}"
    fi

    echo -e "\n${green}当前监狱状态:${plain}"
    fail2ban-client status 3x-ipl || echo -e "${yellow}无法获取监狱状态${plain}"
}

update_geo() {
    echo -e "${green}正在更新地理位置数据库...${plain}"
    echo -e "${green}\t1.${plain} 更新标准版本 (推荐)"
    echo -e "${green}\t2.${plain} 更新伊朗版本"
    echo -e "${green}\t3.${plain} 更新俄罗斯版本"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -rp "请选择: " choice
    
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        update_standard_geo
        ;;
    2)
        update_iran_geo
        ;;
    3)
        update_russia_geo
        ;;
    *)
        echo -e "${red}无效选项。请选择有效数字。${plain}\n"
        update_geo
        ;;
    esac
}

update_standard_geo() {
    cd /usr/local/x-ui/bin
    
    echo -e "${green}正在下载标准版地理位置数据库...${plain}"
    
    # 尝试从不同镜像源下载
    for mirror in "${MIRROR_SOURCES[@]}"; do
        echo -e "${blue}尝试从镜像源下载: $mirror${plain}"
        
        if wget -q --timeout=10 -N "${mirror}/geoip.dat" && wget -q --timeout=10 -N "${mirror}/geosite.dat"; then
            echo -e "${green}成功从镜像源下载地理位置数据库${plain}"
            restart
            return 0
        else
            echo -e "${yellow}镜像源下载失败，尝试下一个...${plain}"
        fi
    done
    
    echo -e "${red}所有镜像源下载失败${plain}"
    before_show_menu
}

update_iran_geo() {
    cd /usr/local/x-ui/bin
    
    echo -e "${green}正在下载伊朗版地理位置数据库...${plain}"
    
    # 使用代理或镜像源
    if wget -O geoip_IR.dat -N "https://ghproxy.com/https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat" && 
       wget -O geosite_IR.dat -N "https://ghproxy.com/https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat"; then
        echo -e "${green}伊朗版地理位置数据库下载成功${plain}"
    else
        echo -e "${red}伊朗版地理位置数据库下载失败${plain}"
    fi
    
    before_show_menu
}

update_russia_geo() {
    cd /usr/local/x-ui/bin
    
    echo -e "${green}正在下载俄罗斯版地理位置数据库...${plain}"
    
    # 使用代理或镜像源
    if wget -O geoip_RU.dat -N "https://ghproxy.com/https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat" && 
       wget -O geosite_RU.dat -N "https://ghproxy.com/https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat"; then
        echo -e "${green}俄罗斯版地理位置数据库下载成功${plain}"
    else
        echo -e "${red}俄罗斯版地理位置数据库下载失败${plain}"
    fi
    
    before_show_menu
}

bbr_menu() {
    echo -e "${green}\t1.${plain} 启用 BBR"
    echo -e "${green}\t2.${plain} 禁用 BBR"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -rp "请选择: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        enable_bbr
        bbr_menu
        ;;
    2)
        disable_bbr
        bbr_menu
        ;;
    *)
        echo -e "${red}无效选项。请选择有效数字。${plain}\n"
        bbr_menu
        ;;
    esac
}

disable_bbr() {
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${yellow}BBR 当前未启用。${plain}"
        before_show_menu
    fi

    # 将 BBR 替换为 CUBIC 配置
    sed -i 's/net.core.default_qdisc=fq/net.core.default_qdisc=pfifo_fast/' /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=bbr/net.ipv4.tcp_congestion_control=cubic/' /etc/sysctl.conf

    # 应用更改
    sysctl -p

    # 验证 BBR 已被 CUBIC 替换
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}BBR 已成功替换为 CUBIC。${plain}"
    else
        echo -e "${red}BBR 替换为 CUBIC 失败。请检查系统配置。${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${green}BBR 已经启用!${plain}"
        before_show_menu
    fi

    # 检查操作系统并安装必要包
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    *)
        echo -e "${red}不支持的操作系统。请检查脚本并手动安装必要的包。${plain}\n"
        exit 1
        ;;
    esac

    # 启用 BBR
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf

    # 应用更改
    sysctl -p

    # 验证 BBR 已启用
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR 已成功启用。${plain}"
    else
        echo -e "${red}BBR 启用失败。请检查系统配置。${plain}"
    fi
}

check_status() {
    local temp=$(systemctl is-active x-ui)
    if [[ "${temp}" == "active" ]]; then
        return 0
    else
        return 1
    fi
}

show_usage() {
    echo "x-ui 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "x-ui              - 显示管理菜单 (功能更多)"
    echo "x-ui start        - 启动 x-ui 面板"
    echo "x-ui stop         - 停止 x-ui 面板"
    echo "x-ui restart      - 重启 x-ui 面板"
    echo "x-ui status       - 查看 x-ui 状态"
    echo "x-ui enable       - 设置开机自启"
    echo "x-ui disable      - 取消开机自启"
    echo "x-ui log          - 查看 x-ui 日志"
    echo "x-ui banlog       - 查看 Fail2ban 封禁日志"
    echo "x-ui update       - 更新 x-ui 面板"
    echo "x-ui install      - 安装 x-ui 面板"
    echo "x-ui uninstall    - 卸载 x-ui 面板"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}3X-UI 面板管理脚本${plain} ${red}[国内优化版]${plain}
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} 安装 x-ui
  ${green}2.${plain} 更新 x-ui
  ${green}3.${plain} 更新管理脚本
  ${green}4.${plain} 卸载 x-ui
————————————————
  ${green}5.${plain} 重置用户名密码
  ${green}6.${plain} 重置面板设置
  ${green}7.${plain} 设置面板端口
  ${green}8.${plain} 查看当前面板设置
————————————————
  ${green}9.${plain} 启动 x-ui
  ${green}10.${plain} 停止 x-ui
  ${green}11.${plain} 重启 x-ui
  ${green}12.${plain} 查看 x-ui 状态
  ${green}13.${plain} 查看 x-ui 日志
————————————————
  ${green}14.${plain} 设置开机自启
  ${green}15.${plain} 取消开机自启
————————————————
  ${green}16.${plain} 一键安装 bbr (最新内核)
  ${green}17.${plain} 查看封禁日志
  ${green}18.${plain} 更新地理位置数据库
————————————————
  ${green}19.${plain} 重置网页路径
————————————————
"
    echo && read -rp "请输入选择 [0-19]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        install
        ;;
    2)
        update
        ;;
    3)
        update_menu
        ;;
    4)
        uninstall
        ;;
    5)
        reset_user
        ;;
    6)
        reset_config
        ;;
    7)
        set_port
        ;;
    8)
        check_config
        ;;
    9)
        start
        ;;
    10)
        stop
        ;;
    11)
        restart
        ;;
    12)
        status
        ;;
    13)
        show_log
        ;;
    14)
        enable
        ;;
    15)
        disable
        ;;
    16)
        bbr_menu
        ;;
    17)
        show_banlog
        ;;
    18)
        update_geo
        ;;
    19)
        reset_webbasepath
        ;;
    *)
        LOGE "请输入正确的数字 [0-19]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        start 0
        ;;
    "stop")
        stop 0
        ;;
    "restart")
        restart 0
        ;;
    "status")
        status 0
        ;;
    "enable")
        enable 0
        ;;
    "disable")
        disable 0
        ;;
    "log")
        show_log 0
        ;;
    "banlog")
        show_banlog 0
        ;;
    "update")
        update 0
        ;;
    "install")
        install 0
        ;;
    "uninstall")
        uninstall 0
        ;;
    *)
        show_usage
        ;;
    esac
else
    show_menu
fi
