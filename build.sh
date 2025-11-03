#!/bin/bash

# 3x-ui 多架构构建脚本
# 用于构建所有平台的发行版

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Xray 版本
XRAY_VERSION="v25.6.8"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}3x-ui 安全增强版 - 多架构构建脚本${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 清理旧文件
clean_old_files() {
    echo -e "${YELLOW}清理旧构建文件...${NC}"
    rm -rf x-ui x-ui-linux-*.tar.gz x-ui-windows-*.zip xui-release 2>/dev/null || true
    echo -e "${GREEN}✓ 清理完成${NC}"
    echo ""
}

# 下载 Xray 和 geo 文件
download_xray_and_geo() {
    local platform=$1
    local xray_file=""

    echo -e "${YELLOW}下载 Xray-core (${platform})...${NC}"

    case $platform in
        amd64)
            xray_file="Xray-linux-64.zip"
            ;;
        arm64)
            xray_file="Xray-linux-arm64-v8a.zip"
            ;;
        armv7)
            xray_file="Xray-linux-arm32-v7a.zip"
            ;;
        armv6)
            xray_file="Xray-linux-arm32-v6.zip"
            ;;
        armv5)
            xray_file="Xray-linux-arm32-v5.zip"
            ;;
        386)
            xray_file="Xray-linux-32.zip"
            ;;
        s390x)
            xray_file="Xray-linux-s390x.zip"
            ;;
        windows-amd64)
            xray_file="Xray-windows-64.zip"
            ;;
        *)
            echo -e "${RED}✗ 未知平台: $platform${NC}"
            return 1
            ;;
    esac

    # 下载 Xray
    wget -q ${XRAY_URL}${xray_file} || {
        echo -e "${RED}✗ 下载 Xray 失败${NC}"
        return 1
    }
    unzip -q ${xray_file}
    rm -f ${xray_file}

    # 下载 geo 文件（所有平台共用）
    echo -e "${YELLOW}下载 geo 数据库文件...${NC}"
    rm -f geoip.dat geosite.dat 2>/dev/null || true

    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
    wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
    wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat

    # 重命名 xray
    if [ "$platform" == "windows-amd64" ]; then
        mv xray.exe xray-windows-amd64.exe
    else
        mv xray xray-linux-${platform}
    fi

    echo -e "${GREEN}✓ Xray 和 geo 文件下载完成${NC}"
}

# 构建 Linux 平台
build_linux() {
    local platform=$1
    local goarch=""
    local goarm=""
    local cc=""

    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}构建 Linux ${platform}...${NC}"
    echo -e "${GREEN}=========================================${NC}"

    # 设置编译参数
    case $platform in
        amd64)
            goarch="amd64"
            cc="gcc"
            ;;
        arm64)
            goarch="arm64"
            cc="aarch64-linux-gnu-gcc"
            ;;
        armv7)
            goarch="arm"
            goarm="7"
            cc="arm-linux-gnueabihf-gcc"
            ;;
        armv6)
            goarch="arm"
            goarm="6"
            cc="arm-linux-gnueabihf-gcc"
            ;;
        armv5)
            goarch="arm"
            goarm="5"
            cc="arm-linux-gnueabi-gcc"
            ;;
        386)
            goarch="386"
            cc="i686-linux-gnu-gcc"
            ;;
        s390x)
            goarch="s390x"
            cc="s390x-linux-gnu-gcc"
            ;;
        *)
            echo -e "${RED}✗ 未知平台${NC}"
            return 1
            ;;
    esac

    # 编译
    echo -e "${YELLOW}编译 x-ui...${NC}"
    export CGO_ENABLED=1
    export GOOS=linux
    export GOARCH=$goarch
    export CC=$cc
    if [ -n "$goarm" ]; then
        export GOARM=$goarm
    fi

    go build -ldflags "-w -s" -o xui-release -v main.go || {
        echo -e "${RED}✗ 编译失败${NC}"
        return 1
    }

    echo -e "${GREEN}✓ 编译完成${NC}"

    # 创建发布目录
    echo -e "${YELLOW}准备发布文件...${NC}"
    mkdir -p x-ui/bin

    cp xui-release x-ui/x-ui
    cp x-ui.service x-ui/
    cp x-ui.sh x-ui/

    # 进入 bin 目录下载依赖
    cd x-ui/bin
    download_xray_and_geo $platform
    cd ../..

    # 打包
    echo -e "${YELLOW}打包...${NC}"
    tar -zcf x-ui-linux-${platform}.tar.gz x-ui

    # 清理
    rm -rf x-ui xui-release

    echo -e "${GREEN}✓ x-ui-linux-${platform}.tar.gz 构建完成！${NC}"
    echo ""
}

# 构建 Windows 平台
build_windows() {
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}构建 Windows amd64...${NC}"
    echo -e "${GREEN}=========================================${NC}"

    # 编译
    echo -e "${YELLOW}编译 x-ui.exe...${NC}"
    export CGO_ENABLED=1
    export GOOS=windows
    export GOARCH=amd64
    export CC=x86_64-w64-mingw32-gcc

    go build -ldflags "-w -s" -o xui-release.exe -v main.go || {
        echo -e "${RED}✗ 编译失败${NC}"
        return 1
    }

    echo -e "${GREEN}✓ 编译完成${NC}"

    # 创建发布目录
    echo -e "${YELLOW}准备发布文件...${NC}"
    mkdir -p x-ui/bin

    cp xui-release.exe x-ui/x-ui.exe

    # 进入 bin 目录下载依赖
    cd x-ui/bin
    download_xray_and_geo windows-amd64
    cd ../..

    # 打包为 zip
    echo -e "${YELLOW}打包...${NC}"
    zip -q -r x-ui-windows-amd64.zip x-ui

    # 清理
    rm -rf x-ui xui-release.exe

    echo -e "${GREEN}✓ x-ui-windows-amd64.zip 构建完成！${NC}"
    echo ""
}

# 主函数
main() {
    # 检查 Go 是否安装
    if ! command -v go &> /dev/null; then
        echo -e "${RED}✗ Go 未安装，请先安装 Go${NC}"
        exit 1
    fi

    echo -e "${GREEN}Go 版本: $(go version)${NC}"
    echo ""

    # 清理
    clean_old_files

    # 构建所有 Linux 平台
    build_linux amd64
    build_linux arm64
    build_linux armv7
    build_linux armv6
    build_linux armv5
    build_linux 386
    build_linux s390x

    # 构建 Windows 平台
    build_windows

    # 显示结果
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}所有构建完成！${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo -e "${YELLOW}生成的文件：${NC}"
    ls -lh x-ui-*.tar.gz x-ui-*.zip 2>/dev/null || true
    echo ""
    echo -e "${GREEN}✓ 所有发行版已准备就绪！${NC}"
}

# 运行
main
