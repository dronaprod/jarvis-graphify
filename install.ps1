# ─────────────────────────────────────────────────────────────────────────────
# jarvis-graphify installer — Windows (PowerShell)
#
# One-liner install (downloads wheel from GitHub Releases):
#   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drona-jarvis-org/jarvis_graphify/main/release/install.ps1" -OutFile install.ps1; .\install.ps1
#
# From a cloned / unzipped release folder:
#   .\install.ps1                     # user install (no admin needed)
#   .\install.ps1 -Global             # system-wide (requires admin)
# ─────────────────────────────────────────────────────────────────────────────
param(
    [switch]$Global = $false,
    [switch]$Force  = $false
)

$Tool       = "jarvis-graphify"
$Version    = "1.1.0"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir    = "$env:USERPROFILE\.jarvis-graphify\venv"
$UserBin    = "$env:USERPROFILE\.local\bin"
$GlobalBin  = "C:\Program Files\jarvis-graphify"
$ReleaseUrl = "https://github.com/drona-jarvis-org/jarvis_graphify/releases/download/v${Version}/jarvis_graphify-${Version}-py3-none-any.whl"

function Write-Step($msg) { Write-Host "[jarvis-graphify] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[warning] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║      jarvis-graphify installer       ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Detect Python ─────────────────────────────────────────────────────────
$Python = $null
foreach ($cmd in @("python3", "python")) {
    try {
        $ver = & $cmd -c "import sys; print(sys.version_info >= (3,9))" 2>$null
        if ($ver -eq "True") { $Python = $cmd; break }
    } catch {}
}
if (-not $Python) {
    Write-Err "Python 3.9+ not found. Download from https://python.org/downloads (check 'Add to PATH')"
}
Write-Step "Using $(& $Python --version)"

# ── Create virtual environment ────────────────────────────────────────────
Write-Step "Creating virtual environment at $VenvDir ..."
New-Item -ItemType Directory -Force -Path (Split-Path $VenvDir) | Out-Null
& $Python -m venv $VenvDir
$VenvPip = "$VenvDir\Scripts\pip.exe"
$VenvBin = "$VenvDir\Scripts\jarvis-graphify.exe"

# ── Locate or download wheel ──────────────────────────────────────────────
$WheelPath = $null
$TmpWhl    = $null

# 1. Try local dist\ (when run from a cloned / unzipped release folder)
if ($ScriptDir) {
    $LocalWheel = Get-ChildItem "$ScriptDir\dist\*.whl" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($LocalWheel) { $WheelPath = $LocalWheel.FullName }
}

# 2. Download from GitHub Releases (one-liner install)
if (-not $WheelPath) {
    Write-Step "Downloading jarvis-graphify v${Version} from GitHub Releases..."
    $TmpWhl = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.whl'
    try {
        Invoke-WebRequest -Uri $ReleaseUrl -OutFile $TmpWhl -UseBasicParsing -ErrorAction Stop
        $WheelPath = $TmpWhl
    } catch {
        Write-Err "Download failed: $_`nVisit https://github.com/drona-jarvis-org/jarvis_graphify/releases"
    }
}

Write-Step "Installing from $(Split-Path -Leaf $WheelPath) ..."
& $VenvPip install --upgrade pip --quiet
& $VenvPip install --force-reinstall $WheelPath --quiet

# Clean up temp file
if ($TmpWhl -and (Test-Path $TmpWhl)) { Remove-Item $TmpWhl -Force }

if (-not (Test-Path $VenvBin)) {
    Write-Err "Install failed — executable not found at $VenvBin"
}

# ── Link / add to PATH ────────────────────────────────────────────────────
if ($Global) {
    Write-Step "Installing system-wide to $GlobalBin ..."
    New-Item -ItemType Directory -Force -Path $GlobalBin | Out-Null
    Copy-Item $VenvBin "$GlobalBin\jarvis-graphify.exe" -Force
    $syspath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($syspath -notlike "*$GlobalBin*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$syspath;$GlobalBin", "Machine")
        Write-Step "Added $GlobalBin to system PATH"
    }
} else {
    Write-Step "Installing to user PATH at $UserBin ..."
    New-Item -ItemType Directory -Force -Path $UserBin | Out-Null
    Copy-Item $VenvBin "$UserBin\jarvis-graphify.exe" -Force
    $userpath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userpath -notlike "*$UserBin*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$userpath;$UserBin", "User")
        Write-Step "Added $UserBin to user PATH"
    }
    Write-Warn "Close and reopen PowerShell for PATH changes to take effect."
}

# ── Done ──────────────────────────────────────────────────────────────────
$InstalledVer = & $VenvBin --version 2>&1
Write-Host ""
Write-Step "Installed: $InstalledVer"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Restart PowerShell"
Write-Host "    2. Go to your project:     cd C:\path\to\your-project"
Write-Host "    3. Create config:          jarvis-graphify setup"
Write-Host "    4. Edit the config:        notepad jarvis-graphify-in\settings.json"
Write-Host "    5. Run the scan:           jarvis-graphify ."
Write-Host "    6. Open the graph:         start jarvis-graphify-out\graph.html"
Write-Host ""
Write-Host "  Docs & source:  https://github.com/drona-jarvis-org/jarvis_graphify" -ForegroundColor Cyan
Write-Host ""
