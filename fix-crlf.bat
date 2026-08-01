@echo off
echo Fixing CRLF line endings in shell scripts and config files...
echo.

REM Fix .sh files
for /r %%f in (*.sh) do (
    echo Fixing: %%f
    powershell -Command "$content = Get-Content '%%f' -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('%%f', $content, [System.Text.UTF8Encoding]::new($false))"
)

REM Fix .json files
for /r %%f in (*.json) do (
    echo Fixing: %%f
    powershell -Command "$content = Get-Content '%%f' -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('%%f', $content, [System.Text.UTF8Encoding]::new($false))"
)

REM Fix .yml and .yaml files
for /r %%f in (*.yml *.yaml) do (
    echo Fixing: %%f
    powershell -Command "$content = Get-Content '%%f' -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('%%f', $content, [System.Text.UTF8Encoding]::new($false))"
)

REM Fix .env files
for /r %%f in (.env .env.*) do (
    if exist "%%f" (
        echo Fixing: %%f
        powershell -Command "$content = Get-Content '%%f' -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('%%f', $content, [System.Text.UTF8Encoding]::new($false))"
    )
)

echo.
echo Done! All files converted to LF line endings.
pause
