# ============================================================
#  Student Dev Tools Installer - Windows
#  Installs: Git, Visual Studio 2026 Community, VS Code,
#            MySQL Server + Workbench
#  Requires: Windows 10/11, winget (App Installer)
#
#  One-liner (run in PowerShell as Administrator):
#    irm https://raw.githubusercontent.com/CruzSanchez/DayOneSetup/main/DayOneSetupWindows.ps1 | iex
# ============================================================

# Auto-relaunch as Administrator if not already elevated
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Install-Tool {
    param(
        [string]$Name,
        [string]$WingetId,
        [string[]]$ExtraArgs = @()
    )

    Write-Header "Installing $Name"

    $checkResult = winget list --id $WingetId --exact 2>&1
    if ($checkResult -match [regex]::Escape($WingetId)) {
        Write-Host "  [SKIP] $Name is already installed." -ForegroundColor Yellow
        return
    }

    $cmdArgs = @("install", "--id", $WingetId, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements") + $ExtraArgs

    Write-Host "  Running: winget $($cmdArgs -join ' ')" -ForegroundColor DarkGray
    & winget @cmdArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $Name installed successfully." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $Name may not have installed cleanly. Exit code: $LASTEXITCODE" -ForegroundColor Red
    }
}

function Assert-Winget {
    Write-Header "Checking winget availability"
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "  [ERROR] winget not found." -ForegroundColor Red
        Write-Host "  Install 'App Installer' from the Microsoft Store, then re-run this script." -ForegroundColor Yellow
        Write-Host "  https://aka.ms/getwinget" -ForegroundColor DarkGray
        exit 1
    }
    Write-Host "  [OK] winget is available." -ForegroundColor Green
}

function Install-MySQL {
    Write-Header "Installing MySQL Server"

    $checkResult = winget list --id Oracle.MySQL --exact 2>&1
    if ($checkResult -match "Oracle.MySQL") {
        Write-Host "  [SKIP] MySQL Server is already installed." -ForegroundColor Yellow
    } else {
        & winget install --id Oracle.MySQL --exact --silent --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [WARN] MySQL install may not have completed cleanly." -ForegroundColor Red
            return
        }
        Write-Host "  [OK] MySQL Server installed." -ForegroundColor Green
    }

    # Dynamically find the MySQL service (handles MySQL80, MySQL84, etc.)
    Write-Host "  Waiting for MySQL service to register..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 10

    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($mysqlService -is [System.ServiceProcess.ServiceController]) {
        try {
            Start-Service -Name $mysqlService.Name -ErrorAction Stop
            Write-Host "  [OK] $($mysqlService.Name) service started." -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Could not start $($mysqlService.Name): $_" -ForegroundColor Red
            return
        }
    } else {
        Write-Host "  [WARN] No MySQL service found. It may need a reboot to register." -ForegroundColor Red
        return
    }

    Start-Sleep -Seconds 10

    # Dynamically find mysqladmin on disk (handles any version install path)
    $mysqladmin = Get-ChildItem "C:\Program Files\MySQL" -Recurse -Filter "mysqladmin.exe" -ErrorAction SilentlyContinue |
                  Select-Object -First 1 -ExpandProperty FullName

    if (-not $mysqladmin) {
        Write-Host "  [WARN] mysqladmin.exe not found. Set password manually in MySQL Workbench." -ForegroundColor Yellow
        return
    }

    Write-Host "  Setting MySQL root password using: $mysqladmin" -ForegroundColor DarkGray
    & $mysqladmin -u root password "password" 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Root password set to: password" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Could not set root password automatically." -ForegroundColor Yellow
        Write-Host "         Set it manually in MySQL Workbench on first launch." -ForegroundColor Yellow
    }
}

# ── Main ─────────────────────────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     Student Dev Tools Installer (Windows)    ║" -ForegroundColor Magenta
Write-Host "  ║  Git | Visual Studio 2026 | VS Code | MySQL  ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

Assert-Winget

# ── Git ──────────────────────────────────────────────────────
Install-Tool -Name "Git" -WingetId "Git.Git"

# ── Visual Studio 2026 Community ─────────────────────────────
# NOTE: Using Community Insiders build (VS 2026 preview).
#       Once the stable 2026 winget ID is published, replace with:
#       Microsoft.VisualStudio.2026.Community
# Workloads: .NET Desktop, ASP.NET, Data Storage & Processing
Install-Tool `
    -Name "Visual Studio 2026 Community" `
    -WingetId "Microsoft.VisualStudio.Community.Insiders" `
    -ExtraArgs @(
        "--override",
        "--add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.Data --includeRecommended --passive --norestart"
    )

# ── VS Code ───────────────────────────────────────────────────
Install-Tool -Name "Visual Studio Code" -WingetId "Microsoft.VisualStudioCode"

# ── MySQL Server + password config ───────────────────────────
Install-MySQL

# ── MySQL Workbench ───────────────────────────────────────────
Install-Tool -Name "MySQL Workbench" -WingetId "Oracle.MySQLWorkbench"

# ── Done ─────────────────────────────────────────────────────
Write-Header "Installation Complete"
Write-Host ""
Write-Host "  The following tools were processed:" -ForegroundColor White
Write-Host "    • Git                          (git --version)" -ForegroundColor Green
Write-Host "    • Visual Studio 2026 Community                " -ForegroundColor Green
Write-Host "    • Visual Studio Code           (code --version)" -ForegroundColor Green
Write-Host "    • MySQL Server                 root pw: password" -ForegroundColor Green
Write-Host "    • MySQL Workbench                              " -ForegroundColor Green
Write-Host ""
Write-Host "  Restart your computer before class." -ForegroundColor Yellow
Write-Host ""
