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
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

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

# 其余代码保持不变...

# 更新脚本部分的修改
update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate "${GITEE_URL}/raw/master/x-ui.sh"
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}下载脚本失败，请检查本机能否连接 Gitee${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        echo -e "${green}升级脚本成功，请重新运行脚本${plain}" && exit 0
    fi
}

# 安装部分的修改
install() {
    bash <(curl -Ls "${GITEE_URL}/raw/master/install.sh")
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

# 更新部分的修改
update() {
    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}已取消${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls "${GITEE_URL}/raw/master/install.sh")
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成，已自动重启面板${plain}"
        exit 0
    fi
}

# 其余代码保持不变...