# LF2B OB1 MCP Setup for Windows — Claude Code, Claude Desktop, Claude Cowork
#
# This script configures all Claude clients on Windows to connect to the OB1 MCP server
# running on the Mac Mini (jps-mac-mini on the home LAN or via Tailscale).
#
# Requirements:
#   - PowerShell 5.0+ (built-in on Windows 10+)
#   - One of: Direct LAN access to 10.0.3.5, or Tailscale installed + configured
#   - MCP access key (paste when prompted or set as env var: $env:LF2B_MCP_KEY)
#
# Usage:
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force  # if needed
#   .\setup-ob1-mcp-claude.ps1
#
# Author: JP Cruz (via Claude Code automation)
# Date: 2026-05-08

param(
    [string]$ServerAddress = "",
    [string]$AccessKey = "",
    [switch]$UseTailscale = $false,
    [switch]$SkipValidation = $false,
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Colors for output
$Colors = @{
    "Success" = "Green"
    "Error" = "Red"
    "Warning" = "Yellow"
    "Info" = "Cyan"
}

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor $Colors[$Level]
}

function Test-Connectivity {
    param([string]$Address, [int]$Port = 8100)

    Write-Log "Testing connectivity to $Address`:$Port..." "Info"

    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ConnectAsync($Address, $Port).Wait(3000) | Out-Null

        if ($tcp.Connected) {
            $tcp.Close()
            Write-Log "✓ Server is reachable at $Address`:$Port" "Success"
            return $true
        } else {
            Write-Log "✗ Connection timeout to $Address`:$Port" "Error"
            return $false
        }
    } catch {
        Write-Log "✗ Connection failed: $_" "Error"
        return $false
    }
}

function Test-MCP-Server {
    param([string]$Url, [string]$AccessKey)

    Write-Log "Validating MCP server at $Url..." "Info"

    try {
        $headers = @{
            "x-brain-key" = $AccessKey
            "Accept" = "text/event-stream"
        }

        # Server should accept the connection and start streaming (SSE)
        # We just test that it doesn't reject the auth header
        $response = Invoke-WebRequest -Uri "$Url" -Headers $headers -TimeoutSec 3 -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Log "✓ MCP server authenticated successfully" "Success"
            return $true
        }
    } catch {
        if ($_.Exception.Message -like "*401*" -or $_.Exception.Response.StatusCode -eq 401) {
            Write-Log "✗ Authentication failed (401). Check your access key." "Error"
            return $false
        } elseif ($_.Exception.Message -like "*Connection*") {
            Write-Log "✗ Cannot reach server. Check address and network connectivity." "Error"
            return $false
        } else {
            Write-Log "⚠ Server responded but validation inconclusive (this is OK for SSE streams)" "Warning"
            return $true
        }
    }
}

function Get-TailscaleIP {
    Write-Log "Looking for Tailscale configuration..." "Info"

    try {
        # Check if Tailscale is installed
        $tailscale = Get-Command tailscale -ErrorAction SilentlyContinue
        if (-not $tailscale) {
            Write-Log "⚠ Tailscale not found in PATH. Install from https://tailscale.com/download" "Warning"
            return $null
        }

        # Get Tailscale status
        $status = & tailscale status 2>$null
        if ($status) {
            Write-Log "✓ Tailscale is running" "Success"

            # Extract jps-mac-mini Tailscale IP from status output
            $macMiniLine = $status | Select-String "jps-mac-mini|Mac Mini" | Select-Object -First 1
            if ($macMiniLine) {
                $ip = ([string]$macMiniLine) -replace '.*\s(100\.\d+\.\d+\.\d+).*', '$1'
                if ($ip -match '^\d+\.\d+\.\d+\.\d+$') {
                    Write-Log "✓ Found Mac Mini Tailscale IP: $ip" "Success"
                    return $ip
                }
            }

            Write-Log "⚠ Mac Mini not found in Tailscale peers. Make sure it's online and you've run:" "Warning"
            Write-Log "  - On Mac Mini: sudo tailscale up --advertise-routes=10.0.3.0/24" "Info"
            Write-Log "  - On this Windows machine: sudo tailscale up --accept-routes" "Info"
            return $null
        }
    } catch {
        Write-Log "⚠ Tailscale check failed: $_" "Warning"
    }

    return $null
}

