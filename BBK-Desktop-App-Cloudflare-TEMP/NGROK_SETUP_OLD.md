# ngrok Integration for Cloud Dashboard

## What is ngrok?
ngrok creates a secure tunnel from the public internet to your local Python bridge, allowing the hosted Vercel dashboard to connect to your local hardware.

## Setup Instructions

### 1. Get ngrok Authtoken (Free)
1. Go to https://ngrok.com/
2. Sign up for a free account
3. Go to https://dashboard.ngrok.com/get-started/your-authtoken
4. Copy your authtoken

### 2. Add Authtoken to Config
Edit `config.json` and add your authtoken:
```json
"ngrok": {
  "enabled": true,
  "authtoken": "YOUR_AUTHTOKEN_HERE",
  "region": "us"
}
```

### 3. Start the App
When you start the BBK Desktop App:
1. Python bridge starts on port 8000
2. ngrok tunnel automatically starts
3. You'll see a notification with the public URL (e.g., `https://abc123.ngrok.io`)
4. The URL is also logged in `logs/electron.log`

### 4. Configure Vercel
1. Go to https://vercel.com/your-project/settings/environment-variables
2. Add or update:
   - Variable: `NEXT_PUBLIC_BRIDGE_URL`
   - Value: `abc123.ngrok.io` (without https://)
3. Redeploy your Vercel app

### 5. Test Connection
1. Open https://bbkdashboard.vercel.app in browser
2. Open https://bbkdashboard.vercel.app/member-screen in another tab/window
3. Click "Member Self-Registration" on dashboard
4. Registration form should mirror to member screen

## How It Works

```
Cloud Dashboard (Vercel)
         ↓
    ngrok Tunnel
         ↓
  Local Bridge (Port 8000)
         ↓
   Hardware Devices
```

## Without ngrok
If you don't want to use ngrok:
1. Set `"enabled": false` in config.json under ngrok
2. Use only local URLs:
   - Employee: `http://localhost:3000`
   - Member screen: `http://localhost:3000/member-screen`

## ngrok Free Tier Limitations
- 1 online ngrok process at a time
- URL changes every time you restart (e.g., abc123.ngrok.io → xyz789.ngrok.io)
- 40 connections/minute limit

## ngrok Paid Plans
For production use, consider ngrok paid plans:
- Static domain (URL never changes)
- Higher connection limits
- Custom domains
- More regions

## Troubleshooting

### "Failed to start ngrok tunnel"
- Check if ngrok authtoken is correct
- Ensure port 8000 is not blocked by firewall
- Check logs/electron.log for details

### ngrok URL changes on restart
- This is normal for free tier
- You need to update Vercel env variable each time
- Upgrade to paid plan for static domain

### Connection refused
- Ensure Python bridge started successfully
- Check if port 8000 is accessible
- Verify firewall settings

### Vercel still can't connect
- Verify NEXT_PUBLIC_BRIDGE_URL is set correctly (without https://)
- Redeploy Vercel app after changing env variable
- Check browser console for WebSocket errors
