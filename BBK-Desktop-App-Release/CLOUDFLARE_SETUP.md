# Cloudflare Tunnel Setup Guide

## Overview
This application uses **Cloudflare Tunnel** to expose your local Python bridge to the cloud dashboard hosted on Vercel. Unlike ngrok, Cloudflare Tunnel is **100% FREE** and provides **STATIC URLs** that **never change**.

## Why Cloudflare Tunnel?

✅ **FREE Forever** - No subscription needed  
✅ **Static URLs** - Your URL never changes (unlike ngrok free tier)  
✅ **No Account Required** - Works without Cloudflare account  
✅ **Better Performance** - Cloudflare's global CDN  
✅ **Production Ready** - Reliable and stable

## How It Works

1. **Desktop app starts** → BBK-Bridge.exe runs on port 8000
2. **Cloudflare Tunnel starts** → Creates public HTTPS URL (e.g., `https://abc-123-xyz.trycloudflare.com`)
3. **URL is STATIC** → Same URL every time you restart the app
4. **Dashboard connects** → Vercel dashboard uses this URL to connect to your local hardware

## Setup Instructions

### 1. Start the Desktop App

Launch `BBK-Desktop-App.exe` normally. The app will automatically:
- Start the Python bridge (BBK-Bridge.exe)
- Create a Cloudflare tunnel
- Show a notification with your tunnel URL

### 2. Get Your Tunnel URL

You'll see a notification like this:

```
🌐 Static URL: https://abc-123-xyz.trycloudflare.com

✅ Add to Vercel once:
NEXT_PUBLIC_BRIDGE_URL=abc-123-xyz.trycloudflare.com

📌 This URL never changes!
```

**The URL is also saved to:** `TUNNEL_URL.txt` in the app directory.

### 3. Configure Vercel (ONE-TIME SETUP)

Go to your Vercel project settings:

1. Navigate to: `https://vercel.com/your-project/settings/environment-variables`
2. Add a new environment variable:
   - **Name:** `NEXT_PUBLIC_BRIDGE_URL`
   - **Value:** `abc-123-xyz.trycloudflare.com` (your tunnel URL **without** `https://`)
3. Click **Save**
4. **Redeploy** your dashboard

### 4. Test the Connection

1. Open your hosted dashboard: `https://bbkdashboard.vercel.app`
2. Go to the **Members** page
3. Click **"Member Self-Registration"**
4. Open member screen: `https://bbkdashboard.vercel.app/member-screen`
5. You should see the registration form mirrored in real-time!

## Configuration

### Enable/Disable Tunnel

Edit `config.json`:

```json
{
  "cloudflare": {
    "enabled": true,
    "comment": "Cloudflare Tunnel provides FREE STATIC URLs - no account needed!"
  }
}
```

Set `"enabled": false` to disable the tunnel.

### When Is Tunnel Needed?

The tunnel is **automatically started** when:
- Your dashboard URL contains `vercel.app` (cloud deployment)
- OR `cloudflare.enabled` is set to `true` in config.json

The tunnel is **NOT needed** when:
- Using localhost URLs (e.g., `http://localhost:3000`)
- All devices are on the same local network

## Troubleshooting

### Tunnel Not Starting

Check the logs:
- Location: `logs/electron.log`
- Look for: `"Starting Cloudflare tunnel..."` and `"✅ Cloudflare tunnel established"`

### No Notification Shown

The tunnel URL is saved to `TUNNEL_URL.txt` even if the notification doesn't appear.

### Connection Failed on Dashboard

1. Verify the tunnel is running: Check `TUNNEL_URL.txt`
2. Verify Vercel environment variable:
   - Name: `NEXT_PUBLIC_BRIDGE_URL`
   - Value: Your tunnel URL **without** `https://`
3. Redeploy Vercel dashboard after adding the variable
4. Clear browser cache and reload

### URL Changed After Restart

Cloudflare Tunnel URLs **should be static**. If your URL changes:
- This may happen rarely during cloudflared updates
- Simply update the Vercel environment variable with the new URL
- URLs are much more stable than ngrok free tier

## Technical Details

### Port Forwarding

The tunnel forwards:
- **Local:** `http://localhost:8000` (Python bridge)
- **Public:** `https://your-tunnel.trycloudflare.com`

### WebSocket Support

Cloudflare Tunnel supports WebSocket connections:
- `/ws/mirror` - Screen mirroring
- `/ws/attendance` - Attendance events
- `/ws/events` - Hardware events

### Security

- All connections are HTTPS/WSS (encrypted)
- Only your configured bridge is accessible
- No other local services are exposed

## Comparison: Cloudflare vs ngrok

| Feature | Cloudflare Tunnel | ngrok (free) |
|---------|------------------|--------------|
| **Price** | Free forever | Free (limited) |
| **URL Stability** | Static | Changes on restart |
| **Account Required** | No | Yes |
| **Performance** | Cloudflare CDN | Good |
| **Setup** | Automatic | Requires authtoken |
| **Production Ready** | ✅ Yes | ⚠️ Not recommended |

## Advanced Usage

### Custom Domains

For production, you can configure a custom domain:
1. Create a Cloudflare account
2. Add your domain to Cloudflare
3. Create a named tunnel with a custom subdomain
4. Update the app to use named tunnels

See Cloudflare documentation: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

### Multiple Tunnels

Each instance of the app gets its own unique tunnel URL.

## Support

If you encounter issues:
1. Check `logs/electron.log` for errors
2. Verify `TUNNEL_URL.txt` exists and contains a URL
3. Test the tunnel directly: `curl https://your-tunnel.trycloudflare.com/health`
4. Ensure Python bridge is running on port 8000

## Resources

- Cloudflare Tunnel Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- NPM Package: https://www.npmjs.com/package/cloudflared
- BBK Dashboard: https://bbkdashboard.vercel.app
