#!/bin/bash

# 版本更新脚本
# 使用方法: ./update-version.sh 3.1.2

if [ $# -eq 0 ]; then
    echo "错误: 请提供版本号"
    echo "使用方法: ./update-version.sh 3.1.2"
    exit 1
fi

NEW_VERSION="$1"

# 验证版本号格式
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误: 版本号格式不正确，应为 x.y.z 格式"
    exit 1
fi

echo "开始更新版本号到 v${NEW_VERSION}..."

# 获取当前日期
CURRENT_DATE=$(date +%Y-%m-%d)

# 更新 config/version
echo "${NEW_VERSION}" > config/version
echo "✓ 更新 config/version"

# 更新 install.sh
sed -i "s/last_version=\"v[0-9]\+\.[0-9]\+\.[0-9]\+\"/last_version=\"v${NEW_VERSION}\"/" install.sh
echo "✓ 更新 install.sh"

# 更新 README.md
sed -i "s/\*\*当前版本\*\*: v[0-9]\+\.[0-9]\+\.[0-9]\+/**当前版本**: v${NEW_VERSION}/" README.md
sed -i "s/\*\*更新日期\*\*: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/**更新日期**: ${CURRENT_DATE}/" README.md
echo "✓ 更新 README.md"

# 更新 README.en.md
sed -i "s/\*\*Current Version\*\*: v[0-9]\+\.[0-9]\+\.[0-9]\+/**Current Version**: v${NEW_VERSION}/" README.en.md
sed -i "s/\*\*Update Date\*\*: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/**Update Date**: ${CURRENT_DATE}/" README.en.md
echo "✓ 更新 README.en.md"

# 更新 BUILD.md
sed -i "s/版本：v[0-9]\+\.[0-9]\+\.[0-9]\+/版本：v${NEW_VERSION}/" BUILD.md
echo "✓ 更新 BUILD.md"

echo ""
echo "✅ 版本号已成功更新到 v${NEW_VERSION}"
echo ""
echo "接下来的步骤:"
echo "1. 在 README.md 中添加新版本的更新日志"
echo "2. 提交更改: git add . && git commit -m \"发布 v${NEW_VERSION}\""
echo "3. 创建标签: git tag -a v${NEW_VERSION} -m \"Release v${NEW_VERSION}\""
echo "4. 推送代码: git push origin main && git push origin v${NEW_VERSION}"