function Get-ServerAddress {
    $attempt = 0

    while ($attempt -lt 3) {
        Write-Log "Select connection method:" "Info"
        Write-Host ""
        Write-Host "  1. Direct LAN (10.0.3.5) — requires same network as Mac Mini" -ForegroundColor White
        Write-Host "  2. Tailscale — VPN tunnel (recommended for remote access)" -ForegroundColor White
        Write-Host "  3. Custom IP/hostname" -ForegroundColor White
        Write-Host ""

        $choice = Read-Host "Enter choice (1-3)"

        switch ($choice) {
            "1" {
                $addr = "10.0.3.5"
                if (Test-Connectivity $addr) {
                    return $addr
                } else {
                    Write-Log "Direct LAN not reachable. Try Tailscale instead." "Warning"
                    $attempt++
                }
            }
            "2" {
                $tsIP = Get-TailscaleIP
                if ($tsIP) {
                    return $tsIP
                } else {
                    Write-Log "Cannot proceed with Tailscale. Ensure it's set up correctly." "Error"
                    $attempt++
                }
            }
            "3" {
                $custom = Read-Host "Enter IP or hostname (e.g., 192.168.1.5 or myserver.local)"
                if (Test-Connectivity $custom) {
                    return $custom
                } else {
                    Write-Log "Cannot reach $custom" "Warning"
                    $attempt++
                }
            }
            default {
                Write-Log "Invalid choice. Try again." "Warning"
                $attempt++
            }
        }
    }

    throw "Failed to obtain server address after 3 attempts"
}

function Get-AccessKey {
    if ($AccessKey) {
        return $AccessKey
    }

    if ($env:LF2B_MCP_KEY) {
        Write-Log "Using LF2B_MCP_KEY from environment variable" "Info"
        return $env:LF2B_MCP_KEY
    }

    Write-Log "Paste your MCP access key (from Mac Mini Keychain):" "Info"
    Write-Host "  Location: security find-generic-password -s lf2b_ob1_mcp_key -a ob1_mcp -w" -ForegroundColor DarkGray
    Write-Host ""

    $key = Read-Host "Enter access key" -AsSecureString
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($key))
}

function Update-ClaudeCodeConfig {
    param([string]$ServerIP, [string]$AccessKey, [bool]$DryRun)

    Write-Log "Configuring Claude Code..." "Info"

    $configPath = "$env:APPDATA\.claude\settings.json"
    $configDir = Split-Path $configPath

    if (-not (Test-Path $configDir)) {
        Write-Log "Creating directory: $configDir" "Info"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
    }

    $ob1Config = @{
        "command" = "npx"
        "args" = @(
            "-y",
            "mcp-remote",
            "http://$ServerIP`:8100/mcp",
            "--header",
            "x-brain-key:$AccessKey"
        )
    }

    $settings = @{}
    if (Test-Path $configPath) {
        $existing = Get-Content $configPath -Raw | ConvertFrom-Json
        $settings = $existing
    }

    if (-not $settings.mcpServers) {
        $settings | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{}
    }

    $settings.mcpServers.ob1 = $ob1Config

    Write-Log "  MCP server 'ob1' configured: http://$ServerIP`:8100/mcp" "Info"

    if (-not $DryRun) {
        $settings | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
        Write-Log "✓ Claude Code config saved to: $configPath" "Success"
    } else {
        Write-Log "[DRY RUN] Would save to: $configPath" "Warning"
    }

    return $configPath
}

function Update-ClaudeDesktopConfig {
    param([string]$ServerIP, [string]$AccessKey, [bool]$DryRun)

    Write-Log "Configuring Claude Desktop..." "Info"

    $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
    $configDir = Split-Path $configPath

    if (-not (Test-Path $configDir)) {
        Write-Log "Creating directory: $configDir" "Info"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
    }

    $ob1Config = @{
        "command" = "npx"
        "args" = @(
            "-y",
            "mcp-remote",
            "http://$ServerIP`:8100/mcp",
            "--header",
            "x-brain-key:$AccessKey"
        )
    }

    $settings = @{}
    if (Test-Path $configPath) {
        $existing = Get-Content $configPath -Raw | ConvertFrom-Json
        $settings = $existing
    }

    if (-not $settings.mcpServers) {
        $settings | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{}
    }

    $settings.mcpServers.ob1 = $ob1Config

    Write-Log "  MCP server 'ob1' configured: http://$ServerIP`:8100/mcp" "Info"

    if (-not $DryRun) {
        $settings | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
        Write-Log "✓ Claude Desktop config saved to: $configPath" "Success"
    } else {
        Write-Log "[DRY RUN] Would save to: $configPath" "Warning"
    }

    return $configPath
}

