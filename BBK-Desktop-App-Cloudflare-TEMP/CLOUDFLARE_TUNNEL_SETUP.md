# How to Get a PERMANENT Cloudflare Tunnel URL

## Problem
Quick tunnels (trycloudflare.com) generate **random URLs every restart**:
- Restart 1: `https://abc-123.trycloudflare.com`
- Restart 2: `https://xyz-789.trycloudflare.com` ❌ Different!

This means you have to update Vercel every time you restart.

## Solution: Named Tunnel (FREE, PERMANENT URL!)

### Step 1: Create Cloudflare Account (Free)
1. Go to: https://dash.cloudflare.com
2. Sign up (free forever, no credit card needed)
3. Verify your email

### Step 2: Create a Tunnel
1. In Cloudflare dashboard, click **"Zero Trust"** in left sidebar
2. Go to **"Networks"** → **"Tunnels"**
3. Click **"Create a tunnel"**
4. Choose **"Cloudflared"**
5. Give it a name: `bbk-gym-bridge`
6. Click **"Save tunnel"**

### Step 3: Get Tunnel Token
After creating the tunnel, you'll see:
```
Install and run a connector:
cloudflared tunnel run --token eyJh...your_very_long_token...xyz
```

**Copy the token** (the long string after `--token`)

### Step 4: Add Token to Config
1. Open: `config.json` in the app folder
2. Find the `cloudflare` section:
   ```json
   "cloudflare": {
     "enabled": true,
     "tunnel_token": "",
     "comment": "..."
   }
   ```
3. Paste your token:
   ```json
   "cloudflare": {
     "enabled": true,
     "tunnel_token": "eyJh...your_very_long_token...xyz",
     "comment": "..."
   }
   ```
4. Save the file

### Step 5: Configure Public Hostname
Back in Cloudflare dashboard:
1. Click **"Public Hostname"** tab
2. Click **"Add a public hostname"**
3. Fill in:
   - **Subdomain**: `bbk-gym` (or any name you want)
   - **Domain**: Choose from your domains (or leave empty for *.cfargotunnel.com)
   - **Service Type**: `HTTP`
   - **URL**: `localhost:8000`
4. Click **"Save hostname"**

You'll get a permanent URL like:
- `https://bbk-gym.username.workers.dev` (if using workers.dev)
- `https://bbk-gym.yourdomain.com` (if using custom domain)

### Step 6: Restart the App
1. Close the BBK Desktop App
2. Start it again
3. You'll see a notification with your **PERMANENT URL**!
4. This URL **NEVER changes** ✅

### Step 7: Add to Vercel (ONE TIME ONLY!)
1. Go to: https://vercel.com/your-project/settings/environment-variables
2. Add:
   - Name: `NEXT_PUBLIC_BRIDGE_URL`
   - Value: `bbk-gym.username.workers.dev` (your permanent domain, without https://)
3. Redeploy
4. Done! No need to update again! 🎉

## Comparison

| Method | URL Stability | Account Needed | Setup Time |
|--------|--------------|----------------|------------|
| **Quick Tunnel** | ❌ Changes on restart | No | 0 min |
| **Named Tunnel** | ✅ PERMANENT | Yes (free) | 5 min |

## Troubleshooting

### "Invalid token" error
- Make sure you copied the entire token (it's very long)
- Remove any extra spaces or quotes
- Token should start with `eyJ`

### "Tunnel already running" error
- Stop any existing cloudflared processes
- Restart the desktop app

### Can't see "Zero Trust" in Cloudflare
- Make sure you're logged in
- It might be under "Access" → "Tunnels" on older accounts
- Or use direct link: https://one.dash.cloudflare.com/

## Benefits of Named Tunnel

✅ **Permanent URL** - Never changes  
✅ **Free Forever** - No cost  
✅ **Better Performance** - Cloudflare global network  
✅ **Custom Domain** - Can use your own domain  
✅ **SSL/TLS** - Automatic HTTPS  
✅ **DDoS Protection** - Built-in security  

## No Account? Temporary Solution

If you can't create an account right now, the app will use quick tunnels:
- ⚠️ URL changes every restart
- ⚠️ You must update Vercel environment variable each time
- ⚠️ Not recommended for production

## Need Help?

Check these resources:
- Cloudflare Tunnels Guide: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Create Tunnel: https://one.dash.cloudflare.com/
- Support: https://community.cloudflare.com/
