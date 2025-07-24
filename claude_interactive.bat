@echo off

rem claude_interactive.bat - ����ʽѡ��Claude����

:menu
cls
echo ============================================
echo           Claude CLI ����ѡ����
echo ============================================
echo,
echo ��ǰ����:
if defined ANTHROPIC_AUTH_TOKEN (
    echo   API Key: %ANTHROPIC_AUTH_TOKEN:~0,8%...
) else (
    echo   API Key: δ����
)
if defined ANTHROPIC_BASE_URL (
    echo   Base URL: %ANTHROPIC_BASE_URL%
) else (
    echo   Base URL: Ĭ�� (Anthropic)
)
echo,
echo ��ѡ������:
echo,
echo [1] Moonshot AI (��֮����)
echo [2] AnyRouter �������
echo [3] Anthropic �ٷ�
echo [4] �鿴���п��������ļ�
echo [5] �˳�
echo,
set /p choice=������ѡ�� (1-5):

if "%choice%"=="1" goto moonshot
if "%choice%"=="2" goto anyrouter
if "%choice%"=="3" goto anthropic
if "%choice%"=="4" goto listfiles
if "%choice%"=="5" goto exit
echo ��Чѡ��������...
pause
goto menu

:moonshot
echo,
echo ���ڼ��� Moonshot AI ����...
set "config_file=%USERPROFILE%\.claude-env\moonshot.txt"
if not exist "%config_file%" (
    echo ����: �����ļ�������: %config_file%
    pause
    goto menu
)
goto loadconfig

:anyrouter
echo,
echo ���ڼ��� AnyRouter ����...
set "config_file=%USERPROFILE%\.claude-env\anyrouter.txt"
if not exist "%config_file%" (
    echo ����: �����ļ�������: %config_file%
    pause
    goto menu
)
goto loadconfig

:anthropic
echo,
echo ���ڼ��� Anthropic �ٷ�����...
set ANTHROPIC_AUTH_TOKEN=your_anthropic_AUTH_TOKEN_here
set ANTHROPIC_BASE_URL=
set DESCRIPTION=Anthropic Official
echo [ע��] ��ȷ����������ʵ�� Anthropic API Key
goto startclaude

:listfiles
echo,
echo ���õ������ļ�:
dir /b *.txt 2>nul | findstr /E ".txt"
echo,
echo .claude-env Ŀ¼�е��ļ�:
if exist "%USERPROFILE%\.claude-env" (
    dir /b "%USERPROFILE%\.claude-env\.env.*" 2>nul
) else (
    echo Ŀ¼������
)
echo,
pause
goto menu

:loadconfig
rem ��ձ���
set ANTHROPIC_AUTH_TOKEN=
set ANTHROPIC_BASE_URL=
set DESCRIPTION=

rem ��ȡ�����ļ�
for /f "usebackq tokens=1,* delims==" %%a in ("%config_file%") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        if "%%a"=="ANTHROPIC_AUTH_TOKEN" set ANTHROPIC_AUTH_TOKEN=%%b
        if "%%a"=="ANTHROPIC_BASE_URL" set ANTHROPIC_BASE_URL=%%b
        if "%%a"=="DESCRIPTION" set DESCRIPTION=%%b
    )
)

echo [�ɹ�] �����Ѽ���:
echo   �ṩ��: %DESCRIPTION%
echo   API Key: %ANTHROPIC_AUTH_TOKEN:~0,8%...
echo   Base URL: %ANTHROPIC_BASE_URL%

:startclaude
echo,
echo �������� Claude CLI...
echo,
rem set /p confirm=ȷ��������? (y/n):
rem if not "%confirm%"=="y" if not "%confirm%"=="Y" goto menu

echo,
echo ������...
claude
goto end

:exit
echo �˳�����
goto end

:end
echo,
pause
