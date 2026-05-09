# Enable Tailscale subnet routing to reach OB1 MCP server
# This script configures Tailscale on Windows to use routes advertised by the Mac Mini
#
# Prerequisites:
#   - Tailscale installed (https://tailscale.com/download)
#   - Mac Mini is online and has run: bash ~/scripts/lf2b-tailscale-setup.sh
#
# Usage:
#   .\setup-tailscale-routes.ps1
#
# Author: JP Cruz
# Date: 2026-05-08

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor $Color
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ Tailscale Routes Setup for OB1 MCP (Windows)                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Tailscale is installed
Write-Status "Checking Tailscale installation..." "Cyan"
$tailscale = Get-Command tailscale -ErrorAction SilentlyContinue

if (-not $tailscale) {
    Write-Status "ERROR: Tailscale not found. Install from: https://tailscale.com/download" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Status "✓ Tailscale found: $($tailscale.Source)" "Green"

# Check if Tailscale is running
Write-Status "Checking Tailscale status..." "Cyan"
try {
    $status = & tailscale status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ Tailscale is running" "Green"
    } else {
        Write-Status "✗ Tailscale is not connected. Run: tailscale up" "Red"
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Status "ERROR: Failed to check Tailscale status" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

# Get current status
Write-Status "Current Tailscale status:" "Cyan"
Write-Host ""

try {
    $statusOutput = & tailscale status
    foreach ($line in ($statusOutput -split "`n")) {
        if ($line -match "jps-mac-mini|Mac Mini|100\.\d+") {
            Write-Host "  $line"
        }
    }
} catch {
    Write-Status "Could not parse Tailscale status" "Yellow"
}

Write-Host ""

# Check if already accepting routes
Write-Status "Enabling subnet route acceptance..." "Cyan"

# Run tailscale up with --accept-routes
# This requires admin privileges (will prompt via Tailscale's UI)
Write-Status "You will be prompted to approve this in the Tailscale UI." "Yellow"
Write-Status "Running: tailscale up --accept-routes" "Cyan"

try {
    & tailscale up --accept-routes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ Routes enabled successfully" "Green"
    } else {
        Write-Status "⚠ Tailscale returned a non-zero exit code (may still have succeeded)" "Yellow"
    }
} catch {
    Write-Status "ERROR: Failed to enable routes: $_" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Verify the configuration
Write-Status "Verifying configuration..." "Cyan"
try {
    $newStatus = & tailscale status
    $macMiniFound = $false
    foreach ($line in ($newStatus -split "`n")) {
        if ($line -match "jps-mac-mini|Mac Mini") {
            Write-Status "Mac Mini status: $line" "Green"
            $macMiniFound = $true
        }
    }

    if (-not $macMiniFound) {
        Write-Status "⚠ Mac Mini not found in Tailscale peers yet." "Yellow"
        Write-Status "  Make sure the Mac Mini is online and connected to Tailscale." "Yellow"
        Write-Status "  It may take a few seconds to appear in the peer list." "Yellow"
    }
} catch {
    Write-Status "Could not verify configuration" "Yellow"
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║ Setup Complete!" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Status "Your Windows machine can now reach:" "Cyan"
Write-Host "  • Mac Mini LAN: 10.0.3.0/24 (via Tailscale tunnel)" -ForegroundColor White
Write-Host "  • OB1 MCP Server: http://10.0.3.5:8100/mcp" -ForegroundColor White
Write-Host ""

Write-Status "Next steps:" "Cyan"
Write-Host "  1. Run the main setup script: .\setup-ob1-mcp-claude.ps1" -ForegroundColor White
Write-Host "  2. Choose 'Tailscale' as the connection method" -ForegroundColor White
Write-Host "  3. The script will find your Mac Mini's Tailscale IP automatically" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
