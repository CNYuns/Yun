#!/bin/sh
case $1 in
    amd64)
        ARCH="64"
        FNAME="amd64"
        ;;
    i386)
        ARCH="32"
        FNAME="i386"
        ;;
    armv8 | arm64 | aarch64)
        ARCH="arm64-v8a"
        FNAME="arm64"
        ;;
    armv7 | arm | arm32)
        ARCH="arm32-v7a"
        FNAME="arm32"
        ;;
    armv6)
        ARCH="arm32-v6"
        FNAME="armv6"
        ;;
    *)
        ARCH="64"
        FNAME="amd64"
        ;;
esac
mkdir -p build/bin
cd build/bin
wget -q "https://gitee.com/YX-love/3x-ui/releases/download/v25.6.8/Xray-linux-${ARCH}.zip"
unzip "Xray-linux-${ARCH}.zip"
rm -f "Xray-linux-${ARCH}.zip" geoip.dat geosite.dat
mv xray "xray-linux-${FNAME}"
wget -q https://gitee.com/YX-love/3x-ui/raw/main/geoip.dat
wget -q https://gitee.com/YX-love/3x-ui/raw/main/geosite.dat
wget -q -O geoip_IR.dat https://gitee.com/YX-love/3x-ui/raw/main/geoip_IR.dat
wget -q -O geosite_IR.dat https://gitee.com/YX-love/3x-ui/raw/main/geosite_IR.dat
wget -q -O geoip_RU.dat https://gitee.com/YX-love/3x-ui/raw/main/geoip_RU.dat
wget -q -O geosite_RU.dat https://gitee.com/YX-love/3x-ui/raw/main/geosite_RU.dat
cd ../../
