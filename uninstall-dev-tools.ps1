# ============================================================
#  Student Dev Tools UNINSTALLER - Windows
#  Removes: Git, Visual Studio 2026 Community, VS Code,
#           MySQL Server + Workbench
#  Requires: Windows 10/11, winget (App Installer)
#
#  One-liner (run in PowerShell as Administrator):
#    irm https://raw.githubusercontent.com/CruzSanchez/DayOneSetup/main/UninstallDevTools.ps1 | iex
# ============================================================

# Auto-relaunch as Administrator if not already elevated
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# ── Helpers ──────────────────────────────────────────────────

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Uninstall-Tool {
    param(
        [string]$Name,
        [string]$WingetId
    )

    Write-Header "Uninstalling $Name"

    $checkResult = winget list --id $WingetId --exact 2>&1
    if ($checkResult -notmatch [regex]::Escape($WingetId)) {
        Write-Host "  [SKIP] $Name is not installed." -ForegroundColor Yellow
        return
    }

    & winget uninstall --id $WingetId --exact --silent --accept-source-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $Name uninstalled." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $Name may not have uninstalled cleanly. Exit code: $LASTEXITCODE" -ForegroundColor Red
    }
}

function Uninstall-MySQL {
    Write-Header "Uninstalling MySQL Server"

    # Stop the service before uninstalling
    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($mysqlService -is [System.ServiceProcess.ServiceController]) {
        Write-Host "  Stopping $($mysqlService.Name) service..." -ForegroundColor DarkGray
        Stop-Service -Name $mysqlService.Name -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Service stopped." -ForegroundColor Green
    }

    $checkResult = winget list --id Oracle.MySQL --exact 2>&1
    if ($checkResult -notmatch "Oracle.MySQL") {
        Write-Host "  [SKIP] MySQL Server is not installed." -ForegroundColor Yellow
    } else {
        & winget uninstall --id Oracle.MySQL --exact --silent --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] MySQL Server uninstalled." -ForegroundColor Green
        } else {
            Write-Host "  [WARN] MySQL Server may not have uninstalled cleanly." -ForegroundColor Red
        }
    }

    # Clean up leftover data directory (optional — prompts user)
    $dataDir = "C:\ProgramData\MySQL"
    if (Test-Path $dataDir) {
        Write-Host ""
        Write-Host "  MySQL data directory found at: $dataDir" -ForegroundColor Yellow
        Write-Host "  This contains your databases. Delete it? (y/n): " -ForegroundColor Yellow -NoNewline
        $confirm = Read-Host
        if ($confirm -eq 'y') {
            Remove-Item -Recurse -Force $dataDir -ErrorAction SilentlyContinue
            Write-Host "  [OK] MySQL data directory removed." -ForegroundColor Green
        } else {
            Write-Host "  [SKIP] MySQL data directory kept." -ForegroundColor DarkGray
        }
    }
}

# ── Confirm before proceeding ─────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "  ║     Student Dev Tools UNINSTALLER (Windows)  ║" -ForegroundColor Red
Write-Host "  ║  Git | Visual Studio 2026 | VS Code | MySQL  ║" -ForegroundColor Red
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  This will uninstall all student dev tools from this machine." -ForegroundColor Yellow
Write-Host "  Are you sure you want to continue? (y/n): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host

if ($confirm -ne 'y') {
    Write-Host ""
    Write-Host "  Uninstall cancelled." -ForegroundColor DarkGray
    exit 0
}

# ── MySQL Workbench ───────────────────────────────────────────
Uninstall-Tool -Name "MySQL Workbench" -WingetId "Oracle.MySQLWorkbench"

# ── MySQL Server ──────────────────────────────────────────────
Uninstall-MySQL

# ── VS Code ───────────────────────────────────────────────────
Uninstall-Tool -Name "Visual Studio Code" -WingetId "Microsoft.VisualStudioCode"

# ── Visual Studio 2026 Community ─────────────────────────────
Uninstall-Tool -Name "Visual Studio 2026 Community" -WingetId "Microsoft.VisualStudio.Community.Insiders"

# ── Git ──────────────────────────────────────────────────────
Uninstall-Tool -Name "Git" -WingetId "Git.Git"

# ── Done ─────────────────────────────────────────────────────
Write-Header "Uninstall Complete"
Write-Host ""
Write-Host "  All dev tools have been removed." -ForegroundColor White
Write-Host "  Some changes may require a restart to fully take effect." -ForegroundColor Yellow
Write-Host ""
