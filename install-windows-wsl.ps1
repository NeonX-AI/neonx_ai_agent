#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$InstallDir = "neonx-ai-agent"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Wsl {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    & wsl.exe @Arguments
    $code = $LASTEXITCODE
    if (-not $AllowFailure -and $code -ne 0) {
        throw "wsl.exe failed with exit code $code: $($Arguments -join ' ')"
    }
    return $code
}

function Convert-ToWslPath([string]$WindowsPath) {
    $fullPath = [IO.Path]::GetFullPath($WindowsPath)
    if ($fullPath -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "The installer must be run from a local Windows drive: $fullPath"
    }

    $drive = $Matches[1].ToLowerInvariant()
    $tail = $Matches[2].Replace('\', '/')
    return "/mnt/$drive/$tail"
}

if (-not (Test-Administrator)) {
    Write-Host "Requesting Administrator permission..." -ForegroundColor Yellow
    $argumentList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $PSCommandPath),
        "-Distro", ('"{0}"' -f $Distro),
        "-InstallDir", ('"{0}"' -f $InstallDir)
    )
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList $argumentList -Wait -PassThru
    exit $process.ExitCode
}

try {
    Write-Step "Checking Windows requirements"
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    if ($build -lt 19045) {
        throw "Windows 10 22H2 (build 19045) or Windows 11 is required. Current build: $build"
    }

    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    $restartNeeded = $false

    if ($wslFeature.State -ne "Enabled") {
        Write-Step "Enabling Windows Subsystem for Linux"
        $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
        $restartNeeded = $restartNeeded -or $result.RestartNeeded
    }
    if ($vmFeature.State -ne "Enabled") {
        Write-Step "Enabling Virtual Machine Platform"
        $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
        $restartNeeded = $restartNeeded -or $result.RestartNeeded
    }

    if ($restartNeeded) {
        Write-Warning "Windows features were enabled and a restart is required. Restart Windows, then double-click install-windows-wsl.bat again."
        exit 3010
    }

    Write-Step "Updating WSL and selecting WSL 2"
    Invoke-Wsl -Arguments @("--update")
    Invoke-Wsl -Arguments @("--set-default-version", "2")

    $installedDistros = @(& wsl.exe --list --quiet 2>$null) | ForEach-Object { ($_ -replace "`0", "").Trim() } | Where-Object { $_ }
    if ($installedDistros -notcontains $Distro) {
        Write-Step "Installing $Distro"
        $installCode = Invoke-Wsl -Arguments @("--install", "--distribution", $Distro, "--no-launch") -AllowFailure
        if ($installCode -ne 0) {
            Write-Warning "The requested distro name was unavailable; installing the default Ubuntu distribution."
            Invoke-Wsl -Arguments @("--install", "--distribution", "Ubuntu", "--no-launch")
            $Distro = "Ubuntu"
        }
    }

    Write-Step "Initializing $Distro"
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "sh", "-lc", "true")

    Write-Step "Enabling systemd in WSL"
    $systemdCommand = "printf '[boot]\nsystemd=true\n' > /etc/wsl.conf"
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "sh", "-lc", $systemdCommand)
    Invoke-Wsl -Arguments @("--terminate", $Distro)
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "sh", "-lc", "true")

    Write-Step "Ensuring Docker Engine is available inside WSL (Docker Desktop is not used)"
    $dockerInstall = @'
set -eu
export DEBIAN_FRONTEND=noninteractive
if docker info >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker Engine and Compose are already working; keeping the installed versions."
    apt-get update
    apt-get install -y --no-upgrade rsync ca-certificates curl
else
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    . /etc/os-release
    printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' "$VERSION_CODENAME" "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/docker.sources
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin rsync
fi
systemctl enable --now docker
docker version
docker compose version
'@
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "bash", "-lc", $dockerInstall)

    Write-Step "Safely synchronizing NeonX into the WSL Linux filesystem"
    $sourcePath = Convert-ToWslPath $PSScriptRoot
    $safeInstallDir = $InstallDir -replace '[^A-Za-z0-9._-]', '-'
    if ([string]::IsNullOrWhiteSpace($safeInstallDir)) { $safeInstallDir = "neonx-ai-agent" }
    $targetPath = "/opt/$safeInstallDir"
    $copyCommand = @"
set -eu
target='$targetPath'
source='$sourcePath'
marker="`$target/.neonx-installed"
mkdir -p "`$target"
if [ -f "`$marker" ] || [ -d "`$target/clients" ]; then
    backup_root="/var/backups/neonx-ai-agent"
    timestamp=`$(date +%Y%m%d-%H%M%S)
    backup="`$backup_root/$safeInstallDir-`$timestamp.tar.gz"
    mkdir -p "`$backup_root"
    items=""
    [ -d "`$target/clients" ] && items="clients"
    [ -f "`$target/.env.meta" ] && items="`$items .env.meta"
    if [ -n "`$items" ]; then
        tar -C "`$target" -czf "`$backup" `$items
        echo "Runtime backup created: `$backup"
    fi
    rsync -a --delete \
        --exclude '/clients/' \
        --exclude '/.env.meta' \
        --exclude '/.neonx-installed' \
        "`$source/" "`$target/"
    echo "Existing clients and credentials were preserved."
else
    rsync -a --delete --exclude '/.neonx-installed' "`$source/" "`$target/"
    echo "Initial project copy completed."
fi
touch "`$marker"
chmod +x "`$target/"*.sh "`$target/"create-client.d/*.sh "`$target/"update-clients.d/*.sh 2>/dev/null || true
find /var/backups/neonx-ai-agent -type f -name '*.tar.gz' -mtime +30 -delete 2>/dev/null || true
"@
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "bash", "-lc", $copyCommand)

    Write-Step "Verifying Docker"
    Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "docker", "info")

    Write-Step "Opening NeonX"
    Write-Host "Project in WSL: $targetPath" -ForegroundColor Green
    Write-Host "Backups in WSL: /var/backups/neonx-ai-agent" -ForegroundColor Green
    Write-Host "Docker Desktop was not installed and is not required." -ForegroundColor Green

    $hasClientsCode = Invoke-Wsl -Arguments @("-d", $Distro, "-u", "root", "--", "bash", "-lc", "find '$targetPath/clients' -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null | grep -q .") -AllowFailure
    if ($hasClientsCode -eq 0) {
        Write-Host "Existing clients were preserved. Use ./update-clients.sh when you want to apply new templates and restart them." -ForegroundColor Yellow
        $launchCommand = "cd '$targetPath'; printf '\nNeonX upgraded safely.\nCommands: ./update-clients.sh or ./create-client.sh\n\n'; exec bash"
    }
    else {
        Write-Host "No client exists yet. Enter the API and channel settings in the window that opens." -ForegroundColor Yellow
        $launchCommand = "cd '$targetPath' && ./create-client.sh; exec bash"
    }
    Start-Process wsl.exe -ArgumentList @("-d", $Distro, "-u", "root", "--cd", $targetPath, "--", "bash", "-lc", $launchCommand)
    exit 0
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Fix the error and run install-windows-wsl.bat again; completed steps are safe to repeat." -ForegroundColor Yellow
    exit 1
}
