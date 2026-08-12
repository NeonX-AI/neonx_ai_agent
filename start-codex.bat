@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Codex - Select OpenClaw Client

set "WORKSPACE=/home/node/.openclaw/projects"
rem Keep terminal Codex threads separate from OpenClaw's Telegram/App Server state.
rem This path is inside the persistent OpenClaw mount.
set "CODEX_HOME=/home/node/.openclaw/codex-interactive"

echo ========================================
echo   Codex Interactive Terminal
echo ========================================
echo.

where docker >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker was not found in PATH.
    echo Install or start Docker Desktop, then try again.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Desktop is not running.
    pause
    exit /b 1
)

set "COUNT=0"
for /f "delims=" %%A in ('docker ps --filter "label=com.docker.compose.service=ai_agent" --format "{{.Names}}"') do (
    set "PROJECT="
    for /f "delims=" %%B in ('docker inspect -f "{{index .Config.Labels \"com.docker.compose.project\"}}" "%%A" 2^>nul') do set "PROJECT=%%B"
    if not defined PROJECT set "PROJECT=%%A"
    set /a COUNT+=1
    set "CONTAINER[!COUNT!]=%%A"
    set "CLIENT[!COUNT!]=!PROJECT!"
)

if "!COUNT!"=="0" (
    echo [ERROR] No running OpenClaw client containers were found.
    echo Start a client first, then try again.
    pause
    exit /b 1
)

if "!COUNT!"=="1" (
    set "SELECTION=1"
) else (
    echo Available OpenClaw clients:
    echo.
    for /l %%N in (1,1,!COUNT!) do echo   %%N. !CLIENT[%%N]!  [!CONTAINER[%%N]!]
    echo.
    set /p "SELECTION=Enter client number: "
)

set "CONTAINER=!CONTAINER[%SELECTION%]!"
set "CLIENT=!CLIENT[%SELECTION%]!"
if not defined CONTAINER (
    echo [ERROR] Invalid client number: !SELECTION!
    pause
    exit /b 1
)

title Codex - !CLIENT!
echo.
echo Selected client : !CLIENT!
echo Container       : !CONTAINER!
echo Workspace       : %WORKSPACE%
echo Codex state     : %CODEX_HOME%
echo.

docker exec "!CONTAINER!" sh -lc "command -v codex >/dev/null 2>&1"
if errorlevel 1 (
    echo [ERROR] Codex CLI is not installed in this client yet.
    echo Wait for container bootstrap to finish, then try again.
    pause
    exit /b 1
)

docker exec "!CONTAINER!" sh -lc "mkdir -p '%CODEX_HOME%' && if [ ! -f '%CODEX_HOME%/config.toml' ] && [ -f /root/.codex/config.toml ]; then cp /root/.codex/config.toml '%CODEX_HOME%/config.toml'; chmod 600 '%CODEX_HOME%/config.toml'; fi"
if errorlevel 1 (
    echo [ERROR] Could not prepare the isolated Codex state directory.
    pause
    exit /b 1
)

echo Starting isolated Codex session. Type /help for help, or Ctrl+C to exit.
echo.

docker exec -it -e "CODEX_HOME=%CODEX_HOME%" -w "%WORKSPACE%" "!CONTAINER!" codex --sandbox danger-full-access --ask-for-approval never --no-alt-screen

set "EXIT_CODE=!ERRORLEVEL!"
echo.
if not "!EXIT_CODE!"=="0" echo Codex exited with code !EXIT_CODE!.
echo Codex session closed.
pause
exit /b !EXIT_CODE!
