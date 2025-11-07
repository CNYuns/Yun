#!/bin/bash

# 定义颜色变量
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

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

# 检查系统版本
if [ -f /etc/os-release ]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

# 确认提示函数
confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

# 重启面板确认
confirm_restart() {
    confirm "是否重启面板" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

# 返回主菜单
before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

# 安装面板
install() {
    bash <(curl -Ls https://gitee.com/cnyuns/yun/raw/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

# 更新面板
update() {
    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}已取消${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://gitee.com/cnyuns/yun/raw/main/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成，已自动重启面板${plain}"
        exit 0
    fi
}

# 卸载面板
uninstall() {
    confirm "确定要卸载面板吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop yun
    systemctl disable yun
    rm /etc/systemd/system/yun.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/yun/ -rf
    rm /usr/local/yun/ -rf
    rm /usr/bin/yun -f
    echo -e "${green}卸载成功${plain}"
}

# 重置用户名和密码
reset_user() {
    confirm "确定要将用户名和密码重置为 admin 吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/yun/yun setting -username admin -password admin
    echo -e "${green}用户名和密码已重置为 ${yellow}admin${green}，现在请重启面板${plain}"
    confirm_restart
}

# 重置面板设置
reset_config() {
    confirm "确定要重置所有面板设置吗，账号数据不会丢失，用户名和密码不会改变" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/yun/yun setting -reset
    echo -e "${green}所有面板设置已重置为默认值，现在请重启面板，并使用默认的 ${yellow}54321${green} 端口访问面板${plain}"
    confirm_restart
}

# 显示当前设置
check_config() {
    info=$(/usr/local/yun/yun setting -show)
    if [[ $? != 0 ]]; then
        echo -e "${red}获取当前设置失败，可能是因为存在错误，请备份 /etc/yun/yun.db 文件后卸载并重新安装面板${plain}"
        exit 1
    fi
    echo -e "${info}"
}

# 设置面板端口
set_port() {
    echo && echo -n -e "输入端口号[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu
    else
        /usr/local/yun/yun setting -port ${port}
        echo -e "${green}设置端口完毕，现在请重启面板${plain}"
        confirm_restart
    fi
}

# 启动面板
start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}面板已运行，无需再次启动，如需重启请选择重启${plain}"
    else
        systemctl start yun
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}yun 启动成功${plain}"
        else
            echo -e "${red}面板启动失败，可能是因为启动时间超过了两秒，请稍后查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 停止面板
stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}面板已停止，无需再次停止${plain}"
    else
        systemctl stop yun
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}yun 与 xray 停止成功${plain}"
        else
            echo -e "${red}面板停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 重启面板
restart() {
    systemctl restart yun
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}yun 与 xray 重启成功${plain}"
    else
        echo -e "${red}面板重启失败，可能是因为启动时间超过了两秒，请稍后查看日志信息${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 查看面板状态
status() {
    systemctl status yun -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 设置开机自启
enable() {
    systemctl enable yun
    if [[ $? == 0 ]]; then
        echo -e "${green}yun 设置开机自启成功${plain}"
    else
        echo -e "${red}yun 设置开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 取消开机自启
disable() {
    systemctl disable yun
    if [[ $? == 0 ]]; then
        echo -e "${green}yun 取消开机自启成功${plain}"
    else
        echo -e "${red}yun 取消开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 查看面板日志
show_log() {
    journalctl -u yun.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 迁移v2-ui数据
migrate_v2_ui() {
    /usr/local/yun/yun v2-ui

    before_show_menu
}

# 安装BBR
install_bbr() {
    # 优先使用国内镜像
    echo -e "${green}开始安装 BBR...${plain}"
    bash <(curl -Ls https://ghproxy.com/https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo -e "${green}BBR 安装完成！${plain}"
}

# 更新管理脚本
update_shell() {
    wget -O /usr/bin/yun -N --no-check-certificate https://gitee.com/cnyuns/yun/raw/main/yun.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}下载脚本失败，请检查本机能否连接 Gitee${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/yun
        echo -e "${green}升级脚本成功，请重新运行脚本${plain}" && exit 0
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

# 检查是否开机自启
check_enabled() {
    temp=$(systemctl is-enabled yun)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

# 检查是否已安装
check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}面板已安装，请不要重复安装${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

# 检查是否已安装
check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}请先安装面板${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

# 显示状态
show_status() {
    check_status
    case $? in
        0)
            echo -e "面板状态: ${green}已运行${plain}"
            show_enable_status
            ;;
        1)
            echo -e "面板状态: ${yellow}未运行${plain}"
            show_enable_status
            ;;
        2)
            echo -e "面板状态: ${red}未安装${plain}"
    esac
    show_xray_status
}

# 显示开机自启状态
show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${green}是${plain}"
    else
        echo -e "是否开机自启: ${red}否${plain}"
    fi
}

# 检查xray状态
check_xray_status() {
    local count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ $count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 显示xray状态
show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray 状态: ${green}运行中${plain}"
    else
        echo -e "xray 状态: ${red}未运行${plain}"
    fi
}

# 显示使用帮助
show_usage() {
    echo "yun 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "yun              - 显示管理菜单 (功能更多)"
    echo "yun start        - 启动 yun 面板"
    echo "yun stop         - 停止 yun 面板"
    echo "yun restart      - 重启 yun 面板"
    echo "yun status       - 查看 yun 状态"
    echo "yun enable       - 设置 yun 开机自启"
    echo "yun disable      - 取消 yun 开机自启"
    echo "yun log          - 查看 yun 日志"
    echo "yun v2-ui        - 迁移本机器的 v2-ui 账号数据至 yun"
    echo "yun update       - 更新 yun 面板"
    echo "yun install      - 安装 yun 面板"
    echo "yun uninstall    - 卸载 yun 面板"
    echo "------------------------------------------"
}

# 显示菜单
show_menu() {
    echo -e "
  ${green}yun 面板管理脚本${plain}
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} 安装 yun
  ${green}2.${plain} 更新 yun
  ${green}3.${plain} 卸载 yun
————————————————
  ${green}4.${plain} 重置用户名密码
  ${green}5.${plain} 重置面板设置
  ${green}6.${plain} 设置面板端口
  ${green}7.${plain} 查看当前面板设置
————————————————
  ${green}8.${plain} 启动 yun
  ${green}9.${plain} 停止 yun
  ${green}10.${plain} 重启 yun
  ${green}11.${plain} 查看 yun 状态
  ${green}12.${plain} 查看 yun 日志
————————————————
  ${green}13.${plain} 设置 yun 开机自启
  ${green}14.${plain} 取消 yun 开机自启
————————————————
  ${green}15.${plain} 一键安装 bbr (最新内核)
  ${green}16.${plain} 迁移 v2-ui 账号数据
 "
    show_status
    echo && read -p "请输入选择 [0-16]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && check_config
        ;;
        8) check_install && start
        ;;
        9) check_install && stop
        ;;
        10) check_install && restart
        ;;
        11) check_install && status
        ;;
        12) check_install && show_log
        ;;
        13) check_install && enable
        ;;
        14) check_install && disable
        ;;
        15) install_bbr
        ;;
        16) check_install && migrate_v2_ui
        ;;
        *) echo -e "${red}请输入正确的数字 [0-16]${plain}"
        ;;
    esac
}

# 处理命令行参数
if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "v2-ui") check_install 0 && migrate_v2_ui 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
