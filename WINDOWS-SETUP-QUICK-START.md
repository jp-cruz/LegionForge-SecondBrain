# Windows Setup — Quick Start Guide

Get Claude Code, Claude Desktop, and Claude Cowork on Windows connected to the OB1 MCP server in 3 steps.

## Step 1: Get Access Key from Mac Mini

On **Mac Mini**, open Terminal and run:

```bash
bash ~/scripts/show-mcp-key.sh
```

This will display your MCP access key. Copy it (the long hex string). You'll paste this during Windows setup.

**Alternative (if show-mcp-key.sh doesn't exist):**
```bash
grep '^MCP_ACCESS_KEY=' ~/.lf2b/secrets | cut -d= -f2
```

---

## Step 2: Run Setup Script on Windows

### Easiest: Double-Click Launcher

1. Download/clone the repo to your Windows machine
2. Navigate to: `scripts/windows/`
3. **Right-click** → **`setup-ob1-mcp-claude.bat`** → **"Run as Administrator"**
4. Choose connection method:
   - **Option 1:** Direct LAN (if on same network as Mac Mini)
   - **Option 2:** Tailscale (recommended — works from anywhere)
5. Paste the access key when prompted
6. Script configures all three Claude clients automatically ✓

### Alternative: PowerShell (More Verbose)

```powershell
# Right-click PowerShell → "Run as Administrator"
cd \path\to\scripts\windows
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
.\setup-ob1-mcp-claude.ps1
```

---

## Step 3: Restart Claude & Test

1. **Close** Claude Code, Claude Desktop, Claude Cowork (all instances)
2. **Restart** each application
3. **Test MCP access** — try any OB1 tool:
   - "Search for recent notes"
   - "Capture a test thought"
4. ✅ Works? You're done!

---

## Connection Methods

### Direct LAN (Simplest)

- **Works if:** You're on the same network as the Mac Mini (10.0.3.0/24)
- **Address:** `http://10.0.3.5:8100/mcp`
- **Setup time:** < 1 minute

### Tailscale (Recommended)

- **Works from:** Anywhere (home, office, coffee shop, traveling)
- **Setup time:** 5 minutes (first-time Tailscale setup)

**Pre-requisite:** Tailscale must be set up on both machines.

On **Mac Mini** (run once):
```bash
bash ~/scripts/lf2b-tailscale-setup.sh
```

On **Windows** (run once):
```powershell
# Run as Administrator:
.\setup-tailscale-routes.ps1
# Then: tailscale up --accept-routes
```

Then use the setup script and select "Tailscale" as the connection method.

---

## What Gets Configured

| App | Config File | Status |
|-----|------------|--------|
| Claude Code | `%APPDATA%\.claude\settings.json` | Adds `ob1` MCP server |
| Claude Desktop | `%APPDATA%\Claude\claude_desktop_config.json` | Adds `ob1` MCP server |
| Claude Cowork | `%APPDATA%\Claude\claude_cowork_config.json` | Adds `ob1` MCP server |

Each gets the same configuration:
```json
{
  "ob1": {
    "command": "npx",
    "args": ["-y", "mcp-remote", "http://<server>:8100/mcp", "--header", "x-brain-key:<key>"]
  }
}
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| **"Connection refused"** | Check firewall; ping `10.0.3.5` or Tailscale IP |
| **"401 Unauthorized"** | Verify access key (run on Mac Mini and compare) |
| **"Can't find MCP server"** | Ensure `ob1` entry exists in config files (check paths above) |
| **Restart prompt:** | Close Claude completely, reopen — configs loaded on startup |
| **Tailscale not working** | Run `setup-tailscale-routes.ps1` first, then main setup script |

See `scripts/windows/README.md` for detailed troubleshooting.

---

## File Locations

| File | Purpose |
|------|---------|
| `scripts/windows/setup-ob1-mcp-claude.bat` | **Click this** — launcher |
| `scripts/windows/setup-ob1-mcp-claude.ps1` | Main setup (called by .bat) |
| `scripts/windows/setup-tailscale-routes.ps1` | Optional: enable Tailscale routes |
| `scripts/windows/README.md` | Full documentation & troubleshooting |
| `docs/mcp-lan-access.md` | Network architecture (reference) |

---

## MCP Server Details

| Component | Value |
|-----------|-------|
| **Label** | `ob1` |
| **Protocol** | HTTP (TLS coming in v0.2) |
| **Port** | 8100 |
| **Authentication** | Header: `x-brain-key: <key>` |
| **Available tools** | `search_thoughts`, `list_thoughts`, `thought_stats`, `capture_thought` |

---

## Next Steps

After setup is complete:

1. **Test the connection** — use any OB1 tool in Claude
2. **Explore features:**
   - `search_thoughts` — query your Obsidian vault via semantic search
   - `capture_thought` — save thoughts to the memory system
3. **Customize queries** — fine-tune semantic search using natural language

---

## Security Notes

- **Access key** is stored in plaintext in config files (MCP requirement)
- Use **Tailscale** if your Windows machine leaves the home network
- Direct LAN (`10.0.3.5`) is unencrypted — use only on trusted networks
- **TLS/OAuth2** planned for v0.2+ (higher security)

---

## Support

If setup fails:
1. Run setup script with `-DryRun` flag to preview changes
2. Manually verify config files (paths listed above)
3. Test connectivity: `Test-NetConnection 10.0.3.5 -Port 8100` (PowerShell)
4. Confirm access key with Mac Mini user
5. Check `scripts/windows/README.md` for detailed troubleshooting

---

**Last Updated:** 2026-05-08  
**MCP Server Label:** `ob1`  
**Script Version:** 1.0
