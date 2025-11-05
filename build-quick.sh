#!/bin/bash

# yun 快速构建脚本
# 用于快速构建当前平台的发行版

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 从 config/version 读取版本号
VERSION=$(cat config/version | tr -d '\n')
XRAY_VERSION="v25.6.8"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}yun v${VERSION} - 快速构建脚本${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 检测当前平台
detect_platform() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        armv6l)
            echo "armv6"
            ;;
        i386|i686)
            echo "386"
            ;;
        *)
            echo -e "${RED}✗ 不支持的架构: $arch${NC}"
            exit 1
            ;;
    esac
}

PLATFORM=$(detect_platform)
echo -e "${YELLOW}检测到平台: ${PLATFORM}${NC}"
echo ""

# 清理旧文件
echo -e "${YELLOW}清理旧文件...${NC}"
rm -rf yun yun-linux-${PLATFORM}.tar.gz yun-release 2>/dev/null || true
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

# 编译
echo -e "${YELLOW}编译 yun...${NC}"
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=${PLATFORM}

case $PLATFORM in
    arm64)
        export CC=aarch64-linux-gnu-gcc
        ;;
    armv7)
        export GOARCH=arm
        export GOARM=7
        export CC=arm-linux-gnueabihf-gcc
        ;;
    armv6)
        export GOARCH=arm
        export GOARM=6
        export CC=arm-linux-gnueabihf-gcc
        ;;
    386)
        export CC=i686-linux-gnu-gcc
        ;;
esac

go build -ldflags "-w -s" -o yun-release -v main.go || {
    echo -e "${RED}✗ 编译失败${NC}"
    exit 1
}

echo -e "${GREEN}✓ 编译完成${NC}"
echo ""

# 创建发布目录
echo -e "${YELLOW}准备发布文件...${NC}"
mkdir -p yun/bin

cp yun-release yun/yun
cp yun.service yun/
cp yun.sh yun/

# 下载 Xray 和 geo 文件
echo -e "${YELLOW}下载 Xray 和 geo 数据库...${NC}"
cd yun/bin

# 下载 Xray
case $PLATFORM in
    amd64)
        XRAY_FILE="Xray-linux-64.zip"
        ;;
    arm64)
        XRAY_FILE="Xray-linux-arm64-v8a.zip"
        ;;
    armv7)
        XRAY_FILE="Xray-linux-arm32-v7a.zip"
        ;;
    armv6)
        XRAY_FILE="Xray-linux-arm32-v6.zip"
        ;;
    386)
        XRAY_FILE="Xray-linux-32.zip"
        ;;
esac

wget -q "${XRAY_URL}${XRAY_FILE}" && unzip -q "${XRAY_FILE}" && rm -f "${XRAY_FILE}"

# 下载 geo 文件
rm -f geoip.dat geosite.dat 2>/dev/null || true
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat

mv xray xray-linux-${PLATFORM}
cd ../..

echo -e "${GREEN}✓ 依赖下载完成${NC}"
echo ""

# 打包
echo -e "${YELLOW}打包为 tar.gz...${NC}"
tar -zcf yun-linux-${PLATFORM}.tar.gz yun

# 清理
rm -rf yun yun-release

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ 构建完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${YELLOW}生成的文件：${NC}"
ls -lh yun-linux-${PLATFORM}.tar.gz
echo ""
echo -e "${GREEN}版本: v${VERSION}${NC}"
echo -e "${GREEN}平台: linux-${PLATFORM}${NC}"
echo ""
