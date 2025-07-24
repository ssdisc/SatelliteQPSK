@echo off

rem claude_interactive.bat - 交互式选择Claude配置

:menu
cls
echo ============================================
echo           Claude CLI 配置选择器
echo ============================================
echo,
echo 当前配置:
if defined ANTHROPIC_AUTH_TOKEN (
    echo   API Key: %ANTHROPIC_AUTH_TOKEN:~0,8%...
) else (
    echo   API Key: 未设置
)
if defined ANTHROPIC_BASE_URL (
    echo   Base URL: %ANTHROPIC_BASE_URL%
) else (
    echo   Base URL: 默认 (Anthropic)
)
echo,
echo 请选择配置:
echo,
echo [1] Moonshot AI (月之暗面)
echo [2] AnyRouter 代理服务
echo [3] Anthropic 官方
echo [4] 查看所有可用配置文件
echo [5] 退出
echo,
set /p choice=请输入选择 (1-5):

if "%choice%"=="1" goto moonshot
if "%choice%"=="2" goto anyrouter
if "%choice%"=="3" goto anthropic
if "%choice%"=="4" goto listfiles
if "%choice%"=="5" goto exit
echo 无效选择，请重试...
pause
goto menu

:moonshot
echo,
echo 正在加载 Moonshot AI 配置...
set "config_file=%USERPROFILE%\.claude-env\moonshot.txt"
if not exist "%config_file%" (
    echo 错误: 配置文件不存在: %config_file%
    pause
    goto menu
)
goto loadconfig

:anyrouter
echo,
echo 正在加载 AnyRouter 配置...
set "config_file=%USERPROFILE%\.claude-env\anyrouter.txt"
if not exist "%config_file%" (
    echo 错误: 配置文件不存在: %config_file%
    pause
    goto menu
)
goto loadconfig

:anthropic
echo,
echo 正在加载 Anthropic 官方配置...
set ANTHROPIC_AUTH_TOKEN=your_anthropic_AUTH_TOKEN_here
set ANTHROPIC_BASE_URL=
set DESCRIPTION=Anthropic Official
echo [注意] 请确保设置了真实的 Anthropic API Key
goto startclaude

:listfiles
echo,
echo 可用的配置文件:
dir /b *.txt 2>nul | findstr /E ".txt"
echo,
echo .claude-env 目录中的文件:
if exist "%USERPROFILE%\.claude-env" (
    dir /b "%USERPROFILE%\.claude-env\.env.*" 2>nul
) else (
    echo 目录不存在
)
echo,
pause
goto menu

:loadconfig
rem 清空变量
set ANTHROPIC_AUTH_TOKEN=
set ANTHROPIC_BASE_URL=
set DESCRIPTION=

rem 读取配置文件
for /f "usebackq tokens=1,* delims==" %%a in ("%config_file%") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        if "%%a"=="ANTHROPIC_AUTH_TOKEN" set ANTHROPIC_AUTH_TOKEN=%%b
        if "%%a"=="ANTHROPIC_BASE_URL" set ANTHROPIC_BASE_URL=%%b
        if "%%a"=="DESCRIPTION" set DESCRIPTION=%%b
    )
)

echo [成功] 配置已加载:
echo   提供商: %DESCRIPTION%
echo   API Key: %ANTHROPIC_AUTH_TOKEN:~0,8%...
echo   Base URL: %ANTHROPIC_BASE_URL%

:startclaude
echo,
echo 即将启动 Claude CLI...
echo,
rem set /p confirm=确认启动吗? (y/n):
rem if not "%confirm%"=="y" if not "%confirm%"=="Y" goto menu

echo,
echo 启动中...
claude
goto end

:exit
echo 退出程序
goto end

:end
echo,
pause
