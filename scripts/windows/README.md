# LF2B OB1 MCP Setup for Windows

Automated setup script to configure Claude Code, Claude Desktop, and Claude Cowork on Windows to access the OB1 MCP server running on the Mac Mini.

## Quick Start

### Option 1: Double-Click Launcher (Easiest)

1. Download or clone this repository
2. Navigate to `scripts/windows/`
3. **Right-click** `setup-ob1-mcp-claude.bat` → **Run as Administrator**
4. Follow the prompts:
   - Choose connection method (Direct LAN or Tailscale)
   - Paste your MCP access key (from Mac Mini)
   - Script automatically configures all Claude clients

### Option 2: PowerShell (More Control)

```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
cd \path\to\scripts\windows
.\setup-ob1-mcp-claude.ps1
```

### Option 3: Dry Run (Preview Changes)

```powershell
.\setup-ob1-mcp-claude.ps1 -DryRun
```

Shows what would be configured without making any changes.

---

## Connection Methods

### 1. Direct LAN (10.0.3.5)

**Requires:** Your Windows machine on the same network as the Mac Mini (10.0.3.0/24 subnet).

```
Windows machine (same LAN)
        ↓
    [Router]
        ↓
Mac Mini (10.0.3.5:8100)
```

**Pros:**
- Simplest setup
- Lowest latency

**Cons:**
- Only works if you're on the same physical network
- Not suitable for remote work

---

### 2. Tailscale (Recommended for Most Users)

**Requires:** Tailscale installed on both machines.

```
Windows machine (100.x.x.x)
        ↓
    [Tailscale VPN]
        ↓
Mac Mini (100.y.y.y)
```

**Pros:**
- Works from anywhere (home, office, coffee shop, VPN)
- Encrypted tunnel
- No firewall configuration needed
- Simple to set up

**Cons:**
- Slight latency overhead (negligible for MCP use)
- Requires Tailscale account (free for personal use)

**Setup:**

On Mac Mini:
```bash
bash ~/scripts/lf2b-tailscale-setup.sh
```

On Windows:
```powershell
# Install Tailscale: https://tailscale.com/download
# Then:
sudo tailscale up --accept-routes
# (Windows Defender SmartScreen might warn — click "More info" → "Run anyway")
```

---

## Getting the MCP Access Key

The access key is stored in a secrets file on the Mac Mini. To retrieve it:

### Easiest: Helper Script

On **Mac Mini**, run:

```bash
bash ~/scripts/show-mcp-key.sh
```

This displays the key formatted for easy copying.

### Manual: Direct from Secrets

On **Mac Mini**, run:

```bash
grep '^MCP_ACCESS_KEY=' ~/.lf2b/secrets | cut -d= -f2
```

### During Windows Setup:

The setup script will prompt you to paste the key. Just right-click and paste (no visible characters for security).

---

## What Gets Configured

The script updates three Claude client configurations:

### Claude Code
- **Location:** `%APPDATA%\.claude\settings.json`
- **Updates:** Adds `ob1` MCP server entry
- **Restart needed:** Yes

### Claude Desktop
- **Location:** `%APPDATA%\Claude\claude_desktop_config.json`
- **Updates:** Adds `ob1` MCP server entry
- **Restart needed:** Yes

### Claude Cowork (if installed)
- **Location:** `%APPDATA%\Claude\claude_cowork_config.json` (or variant)
- **Updates:** Adds `ob1` MCP server entry
- **Restart needed:** Yes

---

## Testing the Setup

### 1. Verify Connectivity

```powershell
# Test if you can reach the server
ping 10.0.3.5          # Direct LAN
# or
ping <tailscale-ip>    # Tailscale
```

### 2. Restart Claude Clients

Close and restart all Claude applications (Code, Desktop, Cowork).

### 3. Test MCP Access

In any Claude client, try using an OB1 tool:

```
Try to use the 'search_thoughts' MCP tool:
  "Search for recent notes about OB1"

Or 'capture_thought':
  "Capture this test thought: Windows setup successful"
```

Expected behavior:
- ✅ Tool executes successfully (you see results)
- ❌ "MCP server error" or timeout → connection issue
- ❌ "Authorization failed" → wrong access key

---

## Troubleshooting

### "Connection refused"

