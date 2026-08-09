@echo off
title AutoCAD MCP Launcher

echo ========================================
echo   Starting AutoCAD MCP...
echo ========================================

start "AutoCAD MCP Server" cmd /k "autocad-mcp --transport http --port 8000"

timeout /t 2 /nobreak >nul

echo Opening Chat...
start "" "http://localhost:18789/chat?session=main"

exit
