@echo off
REM 版本更新脚本 (Windows)
REM 使用方法: update-version.bat 3.1.2

if "%~1"=="" (
    echo 错误: 请提供版本号
    echo 使用方法: update-version.bat 3.1.2
    exit /b 1
)

set NEW_VERSION=%~1

echo 开始更新版本号到 v%NEW_VERSION%...

REM 获取当前日期 (格式: YYYY-MM-DD)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set CURRENT_DATE=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%

REM 更新 config/version
echo %NEW_VERSION%> config\version
echo √ 更新 config\version

REM 提示用户手动更新其他文件
echo.
echo √ config\version 已更新
echo.
echo 请手动更新以下文件中的版本号:
echo 1. install.sh - last_version="v%NEW_VERSION%"
echo 2. README.md - **当前版本**: v%NEW_VERSION% 和 **更新日期**: %CURRENT_DATE%
echo 3. README.en.md - **Current Version**: v%NEW_VERSION% 和 **Update Date**: %CURRENT_DATE%
echo 4. BUILD.md - 版本：v%NEW_VERSION%
echo 5. README.md - 添加新版本的更新日志
echo.
echo 或者使用 Git Bash 运行: bash update-version.sh %NEW_VERSION%
echo.
echo 更新完成后执行:
echo 1. git add .
echo 2. git commit -m "发布 v%NEW_VERSION%"
echo 3. git tag -a v%NEW_VERSION% -m "Release v%NEW_VERSION%"
echo 4. git push origin main ^&^& git push origin v%NEW_VERSION%

pause