**Cause:** Server not reachable at the address.

**Fix:**
- Verify correct server IP: `10.0.3.5` (LAN) or `100.x.x.x` (Tailscale)
- Check Windows Firewall allows outbound on port 8100:
  ```powershell
  # Allow outbound to 10.0.3.5:8100
  New-NetFirewallRule -DisplayName "OB1 MCP LAN" -Direction Outbound -Action Allow `
    -RemoteAddress 10.0.3.5 -RemotePort 8100 -Protocol TCP
  ```
- Ping the server: `ping 10.0.3.5`

### "401 Unauthorized"

**Cause:** Wrong or missing MCP access key.

**Fix:**
1. Verify the key on Mac Mini: `security find-generic-password -s lf2b_ob1_mcp_key -a ob1_mcp -w`
2. Run setup script again and paste the correct key
3. Restart Claude clients

### Tailscale not finding Mac Mini

**Cause:** Tailscale routes not advertised/accepted.

**Fix:**

On Mac Mini:
```bash
sudo tailscale up --advertise-routes=10.0.3.0/24 --accept-routes
```

On Windows:
```powershell
# Elevated PowerShell:
tailscale up --accept-routes
# Then enable subnet routes in Tailscale (settings → subnets)
```

Check status:
```powershell
tailscale status | findstr "jps-mac-mini"
```

### Script fails to update config files

**Cause:** Insufficient permissions or files locked.

**Fix:**
1. Close all Claude applications
2. Run script as Administrator (right-click → "Run as Administrator")
3. Ensure `%APPDATA%\Claude\` directory exists (create manually if needed)

### "PowerShell execution policy" error

**Cause:** Windows doesn't allow running scripts.

**Fix:**
```powershell
# In PowerShell (Admin):
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
# Then run the script again
```

---

## Manual Configuration (Advanced)

If the script doesn't work, you can configure manually:

### Claude Code

Edit: `%APPDATA%\.claude\settings.json`

```json
{
  "mcpServers": {
    "ob1": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://10.0.3.5:8100/mcp",
        "--header",
        "x-brain-key:<YOUR_KEY_HERE>"
      ]
    }
  }
}
```

### Claude Desktop

Edit: `%APPDATA%\Claude\claude_desktop_config.json`

Same structure as above.

---

## Security Notes

1. **Access Key:** Never commit the access key to git. It's stored in plaintext in config files (by necessity for MCP), so:
   - Keep your Windows machine secure
   - Don't share config files
   - Rotate the key if compromised

2. **Network Security:**
   - Direct LAN (10.0.3.5) is unencrypted; use only on trusted networks
   - Tailscale uses encryption; safe for untrusted networks
   - TLS will be added in future versions (v0.2+)

3. **Firewall:** OB1 server requires inbound port 8100 on the Mac Mini. The server is header-authenticated (no public endpoint).

---

## Advanced Usage

### Set Environment Variable (Skip Prompts)

```powershell
$env:LF2B_MCP_KEY = "your_key_here"
.\setup-ob1-mcp-claude.ps1 -ServerAddress "10.0.3.5"
```

### Skip Validation Checks

```powershell
.\setup-ob1-mcp-claude.ps1 -SkipValidation
# Useful if behind a restrictive firewall that blocks test connections
```

### Dry Run (Preview)

```powershell
.\setup-ob1-mcp-claude.ps1 -DryRun
# Shows what would change without modifying files
```

---

## Related Documentation

- **Mac Mini Setup:** See `docs/mcp-lan-access.md` (how to expose OB1 over LAN)
- **Tailscale Guide:** https://tailscale.com/kb/1017/install
- **MCP Protocol:** https://modelcontextprotocol.io/
- **Claude Integration:** https://github.com/modelcontextprotocol/

---

## Support

If setup fails:

1. Run with `-DryRun` to see what would be configured
2. Check `%APPDATA%\.claude\settings.json` manually — verify `ob1` entry is present
3. Verify connectivity: `Test-NetConnection 10.0.3.5 -Port 8100` (PowerShell)
4. Confirm access key with Mac Mini user
5. Check log output for specific error messages

---

**Last Updated:** 2026-05-08  
**Script Version:** 1.0  
**Author:** JP Cruz (via Claude Code automation)
