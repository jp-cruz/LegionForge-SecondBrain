# OB1 MCP Server — LAN Access Guide

The Open Brain (OB1) MCP server is accessible over the local network at `http://10.0.3.5:8100/mcp`. This guide covers how to access it from other machines.

## Current Configuration

| Component | Value |
|-----------|-------|
| **Server hostname** | `jps-mac-mini.local` (via mDNS) or `10.0.3.5` |
| **Port** | 8100 |
| **Protocol** | HTTP (TLS planned for v0.2) |
| **Authentication** | Header-based: `x-brain-key: <key>` |
| **MCP Access Key** | Stored in macOS Keychain (`lf2b_ob1_mcp_key / ob1_mcp`) |
| **Server binding** | `0.0.0.0:8100` (all interfaces) |

---

## Access from Other Machines on LAN

### Option 1: Direct LAN IP (fastest, no extra setup)

Use the LAN IP directly in any MCP client configuration:

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
        "x-brain-key:<your-key>"
      ]
    }
  }
}
```

Requirements:
- Machine must be on the same LAN subnet as the Mac Mini (10.0.3.0/24)
- Direct line-of-sight networking (no complex routing)

---

### Option 2: Hostname via mDNS (easier to remember)

Use the hostname `jps-mac-mini.local` instead:

```json
{
  "mcpServers": {
    "ob1": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://jps-mac-mini.local:8100/mcp",
        "--header",
        "x-brain-key:<your-key>"
      ]
    }
  }
}
```

Requirements:
- mDNS must work on your LAN (typically automatic on home/office networks)
- Windows: requires Bonjour (iTunes installs it, or use mDNS resolver separately)
- macOS/Linux: automatic

---

### Option 3: Tailscale (VPN tunnel, recommended for remote access)

For access from outside the LAN or across multiple networks:

**On the Mac Mini (server side):**

```bash
# Enable Tailscale subnet routing (advertise 10.0.3.0/24)
sudo tailscale up --advertise-routes=10.0.3.0/24 --accept-routes

# Or just use the Tailscale IP directly
tailscale ip -4  # prints Tailscale IPv4 (e.g., 100.x.x.x)
```

**On client machine:**

```bash
# Accept Tailscale routes advertised by the Mac Mini
sudo tailscale up --accept-routes
```

Then configure MCP with the Tailscale IP:

```json
{
  "mcpServers": {
    "ob1": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://100.xxx.xxx.xxx:8100/mcp",
        "--header",
        "x-brain-key:<your-key>"
      ]
    }
  }
}
```

Or use the Tailscale hostname:

```bash
tailscale status | grep jps-mac-mini
# Find the hostname (e.g., jps-mac-mini.tail1234.ts.net)
```

---

## Testing Connectivity

### From the Mac Mini itself:

```bash
# Direct test (should get 401 without valid key)
curl -v http://10.0.3.5:8100/mcp 2>&1 | head -20

# With valid key (SSE stream test — Ctrl+C to exit)
curl -v \
  -H "x-brain-key:$(security find-generic-password -s lf2b_ob1_mcp_key -a ob1_mcp -w)" \
  -H "Accept: text/event-stream" \
  http://10.0.3.5:8100/mcp
```

### From another machine:

```bash
# Test connectivity to the server
curl -v http://10.0.3.5:8100/mcp 2>&1 | head -20
# (Should fail with 401 Unauthorized without the key — this is success, it means the server is reachable)

# To verify the key works, you'll need the MCP access key from Keychain on the Mac Mini
```

---

## Key Security Notes

1. **Authentication:** Only header-based (`x-brain-key`). The key is NOT in the URL to avoid leaking it in logs/browser history.
2. **TLS:** Not currently enabled. Do NOT expose the MCP server to untrusted networks. Use Tailscale (encrypted tunnel) for remote access.
3. **Firewall:** The Mac Mini's firewall must allow inbound on port 8100. Current rule:
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/deno
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /opt/homebrew/bin/deno
   ```

---

## Troubleshooting

| Issue | Diagnosis | Fix |
|-------|-----------|-----|
| `Connection refused` | Server not running | `pgrep -fl "deno.*index.ts"` should return a PID; if not, restart with `launchctl start lf2b.ob1-mcp` |
| `Connection timeout` | Firewall or network routing issue | Check Mac firewall + network connectivity with `ping 10.0.3.5` |
| `401 Unauthorized` | Wrong or missing key | Verify key matches `security find-generic-password -s lf2b_ob1_mcp_key -a ob1_mcp -w` |
| `mDNS not resolving` | `jps-mac-mini.local` not found | Fall back to IP address (10.0.3.5); check if mDNS is enabled on your router |
| `Tailscale tunnel not working` | Routes not advertised | Run `sudo tailscale up --advertise-routes=10.0.3.0/24` on Mac Mini and `sudo tailscale up --accept-routes` on client |

---

## Roadmap

- **v0.2:** Add TLS with self-signed cert (for local dev; clients skip verification)
- **v0.3:** mkcert integration for system-trusted local CA certificates
- **v1.0:** OAuth2 + bearer tokens (stronger auth than header keys)

---

## Related Files

- Startup script: `~/scripts/lf2b-ob1-mcp-start.sh`
- Server code: `~/.lf2b/ob1-server/index.ts`
- Deno config: `~/.lf2b/ob1-server/deno.json`
- Launch daemon: `~/Library/LaunchAgents/lf2b.ob1-mcp.plist`
- Architecture: `docs/architecture.md`