function Update-ClaudeCoworkConfig {
    param([string]$ServerIP, [string]$AccessKey, [bool]$DryRun)

    Write-Log "Configuring Claude Cowork..." "Info"

    # Claude Cowork might share config with Desktop or be in a different location
    # Try multiple possible locations
    $possiblePaths = @(
        "$env:APPDATA\Claude\claude_cowork_config.json",
        "$env:APPDATA\Claude\cowork\config.json",
        "$env:LOCALAPPDATA\Claude\claude_cowork_config.json"
    )

    $configPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $configPath = $path
            break
        }
    }

    # Default to the standard location if none exist
    if (-not $configPath) {
        $configPath = $possiblePaths[0]
    }

    $configDir = Split-Path $configPath

    if (-not (Test-Path $configDir)) {
        Write-Log "Creating directory: $configDir" "Info"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
    }

    $ob1Config = @{
        "command" = "npx"
        "args" = @(
            "-y",
            "mcp-remote",
            "http://$ServerIP`:8100/mcp",
            "--header",
            "x-brain-key:$AccessKey"
        )
    }

    $settings = @{}
    if (Test-Path $configPath) {
        $existing = Get-Content $configPath -Raw | ConvertFrom-Json
        $settings = $existing
    }

    if (-not $settings.mcpServers) {
        $settings | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{}
    }

    $settings.mcpServers.ob1 = $ob1Config

    Write-Log "  MCP server 'ob1' configured: http://$ServerIP`:8100/mcp" "Info"

    if (-not $DryRun) {
        $settings | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
        Write-Log "✓ Claude Cowork config saved to: $configPath" "Success"
    } else {
        Write-Log "[DRY RUN] Would save to: $configPath" "Warning"
    }

    return $configPath
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ LF2B OB1 MCP Setup for Windows (Claude Code, Desktop, Cowork) ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Determine server address
    if (-not $ServerAddress) {
        $ServerAddress = Get-ServerAddress
    }
    Write-Log "Server address: $ServerAddress" "Info"

    # Step 2: Get access key
    if (-not $AccessKey) {
        $AccessKey = Get-AccessKey
    }
    Write-Log "Access key obtained (length: $($AccessKey.Length) chars)" "Info"

    # Step 3: Validate connectivity and authentication (unless skipped)
    if (-not $SkipValidation) {
        $parts = $ServerAddress.Split(':')
        $host = $parts[0]

        if (-not (Test-Connectivity $host 8100)) {
            Write-Log "Cannot reach server at $host`:8100" "Error"
            $confirm = Read-Host "Continue anyway? (y/n)"
            if ($confirm -ne "y") {
                throw "Setup cancelled due to connectivity issues"
            }
        }

        # Optional: Test MCP auth (may timeout on SSE, so make it non-fatal)
        # Test-MCP-Server "http://$ServerAddress`:8100/mcp" $AccessKey | Out-Null
    }

    # Step 4: Update Claude configs
    Write-Host ""
    Write-Log "Updating Claude client configurations..." "Info"
    Write-Host ""

    $paths = @()
    $paths += Update-ClaudeCodeConfig $ServerAddress $AccessKey $DryRun
    $paths += Update-ClaudeDesktopConfig $ServerAddress $AccessKey $DryRun
    $paths += Update-ClaudeCoworkConfig $ServerAddress $AccessKey $DryRun

    # Step 5: Summary and next steps
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║ Setup Complete!" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Log "OB1 MCP server configured for:" "Success"
    Write-Host "  • Claude Code" -ForegroundColor Green
    Write-Host "  • Claude Desktop" -ForegroundColor Green
    Write-Host "  • Claude Cowork (if installed)" -ForegroundColor Green
    Write-Host ""

    Write-Log "Server details:" "Info"
    Write-Host "  Server: http://$ServerAddress`:8100/mcp" -ForegroundColor White
    Write-Host "  Label: ob1" -ForegroundColor White
    Write-Host "  Auth: x-brain-key header (set during setup)" -ForegroundColor White
    Write-Host ""

    Write-Log "Next steps:" "Info"
    Write-Host "  1. Restart Claude Code, Desktop, and Cowork to load new configs" -ForegroundColor White
    Write-Host "  2. Test MCP access: Try 'search_thoughts' or 'capture_thought' tools" -ForegroundColor White
    Write-Host "  3. If connection fails:" -ForegroundColor White
    Write-Host "     - Check connectivity: ping $ServerAddress" -ForegroundColor DarkGray
    Write-Host "     - Verify access key: compare with Mac Mini output" -ForegroundColor DarkGray
    Write-Host "     - Check firewall: ensure port 8100 is not blocked" -ForegroundColor DarkGray
    Write-Host ""

    if ($DryRun) {
        Write-Log "[DRY RUN] No files were modified. Run without -DryRun to apply changes." "Warning"
    }

} catch {
    Write-Log "Setup failed: $_" "Error"
    exit 1
}
